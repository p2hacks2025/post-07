import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class ScreenInformation extends StatefulWidget {
  final Map<String, dynamic>? profileJson;
  const ScreenInformation({super.key, this.profileJson});

  @override
  State<ScreenInformation> createState() => _ScreenInformationState();
}

class _ScreenInformationState extends State<ScreenInformation> {
    String? _resultImageUrl;
  final _nicknameController = TextEditingController();
  final _triviaController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _heeController = TextEditingController();

  final FocusNode _triviaFocusNode = FocusNode();

  File? _profileImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _heeController.text = "0";
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _triviaController.dispose();
    _birthdayController.dispose();
    _birthplaceController.dispose();
    _heeController.dispose();
    _triviaFocusNode.dispose();
    super.dispose();
  }

  // -------------------------------
  // 画像選択
  // -------------------------------
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // -------------------------------
  // プロフィール保存（★変更点）
  // -------------------------------
  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty ||
        _triviaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームとトリビアは必須です')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        'https://saliently-multiciliated-jacqui.ngrok-free.dev/save_profile',
      );

      final request = http.MultipartRequest('POST', uri);

      // --- 文字データ ---
      request.fields['nickname'] = _nicknameController.text;
      request.fields['birthday'] = _birthdayController.text;
      request.fields['birthplace'] = _birthplaceController.text;
      request.fields['trivia'] = _triviaController.text;
      request.fields['id'] = 'sample_user_id'; // ← 仮（ログイン後は実ID）
      request.fields['ver'] = '1';
      request.fields['hey'] = _heeController.text;
      request.fields['date'] =
          DateTime.now().toIso8601String(); // ISO形式で送信

      // --- 画像 ---
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // ← API側で受け取るキー名
            _profileImage!.path,
          ),
        );
      }

      final response = await request.send();
      final result = await http.Response.fromStream(response);

      if (result.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィール保存完了')),
        );

        if (!mounted) return;
        
        final profileJson = {
          'nickname': _nicknameController.text,
          'birthday': _birthdayController.text,
          'birthplace': _birthplaceController.text,
          'trivia': _triviaController.text,
          'ver': 1,
        };
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(profileJson:profileJson)),
        );
      } else {
        throw Exception(result.body);
      }
    } catch (e) {
      debugPrint('保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // UI（元コードそのまま）
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    double cardHeight = screenSize.height * 0.9;
    double cardWidth = cardHeight * 1.58;
    if (cardWidth > screenSize.width * 0.95) {
      cardWidth = screenSize.width * 0.95;
      cardHeight = cardWidth / 1.58;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: 'ニックネーム',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    color: Colors.grey[200],
                                    child: _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Center(
                                            child: Icon(Icons.person),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _triviaController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: const InputDecoration(
                                    labelText: 'トリビア',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI画像表示エリア (★タップ無効化済み)
  Widget _buildAiImageArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round())),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // 生成中
            : _resultImageUrl != null
                ? Image.network(_resultImageUrl!, fit: BoxFit.cover) // サーバーからの画像
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
                      Text('AIが画像を生成します', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.blue)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTriviaInput() {
    return GestureDetector(
      onTap: () => _triviaFocusNode.requestFocus(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _triviaController,
          focusNode: _triviaFocusNode,
          onChanged: (value) => setState(() {}),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            labelText: '自分の知ってるトリビアを入力',
            labelStyle: TextStyle(fontSize: 10),
            hintText: '豆知識...',
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}
