import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:uuid/uuid.dart';

import 'screen_profile.dart';
import 'screen_map.dart';
import 'screen_birthday.dart';
import 'screen_ten.dart';
import 'screen_eleven.dart';
import 'screen_encounter.dart';


void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 現在真ん中にあるアイコンの番号
  late PageController _pageController;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _hasDetected = false; // 重複検知を防ぐフラグ
  
  // BLE広告用のフィールド
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  late String _myDeviceId; // 自分のデバイスID

  @override
  void initState() {
    super.initState();
    
    // 自分の一意IDを生成（UUIDを使用）
    _myDeviceId = const Uuid().v4();
    
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.1);
    
    // BLEスキャンを開始
    _startBleScan();
    
    // BLE広告を開始（ペリフェラル機能）
    _startBleAdvertising();
  }

  // BLEスキャンを開始
  void _startBleScan() async {
    try {
      // Bluetoothアダプターの状態を確認
      final adapterState = await FlutterBluePlus.adapterState.first;
      
      if (adapterState == BluetoothAdapterState.on) {
        // スキャンを開始
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));
        
        // スキャン結果をリッスン
        _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
          if (_hasDetected || !mounted) return; // すでに検知済みまたは破棄済みの場合は処理しない
          
          if (results.isNotEmpty) {
            // 最初に検知したデバイスを取得
            final device = results.first.device;
            final deviceId = device.remoteId.toString();
            
            _hasDetected = true; // 重複検知を防ぐ
            FlutterBluePlus.stopScan(); // スキャン停止
            
            // すれ違い画面に遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScreenEncounter(detectedUserId: deviceId),
              ),
            );
          }
        });
      } else {
        // Bluetoothが無効の場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetoothを有効にしてください')),
          );
        }
      }
    } catch (e) {
      // エラーハンドリング
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BLEスキャンエラー: $e')),
        );
      }
    }
  }

  // BLE広告（アドバタイズ）を開始
  void _startBleAdvertising() async {
    try {
      // カスタムサービスUUID（すれ違いアプリ用）
      const serviceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';
      
      // 自分のデバイスIDをバイト配列に変換
      final deviceIdBytes = utf8.encode(_myDeviceId);
      
      // BLE広告を開始
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: serviceUuid,
          manufacturerData: deviceIdBytes,
          includeDeviceName: false,
        ),
      );
      
      debugPrint('BLE広告開始: デバイスID = $_myDeviceId');
    } catch (e) {
      debugPrint('BLE広告エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BLE広告エラー: $e')),
        );
      }
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
  ];

  @override
  void dispose() {
    _scanSubscription?.cancel(); // スキャン購読をキャンセル
    FlutterBluePlus.stopScan(); // スキャンを停止
    
    // BLE広告を停止
    _blePeripheral.stop();
    
    _pageController.dispose();
    super.dispose();
  }

  // アイコンをタップしたときの処理
  void _onIconTapped(int index) {
    // 真ん中のアイコン（選択中）をタップしたときだけ遷移などのアクション
    if (index == _selectedIndex) {
      
      if (index == 1) {
        // マイプロフィール画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenProfile()),
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
          MaterialPageRoute(builder: (context) => const ScreenThree()),
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
        );
      } else {
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