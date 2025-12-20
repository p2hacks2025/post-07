import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:uuid/uuid.dart';

// ===============================
// BLEすれ違い検知サンプル（交互実行・16byteバイナリUUID）
// ===============================
// 重要な修正点:
// - ScanとAdvertiseを同時に行わず「交互」に実行（OS制限・干渉対策）
// - profileIdは16byteバイナリUUIDで送信（文字列より小さい）
// - Manufacturer Dataは profileId(16byte) + version(1byte) = 17byte
// - Scan/Advertise時間は現実的な秒数（例: 5秒ずつ）
// ===============================

const int manufacturerId = 0x1234; // 任意の2byte (0xFFFF以下)
const int appVersion = 1; // 例: アプリのバージョン番号
const int scanDurationSec = 5; // Scan時間（秒）
const int advertiseDurationSec = 5; // Advertise時間（秒）

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  bool _isScanning = false;
  bool _isAdvertising = false;
  String? _myProfileId;
  late Uint8List _myProfileIdBytes;
  int _selectedIndex = 0;
  late PageController _pageController;
  StreamSubscription? _scanSub;
  Timer? _mainLoopTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.1);
    _initProfileId();
    _startMainLoop();
  }

  Future<void> _initProfileId() async {
    // profileIdは16byteバイナリUUID（uuidパッケージ利用）
    _myProfileId = const Uuid().v4();
    _initProfileIdBytes();
  }

  // ===============================
  // UUID文字列 → Uint8List変換関数
  // ===============================
  void _initProfileIdBytes() {
    // Uuid.parse()はList<int>型を返すので、Uint8List.fromList()で型変換
    // BLE Manufacturer DataはUint8List型のみ受け付けるため
    _myProfileIdBytes = Uint8List.fromList(
      Uuid.parse(_myProfileId!)
    );
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

  // ===============================
  // BLE: Manufacturer DataでScan（16byteバイナリUUID）
  // ===============================
  Future<void> _startBleScan() async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: scanDurationSec),
      );
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          final mdata = result.advertisementData.manufacturerData;
          final data = mdata[manufacturerId];
          if (data == null || data.length != 17) continue;
          final profileIdBytes = data.sublist(0, 16);
          final version = data[16];
          final profileIdStr = Uuid.unparse(profileIdBytes);
          // 自分自身は除外
          if (profileIdStr == _myProfileId) continue;
          debugPrint('🎯 すれ違い検出: profileId=$profileIdStr, version=$version');
          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();
          _isScanning = false;
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('すれ違い成功'),
              content: Text('profileId: $profileIdStr\nversion: $version'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ BLEスキャンエラー: $e');
      _isScanning = false;
    }
  }

  // ===============================
  // UI（変更なし）
  // ===============================
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
      // シーン遷移を行わない
      return;
    } else {
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
      backgroundColor: Colors.green.shade600,
      body: Stack(
        children: [
          const Center(
            child: Text(
              'ホーム',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                onPageChanged: (i) => setState(() => _selectedIndex = i),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50,
                        bottom: isSelected ? 20 : 5,
                      ),
                      child: Icon(
                        _screens[index]['icon'],
                        size: isSelected ? 55 : 30,
                        color: Colors.white.withOpacity(isSelected ? 1 : 0.5),
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