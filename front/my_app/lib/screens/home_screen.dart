import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
import '../models/trivia_card.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _scanSubscription;  // BLEスキャン用
  FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  // カスタムサービスUUID
  static const String customServiceUuid =
      '0000FFF0-0000-1000-8000-00805f9b34fb';

  int _selectedIndex = 0; // 現在真ん中にあるアイコンの番号
  late PageController _pageController;
  Timer? _scanTimer;
  bool _isScanning = false;
  final ProfileService _profileService = ProfileService();
  String? _myProfileId;
  List<TriviaCard> _displayedCards = []; // 展示するカードのリスト

  // ■■■ 修正：プロフィール帳のデータを新しい入力項目に合わせました ■■■
  // 項目：ニックネーム, 誕生日, 出身地, トリビア
  final List<Map<String, dynamic>> _profiles = [
    {
      'nickname': 'タロウ',
      'birthday': '1月15日',
      'birthplace': '北海道',
      'trivia': '実は犬より猫派です。最近子猫を拾いました。',
      'color': Colors.blue.shade100,
      'icon': Icons.face,
    },
    {
      'nickname': 'はなちゃん',
      'birthday': '5月22日',
      'birthplace': '東京都',
      'trivia': 'カフェラテには砂糖を3本入れないと飲めません！',
      'color': Colors.pink.shade100,
      'icon': Icons.face_3,
    },
    {
      'nickname': 'イチロー',
      'birthday': '10月22日',
      'birthplace': '愛知県',
      'trivia': '毎週末キャンプに行っているので、焚き火の匂いが取れません。',
      'color': Colors.green.shade100,
      'icon': Icons.face_6,
    },
    {
      'nickname': 'ゆう',
      'birthday': '3月3日',
      'birthplace': '福岡県',
      'trivia': '音ゲーの全国大会に出たことがあります（一回戦負けですが...）',
      'color': Colors.orange.shade100,
      'icon': Icons.face_5,
    },
    {
      'nickname': 'ケンタ',
      'birthday': '8月10日',
      'birthplace': '大阪府',
      'trivia': '関西人ですが、実はお好み焼きをおかずにご飯を食べられません。',
      'color': Colors.purple.shade100,
      'icon': Icons.face_4,
    },
    {
      'nickname': 'みさき',
      'birthday': '7月20日',
      'birthplace': '沖縄県',
      'trivia': '泳げないダイバーです。海に潜るときは必死です。',
      'color': Colors.cyan.shade100,
      'icon': Icons.face_2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.1,
    );

    // プロフィールIDを取得してからBLE開始
    _initializeProfile();
    
    // 展示カードを読み込み
    _loadDisplayedCards();
  }

  // 展示カードを読み込む
  Future<void> _loadDisplayedCards() async {
    final cards = await _profileService.loadDisplayedCards();
    if (mounted) {
      setState(() {
        _displayedCards = cards;
      });
      print('展示カードを読み込みました: ${cards.length}枚');
    }
  }

  // プロフィールIDを取得または生成してBLE開始
  Future<void> _initializeProfile() async {
    print('\n🚀 アプリ初期化開始...');
    Profile? myProfile = await _profileService.loadMyProfile();

    if (myProfile == null) {
      print('新しいプロフィールを生成します');
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
      print('プロフィールを保存しました: $_myProfileId');
    } else {
      print('既存のプロフィールを読み込みました');
      _myProfileId = myProfile.profileId;
      print('プロフィールID: $_myProfileId');
    }

    // BLE広告を開始
    print('BLE広告を開始します...');
    await _startBleAdvertising();

    // 繰り返しスキャンを開始
    print('BLEスキャンを開始します...');
    _startRepeatingScan();
    print('✅ 初期化完了\n');
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    FlutterBluePlus.stopScan();
    _stopBleAdvertising();
    _scanSubscription?.cancel(); // スキャン購読をキャンセル
    _pageController.dispose();
    _blePeripheral.stop();
    super.dispose();
  }

  // 繰り返しスキャンを開始
  void _startRepeatingScan() {
    // すぐにスキャンを開始し、タイムアウト後に自動的に再開
    _startBleScan();
  }

  // BLEスキャンを開始
  Future<void> _startBleScan() async {
    if (_isScanning) {
      print('⚠️ すでにスキャン中です');
      return;
    }

    _isScanning = true;
    print('\n========================================');
    print('🔍 BLEスキャン開始...');
    print('自分のプロフィールID: $_myProfileId');
    print('========================================');

    try {
      // Bluetoothがオンになっているか確認
      if (await FlutterBluePlus.isSupported == false) {
        print('❌ このデバイスはBluetoothをサポートしていません');
        _isScanning = false;
        return;
      }

      // Bluetooth状態を確認
      var adapterState = await FlutterBluePlus.adapterState.first;
      print('📡 Bluetoothアダプター状態: $adapterState');

      // カスタムサービスUUIDでフィルタリングしてスキャン開始
      print('🔎 スキャン開始: $customServiceUuid');
      print('⏱️  タイムアウト: 4秒');

      await FlutterBluePlus.startScan(
        withServices: [Guid(customServiceUuid)],
        timeout: const Duration(seconds: 4),
      );

      // スキャン結果をリッスン（スキャン中継続的にチェック）
      StreamSubscription? scanSubscription;
      String? detectedProfileId;
      int checkCount = 0;

      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        checkCount++;
        print('📊 スキャンチェック #$checkCount: ${results.length}件');

        if (results.isNotEmpty && detectedProfileId == null) {
          print('✅ デバイス検出: ${results.length}件のデバイスを発見！');

          // 相手のプロフィールIDを取得
          for (var i = 0; i < results.length; i++) {
            var result = results[i];
            print('\n--- デバイス #${i + 1} ---');
            print('  名前: ${result.device.platformName}');
            print('  ID: ${result.device.remoteId}');
            print('  RSSI: ${result.rssi}');

            // Service Dataから相手のプロフィールIDを取得
            final serviceData = result.advertisementData.serviceData;
            print('  Service Data: $serviceData');
            print('  Service UUIDs: ${result.advertisementData.serviceUuids}');

            if (serviceData.containsKey(Guid(customServiceUuid))) {
              try {
                final bytes = serviceData[Guid(customServiceUuid)]!;
                detectedProfileId = utf8.decode(bytes);
                print('✅ 相手のプロフィールIDを検知: $detectedProfileId');
                break;
              } catch (e) {
                print('⚠️ プロフィールIDのデコードエラー: $e');
              }
            } else {
              print('⚠️ Service Dataに目的のUUIDが含まれていません');
            }
          }
        }
      });

      // タイムアウトまで待機（4秒）
      await Future.delayed(const Duration(seconds: 4));

      // スキャンを停止
      print('⏹️  スキャン停止');
      await FlutterBluePlus.stopScan();
      await scanSubscription?.cancel();
      _isScanning = false;

      // プロフィールIDが取得できた場合、すれ違い処理を実行
      if (detectedProfileId != null && mounted) {
        print('\n🎉 すれ違い検出成功！');
        print('相手のプロフィールID: $detectedProfileId');
        await _handleEncounter(detectedProfileId!);

        // すれ違い成功画面へ遷移
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScreenEncounter()),
          );
        }

        // 画面から戻ってきたら、少し待機して再スキャン
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          _startRepeatingScan();
        }
      } else {
        // 検出されなかった場合は、短い待機後に再スキャン
        print('\n❌ すれ違い検出なし（総チェック回数: $checkCount）');
        print('🔄 1秒後に再スキャン開始...');
        print('========================================\n');

        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          _startRepeatingScan();
        }
      }
    } catch (e) {
      print('BLEスキャンエラー: $e');
      _isScanning = false;

      // エラーが発生しても2秒後に再試行
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        _startRepeatingScan();
      }
    }
  }

  // BLE広告を開始（プロフィールIDをService Dataに含める）
  Future<void> _startBleAdvertising() async {
    if (_myProfileId == null) {
      print('❌ プロフィールIDがnullのため広告を開始できません');
      return;
    }

    try {
      print('\n========================================');
      print('📢 BLE広告開始中...');
      final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

      // プロフィールIDをバイト列にエンコード
      final List<int> profileIdBytes = utf8.encode(_myProfileId!);
      print('プロフィールID: $_myProfileId');
      print('エンコード後: $profileIdBytes');
      print('バイト数: ${profileIdBytes.length}');

      final AdvertiseData advertiseData = AdvertiseData(
        serviceUuid: customServiceUuid,
        serviceData: profileIdBytes,
        includePowerLevel: true,
      );

      await blePeripheral.start(advertiseData: advertiseData);
      print('✅ BLE広告開始成功！');
      print('サービスUUID: $customServiceUuid');
      print('========================================\n');
    } catch (e) {
      print('❌ BLE広告エラー: $e');
      print('========================================\n');
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

      // サーバーから相手のプロフィール情報を取得
      Profile? encounteredProfile = await _fetchProfileFromServer(
        encounteredProfileId,
      );

      // プロフィール情報が取得できなかった場合、デフォルトプロフィールを使用
      if (encounteredProfile == null) {
        encounteredProfile = Profile(
          profileId: encounteredProfileId,
          nickname: 'すれ違った人 (${encounteredProfileId.substring(0, 8)}...)',
          birthday: '未登録',
          hometown: '未登録',
          trivia: 'プロフィール未登録のユーザーです',
        );
        print('デフォルトプロフィールを使用します');
      }
      
      print('プロフィール取得成功: ${encounteredProfile.nickname}');

      // すれ違い履歴に保存
      final encounter = Encounter(
        profile: encounteredProfile,
        encounterTime: DateTime.now(),
      );
      await _profileService.saveEncounter(encounter);
      print('✅ すれ違い履歴を保存しました: ${encounteredProfile.nickname}');
    } catch (e) {
      print('❌ すれ違い処理エラー: $e');
    }
  }

  // サーバーから相手のプロフィール情報を取得
  Future<Profile?> _fetchProfileFromServer(String profileId) async {
    try {
      print('サーバーからプロフィールを取得中...');
      
      final url = Uri.parse('https://cylinderlike-dana-cryoscopic.ngrok-free.dev/get_profile');
      final response = await http.get(
        url,
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 5));

      print('サーバーレスポンス: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('取得したデータ: $data');
        
        // バックエンドのキー名に合わせて変換
        final profile = Profile(
          profileId: profileId,
          nickname: data['nickname'] ?? '未設定',
          birthday: data['birthday'] ?? '',
          hometown: data['birthplace'] ?? '', // birthplace→hometown
          trivia: data['trivia'] ?? '',
        );
        
        return profile;
      } else if (response.statusCode == 404) {
        print('プロフィールが見つかりませんでした');
        return null;
      }
      
      return null;
    } catch (e) {
      print('プロフィール取得エラー: $e');
      return null;
    }
  }

  // メニューのデータ
  final List<Map<String, dynamic>> _screens = [
    {
      'title': 'ホーム',
      'icon': Icons.home_rounded,
      'color': Colors.green.shade600,
    },
    {
      'title': 'マイプロフィール',
      'icon': Icons.person_rounded,
      'color': Colors.blue.shade400,
    },
    {
      'title': '出身地埋め',
      'icon': Icons.map_rounded,
      'color': Colors.orange.shade400,
    }, // index: 2
    {
      'title': '誕生日埋め',
      'icon': Icons.cake_rounded,
      'color': Colors.pink.shade400,
    },
    {
      'title': '広場',
      'icon': Icons.people_alt_rounded,
      'color': Colors.teal.shade400,
    },
    {
      'title': 'トロフィー',
      'icon': Icons.emoji_events_rounded,
      'color': Colors.amber.shade600,
    },
    {
      'title': '履歴',
      'icon': Icons.history_rounded,
      'color': Colors.purple.shade400,
    },
  ];



  // アイコンをタップしたときの処理
  void _onIconTapped(int index) {
    if (index == _selectedIndex) {
      if (index == 1) {
        // プロフィール編集画面へ遷移 (ScreenProfile)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScreenProfile(profileId: _myProfileId)),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenMap()),
        );
      } else if (index == 3) {
        // ScreenThreeがscreen_birthday.dartにあると仮定
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenBirthday()),
        );
      } else if (index == 0) {
        // ホームボタンを押したとき（特に何もしないか、更新など）
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ここがホームです')));
      } else if (index == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenEleven()),
        ).then((_) {
          // 広場画面から戻ってきたらカードを再読み込み
          _loadDisplayedCards();
        });
      } else if (index == 5) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenTen()),
        );
      } else if (index == 6) {
        // 履歴画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenHistory()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_screens[index]['title']} は準備中です')),
        );
      }
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ■■■ 修正：詳細ダイアログの表示内容を変更しました ■■■
  void _showProfileDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(data['icon'], size: 30),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  data['nickname'], // 名前 -> ニックネーム
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 出身地と誕生日を表示
              _buildInfoRow(Icons.location_on, '出身地', data['birthplace']),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.cake, '誕生日', data['birthday']),
              
              const Divider(height: 30, thickness: 1),
              
              // トリビア表示
              const Text('【私のトリビア】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['trivia'], // コメント/趣味 -> トリビア
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  // ダイアログ内の行を作るためのヘルパー関数
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label：', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.green.shade600, // ホーム画面の背景色（固定）
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 60), // AppBarの高さ分
                  
                  // ===== トリビアカード展示エリア =====
                  Expanded(
                    child: _displayedCards.isEmpty
                        ? const Center(
                            child: Text(
                              '広場でトリビアカードを完了すると\nここに展示されます',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            physics: const BouncingScrollPhysics(), // スクロール可能に
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3列
                              childAspectRatio: 2.5, // 横長の名刺型（コンパクト）
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                            itemCount: _displayedCards.length,
                            itemBuilder: (context, index) {
                              final card = _displayedCards[index];
                              return _buildTriviaCard(card);
                            },
                          ),
                  ),
                  
                  // ホームのタイトル部分（下半分）
                  Text(
                  'ホーム',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                  ),
                ),
                const SizedBox(height: 20),

                // ここにGridView.builderを追加
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return Card(
                        elevation: 2,
                        color: profile['color'],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showProfileDetail(profile),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.5),
                                child: Icon(profile['icon'], color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profile['nickname'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                profile['birthplace'],
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                  const SizedBox(height: 10),
                  const Icon(Icons.home_rounded, size: 60, color: Colors.white),
                  const SizedBox(height: 100), // アイコンとかぶらないための余白
                ],
              ),
            ),
          ),

          // 下部メニュー (変更なし)
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
                    _selectedIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final bool isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50, // 選択中は上に上がる
                        bottom: isSelected ? 20 : 5,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 選択中は少し光らせる演出（お好みで）
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'],
                          // 選択中はサイズ50、それ以外は30
                          size: isSelected ? 50 : 30,
                          // 選択中は白くハッキリ、それ以外は半透明
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
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

  // トリビアカードのウィジェットを構築（名刺型）
  Widget _buildTriviaCard(TriviaCard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // タイトル
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  card.content,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // へーカウントと日付
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, size: 36, color: Colors.amber),
                    const SizedBox(width: 1),
                    Text(
                      '${card.heeCount}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${card.completedAt.month}/${card.completedAt.day}',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
