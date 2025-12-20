import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:http/http.dart' as http;

import 'package:uuid/uuid.dart';

// 遷移先の各画面（プロジェクトに合わせてインポートパスを確認してください）
import 'screen_profile.dart';
import 'screen_map.dart';
import 'screen_birthday.dart';
import 'screen_achieve.dart';
import 'screen_park.dart'; // 広場（ScreenEleven）用
import 'screen_encounter.dart';
import 'screen_history.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../models/encounter.dart';

const int manufacturerId = 0x1234; // 任意の2byte (0xFFFF以下)
const int appVersion = 1; // 例: アプリのバージョン番号
const int scanDurationSec = 5; // Scan時間（秒）
const int advertiseDurationSec = 5; // Advertise時間（秒）

void main() {
  runApp(
    const MaterialApp(
      home: HomeScreen(
        profileJson: {
          "uid": "debug-uid-001",
        },
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> profileJson;

  const HomeScreen({
    super.key,
    required this.profileJson,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  StreamSubscription? _scanSubscription;
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  static const String customServiceUuid =
      '0000FFF0-0000-1000-8000-00805f9b34fb';

  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isScanning = false;
  bool _isAdvertising = false;
  final ProfileService _profileService = ProfileService();
  String? _myProfileId;

  late Uint8List _myProfileIdBytes;
  StreamSubscription? _scanSub;
  Timer? _mainLoopTimer;
  

  // ダミーデータ（プロフィールリスト）
  final List<Map<String, dynamic>> _profiles = [
    {
      'nickname': 'タロウ',
      'birthday': '1月15日',
      'birthplace': '北海道',
      'trivia': '実は犬より猫派です。',
      'color': Colors.blue.shade100,
      'icon': Icons.face
    },
    {
      'nickname': 'はなちゃん',
      'birthday': '5月22日',
      'birthplace': '東京都',
      'trivia': '砂糖は3本入れます！',
      'color': Colors.pink.shade100,
      'icon': Icons.face_3
    },
    {
      'nickname': 'イチロー',
      'birthday': '10月22日',
      'birthplace': '愛知県',
      'trivia': '焚き火の匂いが好き。',
      'color': Colors.green.shade100,
      'icon': Icons.face_6
    },
    {
      'nickname': 'ゆう',
      'birthday': '3月3日',
      'birthplace': '福岡県',
      'trivia': '音ゲー大会に出ました。',
      'color': Colors.orange.shade100,
      'icon': Icons.face_5
    },
    {
      'nickname': 'ケンタ',
      'birthday': '8月10日',
      'birthplace': '大阪府',
      'trivia': 'お好み焼きはおかずじゃない。',
      'color': Colors.purple.shade100,
      'icon': Icons.face_4
    },
    {
      'nickname': 'みさき',
      'birthday': '7月20日',
      'birthplace': '沖縄県',
      'trivia': '泳げないダイバーです。',
      'color': Colors.cyan.shade100,
      'icon': Icons.face_2
    },
  ];

  @override
  void initState() {
    super.initState();
    // フッターのアイコン間隔を調整するPageController
    // ★ JSON から uid を取得
    _myProfileId = widget.profileJson["uid"] as String?;

    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.15, // アイコンの密度を調整
    );
    _initializeProfile();
    _startMainLoop();
  }

  Future<void> _initProfileId() async {
    // profileIdは16byteバイナリUUID（uuidパッケージ利用）
    _myProfileId = const Uuid().v4();
    _initProfileIdBytes();
  }

  void _initProfileIdBytes() {
    // Uuid.parse()はList<int>型を返すので、Uint8List.fromList()で型変換
    // BLE Manufacturer DataはUint8List型のみ受け付けるため
    _myProfileIdBytes = Uint8List.fromList(
      Uuid.parse(_myProfileId!)
    );
  }






  Future<void> _initializeProfile() async {
    Profile? myProfile = await _profileService.loadMyProfile();
    if (myProfile == null) {
      _myProfileId = _profileService.generateProfileId();
      myProfile = Profile(
          profileId: _myProfileId!,
          nickname: 'ゲスト',
          birthday: '',
          birthplace: '',
          trivia: '');
      await _profileService.saveMyProfile(myProfile);
    } else {
      _myProfileId = myProfile.profileId;
    }

    // profileIdバイト列を必ず初期化
    _initProfileIdBytes();

    // ★★★ エミュレーター対策：ここをコメントアウトしました ★★★
    // エミュレーターはBluetoothを使えないため、ここでエラーになります。
    // 実機でテストするときは、ここのコメントアウト（//）を外してください。
    // await _startBleAdvertising(); 
    // _startRepeatingScan();
  }

  @override
  void dispose() {
    _mainLoopTimer?.cancel();
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _stopBleAdvertising();
    _pageController.dispose();
    super.dispose();
  }

  // ===============================
  // メインループ: Scan→Advertiseを交互に繰り返す
  // ===============================
  void _startMainLoop() {
    // まずScanから開始
    _mainLoopTimer = Timer.periodic(Duration(seconds: scanDurationSec + advertiseDurationSec), (timer) async {
      await _startBleScan();
      await Future.delayed(Duration(seconds: scanDurationSec));
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _isScanning = false;
      await _startBleAdvertising();
      await Future.delayed(Duration(seconds: advertiseDurationSec));
      await _stopBleAdvertising();
      _isAdvertising = false;
    });
    // 最初だけ即時Scan
    _startBleScan();
    Future.delayed(Duration(seconds: scanDurationSec), () async {
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _isScanning = false;
      await _startBleAdvertising();
      await Future.delayed(Duration(seconds: advertiseDurationSec));
      await _stopBleAdvertising();
      _isAdvertising = false;
    });
  }

  // ===============================
  // BLE: Manufacturer DataでAdvertise（16byteバイナリUUID）
  // ===============================
  Future<void> _startBleAdvertising() async {
    if (_isAdvertising) return;
    _isAdvertising = true;
    try {
      // profileId(16byte) + appVersion(1byte) → 17byte
      final data = Uint8List(17)
        ..setRange(0, 16, _myProfileIdBytes)
        ..[16] = appVersion;
      final advertiseData = AdvertiseData(
        manufacturerId: manufacturerId,
        manufacturerData: data,
        includePowerLevel: true,
      );
      await _blePeripheral.start(advertiseData: advertiseData);
      debugPrint('📢 BLE広告開始 (profileId: $_myProfileId, version: $appVersion)');
    } catch (e) {
      debugPrint('❌ BLE広告エラー: $e');
    }
  }

  Future<void> _stopBleAdvertising() async {
    try {
      await _blePeripheral.stop();
    } catch (_) {}
  }





  // --- BLE関連ロジック（省略なし） ---
  void _startRepeatingScan() => _startBleScan();

  Future<void> _startBleScan() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: scanDurationSec),
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          final mData = r.advertisementData.manufacturerData;

          if (!mData.containsKey(manufacturerId)) continue;

          final data = mData[manufacturerId]!;
          if (data.length < 17) continue;

          // UUID復元
          final uuidBytes = data.sublist(0, 16);
          final version = data[16];

          final detectedProfileId = Uuid.unparse(uuidBytes);

          debugPrint(
            '👀 検知！ profileId=$detectedProfileId version=$version',
          );

          // 二重検知防止
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _isScanning = false;

          if (!mounted) return;

          await _handleEncounter(detectedProfileId);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenEncounter()),
          );
          return;
        }
      });
    } catch (e) {
      debugPrint('❌ Scan error: $e');
      _isScanning = false;
    }
  }

  // ...既存の_startBleAdvertising, _stopBleAdvertisingの重複定義を削除...

  Future<void> _handleEncounter(String id) async {
    Profile? profile = await _fetchProfileFromServer(id);
    profile ??= Profile(
        profileId: id,
        nickname: 'すれ違った人',
        birthday: '',
        birthplace: '',
        trivia: '');
    await _profileService.saveEncounter(
        Encounter(profile: profile, encounterTime: DateTime.now()));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<Profile?> _fetchProfileFromServer(String id) async {
    try {
      final url = Uri.parse(
          'https://saliently-multiciliated-jacqui.ngrok-free.dev/get_profile');
      final res = await http.get(url, headers: {
        'ngrok-skip-browser-warning': 'true'
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return Profile(
            profileId: id,
            nickname: d['nickname'] ?? '',
            birthday: d['birthday'] ?? '',
            birthplace: d['birthplace'] ?? '',
            trivia: d['trivia'] ?? '');
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // --- メニュー設定 ---
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded},
    {'title': '出身地埋め', 'icon': Icons.map_rounded},
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded},
    {'title': '広場', 'icon': Icons.people_alt_rounded},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded},
    {'title': '履歴', 'icon': Icons.history_rounded},
  ];

  void _onIconTapped(int index) {
    if (index == _selectedIndex) {
      Widget? target;
      switch (index) {
        case 1:
          target = ScreenProfile(profileJson: widget.profileJson);
          break;
        case 2:
          target = const ScreenMap();
          break;
        case 3:
          target = const ScreenBirthday();
          break;
        case 4:
          target = const ScreenEleven();
          break; // 前回の画面11
        case 5:
          target = const ScreenAchieve();
          break;
        case 6:
          target = const ScreenHistory();
          break;
      }
      if (target != null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => target!));
      }
    } else {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showProfileDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(data['icon']),
          const SizedBox(width: 10),
          Text(data['nickname'])
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(Icons.location_on, '出身地', data['birthplace']),
            _buildInfoRow(Icons.cake, '誕生日', data['birthday']),
            const Divider(),
            Text(data['trivia']),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('閉じる'))
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData i, String l, String v) =>
      Row(children: [Icon(i, size: 16), Text(' $l: $v')]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // メインコンテンツエリア
          Positioned.fill(
            child: Container(
              color: Colors.green.shade600,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'trinkle', // タイトルをアプリ名に
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final p = _profiles[index];
                          return Card(
                            elevation: 4,
                            color: p['color'],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: InkWell(
                              onTap: () => _showProfileDetail(p),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                      backgroundColor: Colors.white70,
                                      child: Icon(p['icon'],
                                          color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Text(p['nickname'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // フッターとの干渉を防ぐためのスペース（少し狭めました）
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ),

          // 下部メニュー（フッター）
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 85, // 全体の高さをスリムに調整
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15), // 背景を少し濃くして「バー」感を演出
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                onPageChanged: (index) =>
                    setState(() => _selectedIndex = index),
                itemBuilder: (context, index) {
                  final bool isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      // topを小さくすることでアイコンを高い位置に維持
                      margin: EdgeInsets.only(
                        top: isSelected ? 8 : 25,
                        bottom: isSelected ? 12 : 5,
                      ),
                      child: Icon(
                        _screens[index]['icon'],
                        size: isSelected ? 50 : 32, // 選択時のサイズを微調整
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
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