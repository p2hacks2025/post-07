import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:math' as math;
import '../services/profile_service.dart';
import '../models/trivia_card.dart';

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
  final ProfileService _profileService = ProfileService();

  // デモ用のカード情報
  final List<Map<String, String>> _cardData = [
    {
      'title': 'トリビアカード1',
      'content': 'コーヒーは世界で最も取引されている商品の一つです',
    },
    {
      'title': 'トリビアカード2',
      'content': '人間の脳は約860億個のニューロンで構成されています',
    },
    {
      'title': 'トリビアカード3',
      'content': '地球上で最も深い場所はマリアナ海溝で約11,000mの深さです',
    },
  ];

  @override
  void initState() {
    super.initState();

    // 登場（右 → 中央）
    _enterController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _enterX = Tween<double>(begin: 1.2, end: 0.5).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeInOut),
    );

    // 退場（中央 → 左）
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

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onCardComplete(int index) async {
    // カード情報を保存
    final card = TriviaCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}_$index',
      title: _cardData[index]['title']!,
      content: _cardData[index]['content']!,
      heeCount: _heeCounts[index],
      completedAt: DateTime.now(),
    );
    
    await _profileService.saveDisplayedCard(card);
    print('カードを保存しました: ${card.title}');

    // 次のカードへ or 退場
    if (mounted) {
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

          final double x = _phase == Phase.exiting ? _exitX.value : _enterX.value;

          final double jumpY = _phase == Phase.entering
              ? math.max(0, math.sin(2*3 * math.pi * 2 * t) * 80)
              : 0;

          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final modelWidth = screenWidth * 1.0; // 画面幅の100%
          final modelHeight = screenHeight * 0.8; // 画面高さの80%

          return Stack(
            children: [
              Container(color: Colors.white),

              // 3Dモデルの人キャラクター（背面に配置）
              Positioned(
                left: screenWidth * x - (modelWidth / 2),
                bottom: 20 + jumpY,
                child: SizedBox(
                  width: modelWidth,
                  height: modelHeight,
                  child: ModelViewer(
                    src: 'assets/models/p2hacks2025_catgirl.glb',
                    autoRotate: false,
                    cameraControls: false,
                    disableZoom: true,
                    backgroundColor: Colors.transparent,
                    environmentImage: 'neutral',
                  ),
                ),
              ),

              // 中央カード表示（前面に配置）
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'カード ${index + 1}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  _cardData[index]['content']!,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
