import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScreenEleven extends StatefulWidget {
  const ScreenEleven({super.key});

  @override
  State<ScreenEleven> createState() => _ScreenElevenState();
}

enum Phase { entering, showing, exiting }

class _ScreenElevenState extends State<ScreenEleven> with TickerProviderStateMixin {
  Phase _phase = Phase.entering;
  late AnimationController _enterController;
  late AnimationController _exitController;
  late Animation<double> _enterX;
  late Animation<double> _exitX;

  final PageController _pageController = PageController();
  final int _totalCards = 3;
  final int _maxHeeCount = 20;
  final List<int> _heeCounts = [0, 0, 0];
  bool _isProcessing = false;

  late Flutter3DController _modelController;
  bool _modelLoaded = false;
  
  // 【修正点1】3Dモデルのウィジェットをキャッシュするための変数
  Widget? _cachedModelWidget;

  @override
  void initState() {
    super.initState();
    _modelController = Flutter3DController();

    _enterController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _enterX = Tween<double>(begin: 1.2, end: 0.5).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeInOut),
    );

    _exitController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _exitX = Tween<double>(begin: 0.5, end: -0.5).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _enterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _phase = Phase.showing);
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) Navigator.pop(context);
    });

    // 3Dモデルの生成をinitStateの最後で行う
    _initModelWidget();

    // 保険のタイマー
    Future.delayed(const Duration(seconds: 3), () {
      if (!_modelLoaded && mounted) {
        setState(() => _modelLoaded = true);
        _enterController.forward();
      }
    });
  }

  // 【修正点2】モデルウィジェットを一度だけ生成するメソッド
  void _initModelWidget() {
    _cachedModelWidget = RepaintBoundary( // 描画負荷を分離
      child: SizedBox(
        width: 300,
        height: 500,
        child: Flutter3DViewer(
          controller: _modelController,
          src: 'assets/models/p2hacks2025_catgirl.glb',
          onProgress: (double progress) {
            if (!_modelLoaded && progress >= 1.0) {
              setState(() => _modelLoaded = true);
              _enterController.forward();
            }
          },
          onLoad: (String path) {
            if (!_modelLoaded) {
              setState(() => _modelLoaded = true);
              _enterController.forward();
            }
          },
          onError: (error) => debugPrint('3D Error: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ( _onCardComplete メソッドは変更なしのため中略 )
  void _onCardComplete(int index) async {

    if (_isProcessing) return;
    setState(() => _isProcessing = true);
   
  

    // へぇ数をバックエンドに送信
    try {
      final url = Uri.parse('https://saliently-multiciliated-jacqui.ngrok-free.dev/heyplus');
      
      final data = {
        'id': 'abcde', //仮置き
        'ver':0,//仮置き
        'pushedhey': _heeCounts[index], // 追加情報として送信

      };
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (index < _totalCards - 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        } else {
          setState(() => _phase = Phase.exiting);
          _exitController.forward();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('通信エラーが発生しました')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('trinkle'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // 【修正点3】アニメーションする部分だけをAnimatedBuilderで囲む
          AnimatedBuilder(
            animation: Listenable.merge([_enterController, _exitController]),
            child: _cachedModelWidget, // キャッシュしたモデルを使用
            builder: (context, child) {
              final double x = _phase == Phase.exiting ? _exitX.value : _enterX.value;
              final double jumpY = (_phase == Phase.entering)
                  ? math.max(0, math.sin(2 * 3 * math.pi * 2 * _enterController.value) * 80)
                  : 0;

              return Positioned(
                left: screenWidth * x - 150,
                bottom: 20 + jumpY,
                child: child!,
              );
            },
          ),

          if (!_modelLoaded) const Center(child: CircularProgressIndicator()),

          if (_phase == Phase.showing)
            Center(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalCards,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => _buildCard(index),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text('トリビア ${index + 1}', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('へぇ: ${_heeCounts[index]} / $_maxHeeCount', style: const TextStyle(fontSize: 22, color: Colors.white)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: (_heeCounts[index] < _maxHeeCount && !_isProcessing) ? () => setState(() => _heeCounts[index]++) : null,
                  child: const Text('へぇ！'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _onCardComplete(index),
                  child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('完了'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}