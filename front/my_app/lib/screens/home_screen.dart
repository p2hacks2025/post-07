import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'dart:async';
import 'dart:convert';

import 'screen_profile.dart';
import 'screen_map.dart';
import 'screen_birthday.dart';
import 'screen_achieve.dart';
import 'screen_park.dart';
import 'screen_encounter.dart';
import 'screen_history.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../models/encounter.dart';


void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // カスタムサービスUUID
  static const String customServiceUuid = '0000FFF0-0000-1000-8000-00805f9b34fb';
  
  int _selectedIndex = 0; // 現在真ん中にあるアイコンの番号
  late PageController _pageController;
  Timer? _scanTimer;
  bool _isScanning = false;
  final ProfileService _profileService = ProfileService();
  String? _myProfileId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.1);
    
    // プロフィールIDを取得してからBLE開始
    _initializeProfile();
  }

  // プロフィールIDを取得または生成してBLE開始
  Future<void> _initializeProfile() async {
    Profile? myProfile = await _profileService.loadMyProfile();
    
    if (myProfile == null) {
      // プロフィールが存在しない場合、新しいIDを生成して保存
      _myProfileId = _profileService.generateProfileId();
      myProfile = Profile(
        profileId: _myProfileId!,
        nickname: 'ゲスト',
        birthday: '',
        hometown: '',
        trivia: '',
      );
      await _profileService.saveMyProfile(myProfile);
    } else {
      _myProfileId = myProfile.profileId;
    }
    
    // BLE広告を開始
    _startBleAdvertising();
    
    // 繰り返しスキャンを開始
    _startRepeatingScan();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    FlutterBluePlus.stopScan();
    _stopBleAdvertising();
    _pageController.dispose();
    super.dispose();
  }

  // 繰り返しスキャンを開始
  void _startRepeatingScan() {
    _startBleScan();
  }

  // BLEスキャンを開始
  Future<void> _startBleScan() async {
    if (_isScanning) return;
    
    _isScanning = true;
    print('BLEスキャン開始...');
    
    try {
      // Bluetoothがオンになっているか確認
      if (await FlutterBluePlus.isSupported == false) {
        print('このデバイスはBluetoothをサポートしていません');
        _isScanning = false;
        return;
      }

      // カスタムサービスUUIDでフィルタリングしてスキャン開始
      await FlutterBluePlus.startScan(
        withServices: [Guid(customServiceUuid)],
        timeout: const Duration(seconds: 5),
      );
      print('スキャン中: $customServiceUuid');

      // スキャン結果をリッスン
      FlutterBluePlus.scanResults.listen((results) async {
        print('スキャン結果: ${results.length}件のデバイスを検出');
        
        if (results.isNotEmpty && mounted) {
          // デバイスを検知したらスキャンを停止
          await FlutterBluePlus.stopScan();
          _isScanning = false;
          
          // 相手のプロフィールIDを取得
          String? encounteredProfileId;
          for (var result in results) {
            print('デバイス検出: ${result.device.platformName}');
            
            // Service Dataから相手のプロフィールIDを取得
            final serviceData = result.advertisementData.serviceData;
            print('Service Data: $serviceData');
            
            if (serviceData.containsKey(Guid(customServiceUuid))) {
              final bytes = serviceData[Guid(customServiceUuid)]!;
              encounteredProfileId = utf8.decode(bytes);
              print('✅ 相手のプロフィールIDを検知: $encounteredProfileId');
              break;
            } else {
              print('⚠️ Service Dataに目的のUUIDが含まれていません');
            }
          }
          
          // プロフィールIDが取得できた場合、相手の情報を取得して保存
          if (encounteredProfileId != null) {
            await _handleEncounter(encounteredProfileId);
            
            // すれ違い成功画面へ遷移
            if (mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScreenEncounter()),
              );
            }
          } else {
            print('⚠️ プロフィールIDを取得できませんでした');
          }
          
          // 画面から戻ってきたら、5秒後に再度スキャン開始
          if (mounted) {
            await Future.delayed(const Duration(seconds: 5));
            _startRepeatingScan();
          }
        }
      });

      // タイムアウト後も5秒待機して再スキャン
      await Future.delayed(const Duration(seconds: 5));
      if (_isScanning && mounted) {
        await FlutterBluePlus.stopScan();
        _isScanning = false;
      }
      
      if (mounted) {
        await Future.delayed(const Duration(seconds: 5));
        _startRepeatingScan();
      }
    } catch (e) {
      print('BLEスキャンエラー: $e');
      _isScanning = false;
      
      // エラーが発生しても5秒後に再試行
      if (mounted) {
        await Future.delayed(const Duration(seconds: 5));
        _startRepeatingScan();
      }
    }
  }

  // BLE広告を開始（プロフィールIDをService Dataに含める）
  Future<void> _startBleAdvertising() async {
    if (_myProfileId == null) {
      print('⚠️ プロフィールIDがnullのため広告を開始できません');
      return;
    }
    
    try {
      final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
      
      // プロフィールIDをバイト列にエンコード
      final List<int> profileIdBytes = utf8.encode(_myProfileId!);
      print('プロフィールIDをエンコード: $_myProfileId -> $profileIdBytes');
      
      final AdvertiseData advertiseData = AdvertiseData(
        serviceUuid: customServiceUuid,
        serviceData: profileIdBytes,
        includePowerLevel: true,
      );

      await blePeripheral.start(advertiseData: advertiseData);
      print('✅ BLE広告開始成功: $customServiceUuid (プロフィールID: $_myProfileId)');
    } catch (e) {
      print('❌ BLE広告エラー: $e');
    }
  }

  // BLE広告を停止
  Future<void> _stopBleAdvertising() async {
    try {
      final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
      await blePeripheral.stop();
    } catch (e) {
      print('BLE広告停止エラー: $e');
    }
  }

  // すれ違い時の処理（プロフィール取得と保存）
  Future<void> _handleEncounter(String encounteredProfileId) async {
    try {
      print('すれ違い処理開始: ProfileID=$encounteredProfileId');
      
      // サーバーから相手のプロフィール情報を取得（ダミーAPI）
      Profile? encounteredProfile = await _fetchProfileFromServer(encounteredProfileId);
      
      // プロフィール情報が取得できなくても、すれ違いは記録する
      if (encounteredProfile == null) {
        // デフォルトプロフィールを作成
        encounteredProfile = Profile(
          profileId: encounteredProfileId,
          nickname: 'ゲスト ($encounteredProfileId)',
          birthday: '未登録',
          hometown: '未登録',
          trivia: 'プロフィール未登録のユーザーです',
        );
        print('デフォルトプロフィールを使用します');
      }
      
      // すれ違い履歴に保存
      final encounter = Encounter(
        profile: encounteredProfile,
        encounterTime: DateTime.now(),
      );
      await _profileService.saveEncounter(encounter);
      print('すれ違い履歴を保存しました: ${encounteredProfile.nickname}');
    } catch (e) {
      print('すれ違い処理エラー: $e');
      // エラーが発生してもデフォルト情報で保存を試みる
      try {
        final defaultProfile = Profile(
          profileId: encounteredProfileId,
          nickname: 'Unknown User',
          birthday: '未登録',
          hometown: '未登録',
          trivia: 'プロフィール取得に失敗しました',
        );
        final encounter = Encounter(
          profile: defaultProfile,
          encounterTime: DateTime.now(),
        );
        await _profileService.saveEncounter(encounter);
        print('デフォルトプロフィールで保存しました');
      } catch (saveError) {
        print('保存失敗: $saveError');
      }
    }
  }

  // サーバーから相手のプロフィール情報を取得（ダミーAPI）
  Future<Profile?> _fetchProfileFromServer(String profileId) async {
    try {
      // TODO: 実際のAPIエンドポイントに置き換える
      // final response = await http.get(
      //   Uri.parse('https://your-api.com/profiles/$profileId'),
      // );
      // 
      // if (response.statusCode == 200) {
      //   return Profile.fromJson(jsonDecode(response.body));
      // }
      
      // ダミーデータを返す
      await Future.delayed(const Duration(milliseconds: 500));
      return Profile(
        profileId: profileId,
        nickname: 'すれ違った人',
        birthday: '2000-01-01',
        hometown: '東京都',
        trivia: 'こんにちは！',
      );
    } catch (e) {
      print('プロフィール取得エラー: $e');
      return null;
    }
  }

  // メニューのデータ
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'color': Colors.green.shade600},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded, 'color': Colors.blue.shade400},
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'color': Colors.orange.shade400}, // index: 2
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'color': Colors.pink.shade400},
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'color': Colors.teal.shade400},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber.shade600},
    {'title': '履歴', 'icon': Icons.history_rounded, 'color': Colors.purple.shade400},
  ];

  // アイコンをタップしたときの処理
  void _onIconTapped(int index) {
    // 真ん中のアイコン（選択中）をタップしたときだけ遷移などのアクション
    if (index == _selectedIndex) {
      
      if (index == 1) {
        // マイプロフィール画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScreenProfile(profileId: _myProfileId)),
        );
      } else if (index == 2) {
        // 地図画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenMap()),
        );
      } else if (index == 3) {
        // 誕生日画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenBirthday()),
        );
      }
      
      else if (index == 0) {
        // ホームボタンを押したとき（特に何もしないか、更新など）
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('ここがホームです')),
        );
      } else if (index == 4) {
        // 広場画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenEleven()),
        );
      } else if (index == 5) {
        // トロフィー画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenTen()),
        );      } else if (index == 6) {
        // 履歴画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenHistory()),
        );      } else {
        // その他のボタン（準備中）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_screens[index]['title']} は準備中です')),
        );
      }
      
    } else {
      // 端のアイコンをタップしたら、真ん中に持ってくる
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ベースの色
      body: Stack(
        children: [
          // ===================================================
          // 1. メイン画面（ここを固定にする！）
          // ===================================================
          Positioned.fill(
            child: Container(
              color: Colors.green.shade600, // ホーム画面の背景色（固定）
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 常に「ホーム」の内容を表示
                  Text(
                    'ホーム',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                  SizedBox(height: 20),
                  Icon(
                    Icons.home_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'いつもの場所',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 100), // アイコンとかぶらないための余白
                ],
              ),
            ),
          ),

          // ===================================================
          // 2. 下のメニューアイコン（ここはスライドで動く）
          // ===================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index; // 真ん中の番号だけ更新（画面は変えない）
                  });
                },
                itemBuilder: (context, index) {
                  final bool isSelected = index == _selectedIndex;

                  // アイコン部分のデザイン
                  return GestureDetector(
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      // 真ん中に来たら上に上がり、大きくなる
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50,    // 選択中は上に上がる
                        bottom: isSelected ? 20 : 5,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 選択中は少し光らせる演出（お好みで）
                        boxShadow: isSelected ? [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                        ] : [],
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'],
                          // 選択中はサイズ50、それ以外は30
                          size: isSelected ? 50 : 30,
                          // 選択中は白くハッキリ、それ以外は半透明
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}