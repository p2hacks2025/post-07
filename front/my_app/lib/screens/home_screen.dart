import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
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
  StreamSubscription? _scanSubscription;
  FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  static const String customServiceUuid = '0000FFF0-0000-1000-8000-00805f9b34fb';

  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isScanning = false;
  final ProfileService _profileService = ProfileService();
  String? _myProfileId;

  // ダミーデータ（プロフィールリスト）
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
      'trivia': '音ゲーの全国大会に出たことがあります。',
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
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    Profile? myProfile = await _profileService.loadMyProfile();
    if (myProfile == null) {
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
    await _startBleAdvertising();
    _startRepeatingScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _stopBleAdvertising();
    _scanSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 繰り返しスキャンを開始（Timer.periodicで制御）
  void _startRepeatingScan() {
    if (_scanTimer?.isActive ?? false) return;
    
    // 最初のスキャンをすぐに実行
    _startBleScan();
    
    // 15秒ごとに定期的にスキャン
    _scanTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isScanning && mounted) {
        await _startBleScan();
      }
    });
  }

  Future<void> _startBleScan() async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      if (await FlutterBluePlus.isSupported == false) return;
      await FlutterBluePlus.startScan(
        withServices: [Guid(customServiceUuid)],
        timeout: const Duration(seconds: 4),
      );
      
      String? detectedProfileId;
      StreamSubscription? scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final serviceData = result.advertisementData.serviceData;
          if (serviceData.containsKey(Guid(customServiceUuid))) {
            detectedProfileId = utf8.decode(serviceData[Guid(customServiceUuid)]!);
            break;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();
      _isScanning = false;

      if (detectedProfileId != null && mounted) {
        await _handleEncounter(detectedProfileId!);

        // すれ違い成功画面へ遷移
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScreenEncounter()),
          );
        }

        // 画面から戻ってきてもTimerが自動的に再スキャンを実行
      } else {
        // 検出されなかった場合（Timerが自動的に再スキャンを実行）
        print('\n❌ すれ違い検出なし（総チェック回数: $checkCount）');
        print('🔄 次のスキャンはTimerが自動実行します');
        print('========================================\n');
      }
    } catch (e) {
      print('BLEスキャンエラー: $e');
      _isScanning = false;
      // エラーが発生してもTimerが自動的に再試行
    }
  }

  Future<void> _startBleAdvertising() async {
    if (_myProfileId == null) return;
    try {
      final AdvertiseData advertiseData = AdvertiseData(
        serviceUuid: customServiceUuid,
        serviceData: utf8.encode(_myProfileId!),
        includePowerLevel: true,
      );
      await _blePeripheral.start(advertiseData: advertiseData);
    } catch (e) { debugPrint('BLE Advertising Error: $e'); }
  }

  Future<void> _stopBleAdvertising() async => await _blePeripheral.stop();

  Future<void> _handleEncounter(String id) async {
    Profile? profile = await _fetchProfileFromServer(id);
    profile ??= Profile(profileId: id, nickname: 'すれ違った人', birthday: '', hometown: '', trivia: '');
    await _profileService.saveEncounter(Encounter(profile: profile, encounterTime: DateTime.now()));
  }

  Future<Profile?> _fetchProfileFromServer(String id) async {
    try {
      final url = Uri.parse('https://cylinderlike-dana-cryoscopic.ngrok-free.dev/get_profile');
      final res = await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'}).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return Profile(profileId: id, nickname: d['nickname'] ?? '', birthday: d['birthday'] ?? '', hometown: d['birthplace'] ?? '', trivia: d['trivia'] ?? '');
      }
    } catch (e) { return null; }
    return null;
  }

  // --- メニュー設定 ---
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'color': Colors.green.shade600},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded, 'color': Colors.blue.shade400},
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'color': Colors.orange.shade400},
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'color': Colors.pink.shade400},
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'color': Colors.teal.shade400},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber.shade600},
    {'title': '履歴', 'icon': Icons.history_rounded, 'color': Colors.purple.shade400},
  ];

  // アイコンをタップしたときの処理
  void _onIconTapped(int index) {
    if (index == _selectedIndex) {
      Widget? target;
      switch (index) {
        case 1: target = const ScreenProfile(); break;
        case 2: target = const ScreenMap(); break;
        case 3: target = const ScreenBirthday(); break;
        case 4: target = const ScreenEleven(); break;
        case 5: target = const ScreenAchieve(); break;
        case 6: target = const ScreenHistory(); break;
      }
      if (target != null) Navigator.push(context, MaterialPageRoute(builder: (context) => target!));
    } else {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showProfileDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(data['icon']), const SizedBox(width: 10), Text(data['nickname'])]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(Icons.location_on, '出身地', data['birthplace']),
            _buildInfoRow(Icons.cake, '誕生日', data['birthday']),
            const Divider(),
            Text(data['trivia']),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
      ),
    );
  }

  Widget _buildInfoRow(IconData i, String l, String v) => Row(children: [Icon(i, size: 16), Text(' $l: $v')]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景とメインコンテンツ
          Positioned.fill(
            child: Container(
              color: Colors.green.shade600,
              child: SafeArea( // ステータスバーを考慮
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // 1. タイトル
                    const Text(
                      'ホーム',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 2. プロフィールグリッド（画面中央のメイン）
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.58,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final p = _profiles[index];
                          return Card(
                            elevation: 3,
                            color: p['color'],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: InkWell(
                              onTap: () => _showProfileDetail(p),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(backgroundColor: Colors.white54, child: Icon(p['icon'], color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Text(p['nickname'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text(p['birthplace'], style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
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
                  const SizedBox(height: 10),
                  const Text(
                    'ホーム',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.home_rounded, size: 60, color: Colors.white),
                  const SizedBox(height: 100), // アイコンとかぶらないための余白
                ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 90), // 下部メニュー用のスペース
                  ],
                ),
              ),
            ),
          ),

          // 下部メニュー
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                onPageChanged: (index) => setState(() => _selectedIndex = index),
                itemBuilder: (context, index) {
                  final bool isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(top: isSelected ? 30 : 50, bottom: isSelected ? 20 : 5),
                      child: Icon(
                        _screens[index]['icon'],
                        size: isSelected ? 55 : 30,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // タイトル
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // コンテンツ
            Expanded(
              child: Text(
                card.content,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // へーカウントと日付
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${card.heeCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${card.completedAt.month}/${card.completedAt.day}',
                  style: const TextStyle(
                    fontSize: 11,
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
