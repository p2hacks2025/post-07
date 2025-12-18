import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'dart:math' as math;

class ScreenEleven extends StatefulWidget {
  const ScreenEleven({super.key});

  @override
  State<ScreenEleven> createState() => _ScreenElevenState();
}

enum Phase {
  entering, // 右から跳ねて登場
  showing,  // 中央でカード提示
  exiting,  // 左へ退場
}

class _ScreenElevenState extends State<ScreenEleven>
    with TickerProviderStateMixin {
  Phase _phase = Phase.entering;

  late AnimationController _enterController;
  late AnimationController _exitController;
  late Animation<double> _enterX;
  late Animation<double> _exitX;

  final PageController _pageController = PageController();
  final int _totalCards = 3;
  final int _maxHeeCount = 20;
  final List<int> _heeCounts = [0, 0, 0];

  // 3Dモデル用コントローラ
  late Flutter3DController _modelController;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();

    _modelController = Flutter3DController();

    // 登場アニメーション
    _enterController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _enterX = Tween<double>(begin: 1.2, end: 0.5).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeInOut),
    );

    // 退場アニメーション
    _exitController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _exitX = Tween<double>(begin: 0.5, end: -0.5).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    // 登場完了 → カード表示
    _enterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _phase = Phase.showing;
        });
      }
    });

    // 退場完了 → 画面終了
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context);
      }
    });

    // タイムアウト保険：0.4秒後にまだロードされていなければ強制開始
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!_modelLoaded) {
        _modelLoaded = true;
        _enterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _pageController.dispose();
    // _modelController.dispose(); // Flutter3DController は自動で解放されるので不要
    super.dispose();
  }

  void _onCardComplete(int index) {
    if (index < _totalCards - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      setState(() {
        _phase = Phase.exiting;
      });
      _exitController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画面11'),
        backgroundColor: Colors.red,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_enterController, _exitController]),
        builder: (context, _) {
          final t = _enterController.value;
          final double x =
              _phase == Phase.exiting ? _exitX.value : _enterX.value;
          final double jumpY = _phase == Phase.entering
              ? math.max(0, math.sin(2 * 3 * math.pi * 2 * t) * 80)
              : 0;

          return Stack(
            children: [
              Container(color: Colors.white),

              // 3Dモデルの人キャラクター
              Positioned(
                left: MediaQuery.of(context).size.width * x - 150,
                bottom: -50 + jumpY,
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Flutter3DViewer(
                    controller: _modelController,
                    src: 'assets/models/p2hacks2025_catgirl.glb',

                    // 読み込み進捗
                    onProgress: (double progressValue) {
                      if (!_modelLoaded && progressValue >= 1.0) {
                        _modelLoaded = true;
                        _enterController.forward();
                      }
                      debugPrint('loading: $progressValue');
                    },

                    // ロード完了時
                    onLoad: (String modelPath) {
                      if (!_modelLoaded) {
                        _modelLoaded = true;
                        _enterController.forward();
                      }
                    },

                    // ロード失敗時
                    onError: (String error) {
                      debugPrint('Error loading model: $error');
                      // 保険としてロード失敗でも進める
                      if (!_modelLoaded) {
                        _modelLoaded = true;
                        _enterController.forward();
                      }
                    },
                  ),
                ),
              ),

              // ロード中インジケータ
              if (!_modelLoaded)
                const Center(child: CircularProgressIndicator()),

              // 中央カード表示
              if (_phase == Phase.showing)
                Center(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _totalCards,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildCard(index);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(int index) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active,
                size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'カード ${index + 1}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'へー: ${_heeCounts[index]} / $_maxHeeCount',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _heeCounts[index] < _maxHeeCount
                      ? () {
                          setState(() {
                            _heeCounts[index]++;
                          });
                        }
                      : null,
                  child: const Text('へー'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _onCardComplete(index),
                  child: const Text('完了'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
