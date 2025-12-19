import 'package:flutter/material.dart';
import 'home_screen.dart';        // 登録済みならこっちへ
import 'screen_information.dart'; // 未登録ならこっちへ

class ScreenStart extends StatelessWidget {
  // ★ main.dart から受け取るための変数
  final bool isRegistered;

  const ScreenStart({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        // 画面全体どこをタップしても次へ進む
        onTap: () {
          // 登録済みならホーム画面へ、未登録なら情報入力画面へ
          if (isRegistered) {
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
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ロゴやイラストがあればここに配置
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
              // 点滅する文字のアニメーションなどを入れてもOK
              const Text(
                '画面をタッチしてはじめる',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}