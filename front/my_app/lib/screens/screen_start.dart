import 'package:flutter/material.dart';
import 'package:my_app/screens/screen_information.dart';
import 'home_screen.dart';

class ScreenStart extends StatefulWidget {
  final bool isRegistered;
  final Map<String, dynamic> profileJson;

  const ScreenStart({
    super.key,
    required this.isRegistered,
    required this.profileJson,
  });

  @override
  State<ScreenStart> createState() => _ScreenStartState();
}

class _ScreenStartState extends State<ScreenStart> {
  double _flashOpacity = 0.0;

  Future<void> _handleStart() async {
    setState(() {
      _flashOpacity = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

<<<<<<< HEAD
=======
     // 🔍 デバッグ：idだけのJSON確認
    debugPrint("現在の profileJson:");
    debugPrint(widget.profileJson.toString());
    
    // 3. 次の画面へ遷移
>>>>>>> 3233e9f033a54eb33c325c25ae3dac47152fd372
    if (widget.isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(profileJson: widget.profileJson)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ScreenInformation(profileJson: widget.profileJson)),
      );
    }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF9787EA);

    return Scaffold(
      backgroundColor: themeColor,
      body: GestureDetector(
        onTap: _handleStart,
        child: Stack(
          children: [
            Column(
              children: [
                // 1. 上側の余白
                const SizedBox(height: 60),

                // 2. 画像エリア
                Expanded(
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center, 
                    child: Transform.scale(
                      scale: 0.8, // ★ 1.2 から 1.1 に少し小さくしました
                      child: Image.asset(
                        'assets/images/title_bg.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth, 
                      ),
                    ),
                  ),
                ),

                // 3. 下側の文字エリア
                Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'TAP TO START',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '画面をタッチしてはじめる',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- 発光エフェクト ---
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOpacity,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}