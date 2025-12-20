import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'screens/home_screen.dart'; 
import 'screens/screen_birthday.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 画面を横向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // デバッグ帯を消す
      title: 'Flutter Template',
      
      // 日本語入力対応
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語を設定
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      
      // HomeScreenを最初の画面に設定
      home: const HomeScreen(),
      
      // ルーティング設定
      routes: {
        '/home': (context) => const HomeScreen(),
        '/birthday': (context) => const ScreenBirthday(),
        // まだ作っていない画面の仮置き
        '/profile': (context) => const PlaceholderScreen(title: 'マイプロフィール'),
        '/map': (context) => const PlaceholderScreen(title: '出身地埋め'),
        '/square': (context) => const PlaceholderScreen(title: '広場'),
        '/trophy': (context) => const PlaceholderScreen(title: 'トロフィー'),
      },
    );
  }
}

// ■ まだ作っていない画面の代わりに表示する「仮の画面」
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$title 画面はまだありません', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}