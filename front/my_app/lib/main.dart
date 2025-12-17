import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ★追加：日本語対応のために必要です
import 'package:flutter_localizations/flutter_localizations.dart'; 

// ▼ データを読み込むために必要です
import 'package:shared_preferences/shared_preferences.dart';

// 実際のファイル構成に合わせてimportを確認してください
import 'screens/home_screen.dart'; 
import 'screens/screen_information.dart'; 
import 'screens/screen_birthday.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 画面を横向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
   //DeviceOrientation.portraitUp, // 縦固定
  ]);

  // ▼▼▼ ここが追加したロジックです ▼▼▼
  // アプリ起動時に「登録済みかどうか」のチェックを行います
  final prefs = await SharedPreferences.getInstance();
  // 'isRegistered' というデータを探す。なければ false (未登録) になります
  final bool isRegistered = prefs.getBool('isRegistered') ?? false;

  // 結果をMyAppに渡してアプリを起動します
  runApp(MyApp(isRegistered: isRegistered));
}

class MyApp extends StatelessWidget {
  // ▼ 登録済みかどうかを受け取るための変数
  final bool isRegistered;

  const MyApp({
    super.key, 
    required this.isRegistered, // メイン関数から受け取ります
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Template',
      
      // ★★★ ここが日本語入力対応のための追加部分です ★★★
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語を設定
      ],
      // ★★★ ここまで ★★★

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      
      // ▼▼▼ ここが分岐ポイント ▼▼▼
      // 登録済みなら HomeScreen、まだなら ScreenInformation を表示
      home: isRegistered ? const HomeScreen() : const ScreenInformation(),
      
      // ルーティング設定（他の画面への移動用）
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