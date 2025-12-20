import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TriviaInputScreen extends StatefulWidget {
  const TriviaInputScreen({super.key});

  @override
  State<TriviaInputScreen> createState() => _TriviaInputScreenState();
}

class _TriviaInputScreenState extends State<TriviaInputScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _triviaController = TextEditingController();
  
  String? _resultImageUrl;
  bool _isLoading = false;

  

  Future<void> _submitProfile() async {
    debugPrint("★ボタンが押されました！処理を開始します！"); // ←これを追加
    // ★ここを今のngrokのURLに書き換えてください！
    // 例: 'https://xxxx-xxxx.ngrok-free.app/save_profile'
    final String url = 'https://cylinderlike-dana-cryoscopic.ngrok-free.dev/save_profile'; 

    setState(() {
      _isLoading = true;
      _resultImageUrl = null;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nickname": _nicknameController.text,
          "birthday": "2000-01-01", 
          "birthplace": "Hakodate", 
          "trivia": _triviaController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // サーバーからのレスポンス構造に合わせてURLを取り出す
        // apiResponse.pyでは { "data": { "card_image_url": "..." } } と返しているため
        final imageUrl = data['data']['card_image_url'];

        setState(() {
          _resultImageUrl = imageUrl;
        });
      } else {
        debugPrint("エラー: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("通信エラー: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('トリビア送信テスト')),
      body: Row( // 横画面設定になっていたのでRowで見やすく調整
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: 'ニックネーム'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _triviaController,
                    decoration: const InputDecoration(labelText: 'トリビア'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
                    child: _isLoading 
                        ? const CircularProgressIndicator() 
                        : const Text('カード生成'),
                  ),
                ],
              ),
            ),
          ),
          // 右半分に画像を表示
          Expanded(
            child: Center(
              child: _resultImageUrl != null
                  ? Image.network(_resultImageUrl!)
                  : const Text("ここにカードが表示されます"),
            ),
          ),
        ],
      ),
    );
  }
}