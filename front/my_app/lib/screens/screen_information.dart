import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/screens/screen_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenInformation extends StatefulWidget {
  const ScreenInformation({super.key});

  @override
  State<ScreenInformation> createState() => _ScreenInformationState();
}

class _ScreenInformationState extends State<ScreenInformation> {
  // コントローラーと変数の定義
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthplaceController = TextEditingController();
  final TextEditingController _triviaController = TextEditingController();
  final TextEditingController _heeCountController = TextEditingController();

  DateTime? _selectedDate;
  File? _profileImage;
  File? _triviaAiImage;

  final ImagePicker _picker = ImagePicker();

  // 画像選択の処理
  Future<void> _pickImage(bool isProfile) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _triviaAiImage = File(pickedFile.path);
        }
      });
    }
  }

  // 日付選択の処理
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 登録完了ボタンの処理
  Future<void> _onComplete() async {
    // ここにFirebaseへの保存処理などを記述します

    // 登録完了したことをスマホに保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRegistered', true);
    await prefs.setString('nickname', _nicknameController.text);

    // 次の画面へ移動して戻れないようにする
    if (!mounted) return; // 画面が存在するか確認
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ScreenProfile()), // 遷移先
    );

    print("ニックネーム: ${_nicknameController.text}");
    print("誕生日: $_selectedDate");
    print("出身: ${_birthplaceController.text}");
    print("トリビア: ${_triviaController.text}");
    print("へぇ数: ${_heeCountController.text}");
    // 次の画面へ遷移など
  }

  @override
  Widget build(BuildContext context) {
    // 画面全体の高さを取得してレイアウト調整に使用
    return Scaffold(
      // キーボード表示時にレイアウトが崩れないようにリサイズを防止するか、
      // 実際にはSingleChildScrollViewでラップするのが一般的ですが、
      // 今回は「スクロールなし」の要望に合わせて画面いっぱいに配置します。
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(title: const Text('ユーザー情報登録')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ------------------------
              // 1. 上部: ニックネーム
              // ------------------------
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'ニックネーム',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),

              // ------------------------
              // 2. 中央エリア (左右分割)
              // ------------------------
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === 左カラム (画像エリア) ===
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // プロフィール画像
                          Expanded(
                            child: _buildImageBox(
                              label: 'プロフィール\n画像',
                              imageFile: _profileImage,
                              onTap: () => _pickImage(true),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // トリビアAI画像
                          Expanded(
                            child: _buildImageBox(
                              label: 'トリビア\nAI画像',
                              imageFile: _triviaAiImage,
                              onTap: () => _pickImage(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // === 右カラム (詳細情報エリア) ===
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          // 生年月日
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '生年月日',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? '選択してください'
                                    : DateFormat('yyyy年MM月dd日').format(_selectedDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 出身都道府県
                          TextField(
                            controller: _birthplaceController,
                            decoration: const InputDecoration(
                              labelText: '出身都道府県',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // トリビアとへぇ数 (横並び)
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // トリビア入力エリア
                                Expanded(
                                  flex: 7,
                                  child: TextField(
                                    controller: _triviaController,
                                    maxLines: null, // 複数行入力可
                                    expands: true, // 親の高さに合わせて広げる
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: const InputDecoration(
                                      labelText: 'トリビア',
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // へぇ数エリア
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _heeCountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          expands: true,
                                          maxLines: null,
                                          textAlignVertical: TextAlignVertical.top,
                                          decoration: const InputDecoration(
                                            labelText: 'へぇ数',
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------
              // 3. 下部: 完了ボタン
              // ------------------------
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // ボタンの色
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '完　了',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 画像選択ボックスの共通ウィジェット
  Widget _buildImageBox({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}