import 'dart:convert'; // JSON解析用に追加
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class ScreenInformation extends StatefulWidget {
  final Map<String, dynamic> profileJson;

  const ScreenInformation({
    super.key,
    required this.profileJson,
  });

  @override
  State<ScreenInformation> createState() => _ScreenInformationState();
}


class _ScreenInformationState extends State<ScreenInformation> {

  final _nicknameController = TextEditingController();
  final _triviaController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _heeController = TextEditingController();

  final FocusNode _triviaFocusNode = FocusNode();

  File? _profileImage;
  String? _resultImageUrl; // AI生成された画像のURLを保存する変数
  bool _isLoading = false;   // 生成中かどうかを判定するフラグ

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _heeController.text = "0";

  debugPrint("ScreenInformation 받은 profileJson: ${widget.profileJson}");
  debugPrint("UID in ScreenInformation: ${widget.profileJson['uid']}");
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

  // --- 画像選択 (プロフィール用のみ) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
    }
  }

  // --- 日付・都道府県選択 (変更なし) ---
  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    int tempMonth = 1;
    int tempDay = 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              _buildPickerToolbar(
                onDone: () {
                  setState(() {
                    _birthdayController.text = '$tempMonth月$tempDay日';
                  });
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWheel(12, (i) => tempMonth = i + 1, '月'),
                    const SizedBox(width: 20),
                    _buildWheel(31, (i) => tempDay = i + 1, '日'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectPrefecture() async {
    FocusScope.of(context).unfocus();
    final prefectures = [
      '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
      '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
      '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
      '岐阜県', '静岡県', '愛知県', '三重県',
      '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
      '鳥取県', '島根県', '岡山県', '広島県', '山口県',
      '徳島県', '香川県', '愛媛県', '高知県',
      '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
    ];
    int tempIndex = 0;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              _buildPickerToolbar(
                onDone: () {
                  setState(() => _birthplaceController.text = prefectures[tempIndex]);
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) => tempIndex = i,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (c, i) => Center(
                        child: Text(prefectures[i], style: const TextStyle(fontSize: 18))),
                    childCount: prefectures.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- サーバー送信処理 (★ここが移植ポイント) ---
  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty || _triviaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームとトリビアを入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('https://saliently-multiciliated-jacqui.ngrok-free.dev/save_profile');
      var request = http.MultipartRequest('POST', uri);

      // テキストデータのセット
      // request.fields['nickname'] = _nicknameController.text;
      // request.fields['birthday'] = _birthdayController.text;
      // request.fields['birthplace'] = _birthplaceController.text;
      // request.fields['trivia'] = _triviaController.text;
      // request.fields['hey'] = int.tryParse_heeController.text;
      // request.fields['hey'] = int.Try_heeController.text;
      // request.fields['id'] = widget.profileJson['uid'].toString();
      // request.fields['ver'] = "1";

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'birthday': _birthdayController.text,
          'birthplace': _birthplaceController.text,
          'trivia': _triviaController.text,
          'hey': int.tryParse(_heeController.text) ?? 0,
          'id': widget.profileJson['uid'],
          'ver':0
        }),
      );



      // 画像ファイルのセット (プロフィール画像のみ)
      // if (_profileImage != null) {
      //   request.files.add(await http.MultipartFile.fromPath(
      //     'profile_image',
      //     _profileImage!.path,
      //   ));
      // }

     

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Discord共有コードのレスポンス構造 data['data']['card_image_url'] に合わせる
        final imageUrl = data['image_url'];

        setState(() {
          _resultImageUrl = imageUrl;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI画像生成完了！')),
        );

        // 少し待ってからホーム画面へ
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
       Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            profileJson: widget.profileJson,
          ),
        ),
      );
      } else {
        throw Exception('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('通信エラー詳細: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通信に失敗しました')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  

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
        resizeToAvoidBottomInset: true,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 8.0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nicknameController,
                              onChanged: (value) => setState(() {}),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'ニックネーム',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  // --- 左側：画像枠エリア ---
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _buildPhotoBox(
                                            label: 'プロフィール写真',
                                            icon: Icons.person,
                                            file: _profileImage,
                                            onTap: () => _pickImage(),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: _buildAiImageArea(), // AI画像表示用
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // --- 右側：入力エリア ---
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      children: [
                                        _buildSelectionField(
                                          controller: _birthdayController,
                                          label: '誕生日',
                                          onTap: _selectDate,
                                        ),
                                        const SizedBox(height: 4),
                                        _buildSelectionField(
                                          controller: _birthplaceController,
                                          label: '出身地',
                                          onTap: _selectPrefecture,
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 7,
                                                child: _buildTriviaInput(),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildHeeCounter(),
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
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 登録ボタン
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 小分けにした部品ウィジェット ---

  Widget _buildPhotoBox({required String label, required IconData icon, File? file, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(6),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.grey, size: 24),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
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
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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

  Widget _buildHeeCounter() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_heeController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Text('へぇ', style: TextStyle(fontSize: 10, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 100,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('登録', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // (共通部品) 日付ホイールなど
  Widget _buildPickerToolbar({required VoidCallback onDone}) {
    return Container(
      color: Colors.grey[100], height: 50, padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        TextButton(onPressed: onDone, child: const Text('完了', style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildWheel(int count, Function(int) onChanged, String unit) {
    return Row(children: [
      SizedBox(width: 70, child: ListWheelScrollView.useDelegate(
        itemExtent: 40, physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (c, i) => Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 20))),
          childCount: count,
        ),
      )),
      Text(unit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSelectionField({required TextEditingController controller, required String label, required VoidCallback onTap}) {
    return TextFormField(
      controller: controller, readOnly: true, onTap: onTap,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(fontSize: 11),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
      ),
    );
  }
}