import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 実際のファイル名に合わせてimportしてください
import 'screens/home_screen.dart'; 
import 'screens/screen_birthday.dart'; // ← ここ重要！先ほど作った screen_3.dart を読み込む

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Flutter Template',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ■ ここが修正ポイント：最初に表示する画面
      home: const HomeScreen(),
      
      // ■ ここが修正ポイント：画面遷移の登録表 (ルーティング)
      routes: {
        '/home': (context) => const HomeScreen(),
        '/birthday': (context) => const ScreenBirthday(), // 誕生日画面
        
        // まだ作っていない画面は、一旦「仮の画面」を表示させるようにしています
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