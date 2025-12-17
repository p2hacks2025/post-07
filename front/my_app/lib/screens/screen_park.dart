import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:math' as math;
import 'dart:ui';


class ScreenEleven extends StatefulWidget {
  const ScreenEleven({super.key});

  @override
  State<ScreenEleven> createState() => _ScreenElevenState();
}

class _ScreenElevenState extends State<ScreenEleven>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;
  late Animation<double> _positionAnimation;
  late Animation<double> _exitPositionAnimation;
  late Animation<double> _boardScaleAnimation;
  bool _showBoard = false;
  bool _showButton = false;
  bool _isExiting = false;
  
  int _currentPerson = 1;
  final int _totalPersons = 3;
  int _heeCount = 0;
  final int _maxHeeCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 右から中央への移動アニメーション (1.0 -> 0.5)
    _positionAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // 退場アニメーション（中央から左へ: 0.5 -> -0.5）
    _exitPositionAnimation = Tween<double>(begin: 0.5, end: -0.5).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    // ボードの拡大アニメーション (0.0 -> 1.0)
    _boardScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showBoard = true;
          _showButton = true;
        });
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentPerson < _totalPersons) {
          // 次の人を表示
          setState(() {
            _currentPerson++;
            _isExiting = false;
          });
          _controller.reset();
          _exitController.reset();
          _controller.forward();
        } else {
          // 全員終了したらメイン画面に戻る
          Navigator.pop(context);
        }
      }
    });

    // アニメーション開始
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onComplete() {
    setState(() {
      _showBoard = false;
      _showButton = false;
      _isExiting = true;
      _heeCount = 0; // 次の人のためにリセット
    });

    // 左に退場するアニメーション開始
    _exitController.forward();
  }

  void _onHee() {
    if (_heeCount < _maxHeeCount) {
      setState(() {
        _heeCount++;
      });
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
        animation: Listenable.merge([_controller, _exitController]),
        builder: (context, child) {
          // 現在の位置を計算
        final double t = _controller.value; // 0.0 → 1.0

            // ===== 横移動（右 → 中央）=====
            // 現在の横位置
              final double x = _isExiting
                  ? _exitPositionAnimation.value   // 中央 → 左
                  : _positionAnimation.value;      // 右 → 中央


            // ===== ジャンプ（2回）=====
       

          const int jumpCount = 2;
          const double jumpHeight = 80;

          final double y = !_isExiting
              ? math.sin(2 * math.pi * jumpCount * t) * jumpHeight
              : 0;

          final double jumpY = math.max(0, y);



          return Stack(
            children: [
              // 背景
              Container(color: Colors.white),

              // カウンター表示（画面上部）
              if (!_showBoard)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        '今回の手紙 $_currentPerson/$_totalPersons 人目',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // 赤いボードを画面いっぱいに表示
              if (_showBoard)
                Center(
                  child: Transform.scale(
                    scale: _boardScaleAnimation.value,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 赤いボード
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),

                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_active,
                                  size: 100,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '重要なお知らせ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                if (_showButton)
                                  Column(
                                    children: [
                                      // へーカウント表示
                                      Text(
                                        'へー: $_heeCount / $_maxHeeCount',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // ボタン行
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // へーボタン
                                          ElevatedButton(
                                            onPressed: _heeCount < _maxHeeCount ? _onHee : null,
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(150, 60),
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: Colors.grey,
                                            ),
                                            child: const Text(
                                              'へー',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          // 完了ボタン
                                          ElevatedButton(
                                            onPressed: _onComplete,
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(150, 60),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text(
                                              '完了',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 左手
                        Positioned(
                          left: -50,
                          top: MediaQuery.of(context).size.height * 0.35 - 50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.brown[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // 右手
                        Positioned(
                          right: -50,
                          top: MediaQuery.of(context).size.height * 0.35 - 50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.brown[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // // 人のキャラクター
              // if (!_showBoard)
              //   Positioned(
              //     left: MediaQuery.of(context).size.width * currentPosition - 200,
              //     bottom: -250,
              //     child: Column(
              //       children: [
              //         // 人の頭
              //         Container(
              //           width: 180,
              //           height: 180,
              //           decoration: const BoxDecoration(
              //             color: Colors.brown,
              //             shape: BoxShape.circle,
              //           ),
              //         ),
              //         // 人の体
              //         Container(
              //           width: 220,
              //           height: 350,
              //           decoration: BoxDecoration(
              //             color: Colors.blue[700],
              //             borderRadius: BorderRadius.circular(30),
              //           ),
              //         ),
              //         const SizedBox(height: 20),
              //         // 赤いボードと手
              //         Stack(
              //           clipBehavior: Clip.none,
              //           children: [
              //             // 赤いボード
              //             Container(
              //               width: 280,
              //               height: 350,
              //               decoration: BoxDecoration(
              //                 color: Colors.red,
              //                 borderRadius: BorderRadius.circular(20),
              //                 border: Border.all(color: Colors.black, width: 6),
              //               ),
              //               child: const Center(
              //                 child: Icon(
              //                   Icons.notification_important,
              //                   color: Colors.white,
              //                   size: 140,
              //                 ),
              //               ),
              //             ),
              //             // 左手
              //             Positioned(
              //               left: -35,
              //               top: 20,
              //               child: Container(
              //                 width: 70,
              //                 height: 70,
              //                 decoration: BoxDecoration(
              //                   color: Colors.brown[300],
              //                   shape: BoxShape.circle,
              //                 ),
              //               ),
              //             ),
              //             // 右手
              //             Positioned(
              //               right: -35,
              //               top: 20,
              //               child: Container(
              //                 width: 70,
              //                 height: 70,
              //                 decoration: BoxDecoration(
              //                   color: Colors.brown[300],
              //                   shape: BoxShape.circle,
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),

              // 3Dキャラクター
                if (!_showBoard)
                Positioned(
                 left: MediaQuery.of(context).size.width * x - 150,
                  bottom: -50 + jumpY,
                  child: SizedBox(
                    width: 300,
                    height: 500,
                    child: ModelViewer(
                      src: 'assets/models/p2hacks2025_catgirl.glb',
                      autoRotate: false,
                      cameraControls: false,
                      disableZoom: true,

                      // ⚠ animationName は一旦消す（後で説明）
                      // animationName: _isExiting ? 'exit' : 'enter',

                      backgroundColor: Colors.white,
                      environmentImage: 'neutral',
                    ),
                  ),
                ),


                 


            ],
          );
        },
      ),
    );
  }
}
