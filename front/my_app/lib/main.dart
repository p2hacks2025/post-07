import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ▼ 実際のファイル構成に合わせてimportを確認してください
import 'screens/screen_birthday.dart'; 
import 'screens/screen_start.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 画面を横向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // アプリ起動時に「登録済みかどうか」のチェックを行います
  final prefs = await SharedPreferences.getInstance();
  final bool isRegistered = prefs.getBool('isRegistered') ?? false;

  // ■ ユーザ固有IDを取得 or 初回生成
  String? userId = prefs.getString('user_id');
  int ver = prefs.getInt('ver') ?? 0;

  if (userId == null) {
    userId = const Uuid().v4();
    ver = 0;
    await prefs.setString('user_id', userId);
    await prefs.setInt('ver', ver);
  }
  print("User ID: $userId"); // デバッグ用
  print(ver);
  
  final Map<String, dynamic> baseProfileJson = {
     "uid": userId,
    "ver": ver, // ← これ
  };

  // 結果をMyAppに渡してアプリを起動します
  runApp(MyApp(isRegistered: isRegistered, profileJson: baseProfileJson,));
}

class MyApp extends StatelessWidget {
  final bool isRegistered;
  final Map<String, dynamic> profileJson;

  const MyApp({
    super.key, 
    required this.isRegistered, 
    required this.profileJson,
  });

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green).copyWith(secondary: Colors.yellow),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
      ),
      
      // ★★★ ここを修正しました ★★★
      // いきなり分岐せず、まずはスタート画面を表示します
      home: ScreenStart(isRegistered: isRegistered,profileJson: profileJson,),
      
      // ルーティング設定
      routes: {
        // '/home': (context) => const HomeScreen(),
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