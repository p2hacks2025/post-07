import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'dart:async';

import '../screens/screen_encounter.dart';

/// BLEすれ違い機能を提供するサービスクラス
class BleEncounterService {
  // カスタムサービスUUID
  static const String customServiceUuid = '0000FFF0-0000-1000-8000-00805f9b34fb';
  
  Timer? _scanTimer;
  bool _isScanning = false;
  bool _isAdvertising = false;
  FlutterBlePeripheral? _blePeripheral;
  BuildContext? _context;

  /// サービスを初期化して開始
  Future<void> start(BuildContext context) async {
    _context = context;
    
    // BLE広告を開始
    await _startBleAdvertising();
    
    // 繰り返しスキャンを開始
    _startRepeatingScan();
  }

  /// サービスを停止
  Future<void> stop() async {
    _scanTimer?.cancel();
    await FlutterBluePlus.stopScan();
    await _stopBleAdvertising();
    _context = null;
  }

  /// 繰り返しスキャンを開始
  void _startRepeatingScan() {
    _startBleScan();
  }

  /// BLEスキャンを開始
  Future<void> _startBleScan() async {
    if (_isScanning || _context == null) return;
    
    _isScanning = true;
    
    try {
      // カスタムサービスUUIDでフィルタリングしてスキャン開始
      await FlutterBluePlus.startScan(
        withServices: [Guid(customServiceUuid)],
        timeout: const Duration(seconds: 5),
      );

      // スキャン結果をリッスン
      FlutterBluePlus.scanResults.listen((results) async {
        if (results.isNotEmpty && _context != null && _context!.mounted) {
          // デバイスを検知したらスキャンを停止
          await FlutterBluePlus.stopScan();
          _isScanning = false;
          
          // すれ違い成功画面へ遷移
          if (_context != null && _context!.mounted) {
            await Navigator.push(
              _context!,
              MaterialPageRoute(builder: (context) => const ScreenEncounter()),
            );
          }
          
          // 画面から戻ってきたら、5秒後に再度スキャン開始
          if (_context != null && _context!.mounted) {
            await Future.delayed(const Duration(seconds: 5));
            _startRepeatingScan();
          }
        }
      });

      // タイムアウト後も5秒待機して再スキャン
      await Future.delayed(const Duration(seconds: 5));
      if (_isScanning && _context != null && _context!.mounted) {
        await FlutterBluePlus.stopScan();
        _isScanning = false;
      }
      
      if (_context != null && _context!.mounted) {
        await Future.delayed(const Duration(seconds: 5));
        _startRepeatingScan();
      }
    } catch (e) {
      print('BLEスキャンエラー: $e');
      _isScanning = false;
      
      // エラーが発生しても5秒後に再試行
      if (_context != null && _context!.mounted) {
        await Future.delayed(const Duration(seconds: 5));
        _startRepeatingScan();
      }
    }
  }

  /// BLE広告を開始
  Future<void> _startBleAdvertising() async {
    if (_isAdvertising) return;
    
    try {
      _blePeripheral = FlutterBlePeripheral();
      
      final AdvertiseData advertiseData = AdvertiseData(
        serviceUuid: customServiceUuid,
        includePowerLevel: true,
      );

      await _blePeripheral!.start(advertiseData: advertiseData);
      _isAdvertising = true;
      print('🔵 BLE広告開始: $customServiceUuid');
    } catch (e) {
      print('❌ BLE広告エラー: $e');
    }
  }

  /// BLE広告を停止
  Future<void> _stopBleAdvertising() async {
    if (!_isAdvertising || _blePeripheral == null) return;
    
    try {
      await _blePeripheral!.stop();
      _isAdvertising = false;
      print('⚪ BLE広告停止');
    } catch (e) {
      print('❌ BLE広告停止エラー: $e');
    }
  }

  /// スキャン中かどうか
  bool get isScanning => _isScanning;

  /// 広告中かどうか
  bool get isAdvertising => _isAdvertising;
}
