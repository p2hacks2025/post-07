import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'screen_information.dart';

class ScreenStart extends StatefulWidget {
  final bool isRegistered;
  final Map<String, dynamic> profileJson; // ★ 追加

  const ScreenStart({super.key, required this.isRegistered,required this.profileJson,});

  @override
  State<ScreenStart> createState() => _ScreenStartState();
}

class _ScreenStartState extends State<ScreenStart> {
  // 光の不透明度を管理する変数
  double _flashOpacity = 0.0;

  Future<void> _handleStart() async {
    // 1. 画面を一瞬で光らせる
    setState(() {
      _flashOpacity = 1.0;
    });

    // 2. 光の演出のために少しだけ待つ（0.3秒程度）
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

     // 🔍 デバッグ：idだけのJSON確認
    debugPrint("現在の profileJson:");
    debugPrint(widget.profileJson.toString());
    
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(profileJson: widget.profileJson)),
      );

    // 3. 次の画面へ遷移
    if (widget.isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScreenInformation()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _handleStart, // タップ時にメソッドを呼び出す
        child: Stack(
          children: [
            // --- レイヤー1: 元々のコンテンツ ---
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 100,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TAP TO START',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '画面をタッチしてはじめる',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // --- レイヤー2: 発光エフェクト用の白い板 ---
            IgnorePointer( // このレイヤーがタップを邪魔しないようにする
              child: AnimatedOpacity(
                opacity: _flashOpacity,
                duration: const Duration(milliseconds: 200), // じわっと光る速度
                curve: Curves.easeIn,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white, // ここを Colors.yellow にすると黄色く光ります
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 50,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}