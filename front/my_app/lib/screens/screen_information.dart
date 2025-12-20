import 'dart:convert';
import 'dart:io';
import 'dart:math'; // 追加: min関数などで使用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart'; // 紙吹雪パッケージ

// 必要なウィジェット（screen_profile.dartと同じものを使用）
import '../widgets/shining_card.dart';
import '../widgets/interactive_card.dart';

import 'home_screen.dart';

class ScreenInformation extends StatefulWidget {
  final Map<String, dynamic>? profileJson;

  const ScreenInformation({super.key, this.profileJson});

  @override
  State<ScreenInformation> createState() => _ScreenInformationState();
}

class _ScreenInformationState extends State<ScreenInformation> {
  // --- 各種コントローラー ---
  final _nicknameController = TextEditingController();
  final _triviaController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _hehController = TextEditingController(text: '0');

  // 紙吹雪用
  late ConfettiController _confettiController;

  File? _profileImage;      // プロフィール写真（ローカル）
  File? _triviaAiImage;     // AI画像（ローカル手動選択）
  String? _triviaAiImageUrl; // AI画像（サーバーURL）

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int _totalHehReceived = 0; // プレビュー用

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // プロフィールJSONがあれば反映（AI画像URLなど）
    if (widget.profileJson != null && widget.profileJson!.isNotEmpty) {
       final uid = widget.profileJson!['uid'];
       // 既存の値があればセット
       _nicknameController.text = widget.profileJson!['nickname'] ?? '';
       _birthdayController.text = widget.profileJson!['birthday'] ?? '';
       _birthplaceController.text = widget.profileJson!['birthplace'] ?? '';
       _triviaController.text = widget.profileJson!['trivia'] ?? '';
       
       if (uid != null) {
         _loadProfileIfExists(uid);
       }
    }
    
    // へぇ数のリスナー（登録画面では通常0スタートですが、念のため）
    _hehController.addListener(() {
      if (mounted) {
        setState(() {
          _totalHehReceived = int.tryParse(_hehController.text) ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _triviaController.dispose();
    _birthdayController.dispose();
    _birthplaceController.dispose();
    _hehController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // -------------------------------
  // サーバーからAI画像URL等を取得
  // -------------------------------
  Future<void> _loadProfileIfExists(String uid) async {
    try {
      final url = Uri.parse(
          'https://saliently-multiciliated-jacqui.ngrok-free.dev/get_user_profile');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'id': uid,
          'ver': 0,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data == null) return;

        setState(() {
          if (data['ai_image_url'] != null) {
            _triviaAiImageUrl = data['ai_image_url'];
          }
          // 既存データがあれば上書き（必要に応じて）
          // _nicknameController.text = data['nickname'] ?? _nicknameController.text;
        });
        debugPrint('AI画像URL取得: $_triviaAiImageUrl');
      }
    } catch (e) {
      debugPrint('プロフィール取得エラー: $e');
    }
  }

  // -------------------------------
  // デバッグ用 AI画像シミュレーション
  // -------------------------------
  void _debugSimulateAiImageFetch() {
    setState(() {
      _triviaAiImageUrl = 'https://picsum.photos/seed/trivia/200/200';
      _triviaAiImage = null; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('デバッグ: AI画像URLを取得しました')),
    );
  }

  // -------------------------------
  // 画像選択
  // -------------------------------
  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _triviaAiImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
    }
  }

  // -------------------------------
  // プロフィール保存処理
  // -------------------------------
  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty || _triviaController.text.isEmpty) {
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
      request.fields['id'] = widget.profileJson?['uid'] ?? 'sample_user_id'; 
      request.fields['ver'] = '1';
      request.fields['hey'] = _hehController.text;
      request.fields['date'] = DateTime.now().toIso8601String();

      // --- 画像 (プロフィール写真) ---
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // API側のキー
            _profileImage!.path,
          ),
        );
      }
      
      // 必要であればAI画像ファイルも送信する処理をここに追加

      final response = await request.send();
      final result = await http.Response.fromStream(response);

      if (result.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録完了！')),
        );
        if (!mounted) return;
        
        final profileJson = {
          'uid': widget.profileJson?['uid'] ?? 'sample_user_id',
          'nickname': _nicknameController.text,
          'birthday': _birthdayController.text,
          'birthplace': _birthplaceController.text,
          'trivia': _triviaController.text,
          'ver': 1,
          'ai_image_url': _triviaAiImageUrl,
        };
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(profileJson: profileJson)),
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
  // UI構築用メソッド群（screen_profile.dartから移植）
  // -------------------------------
  
  BoxDecoration _getCardDecoration(int heh, bool isPreview) {
    List<Color> colors = [Colors.white, Colors.white];
    if (heh >= 300) {
      colors = [const Color(0xFFFFE0F0), const Color(0xFFE0F0FF), const Color(0xFFF0FFE0), const Color(0xFFFFE0F0)];
    } else if (heh >= 200) {
      colors = [const Color(0xFFFFD700), const Color(0xFFFFF8E1), const Color(0xFFD4AF37)];
    } else if (heh >= 100) {
      colors = [const Color(0xFFE5E4E2), const Color(0xFFF8FBFF), const Color(0xFFA1B2C3)];
    } else if (heh >= 50) {
      colors = [const Color(0xFFC0C0C0), const Color(0xFFF5F5F5), const Color(0xFFB0B0B0)];
    } else if (heh >= 20) {
      colors = [const Color(0xFFCD7F32), const Color(0xFFFFE0B2), const Color(0xFF8D6E63)];
    }

    return BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      border: Border.all(color: Colors.black, width: isPreview ? 5.0 : 4.0),
      borderRadius: BorderRadius.circular(16),
      boxShadow: isPreview ? [const BoxShadow(color: Colors.black45, blurRadius: 25, offset: Offset(0, 12))] : [],
    );
  }

  void _showCardPreview() {
    if (_totalHehReceived >= 20) {
      _confettiController.play();
    }
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    double maxAvailableHeight = screenHeight * 0.8;
    double previewWidth = min(screenWidth * 0.9, maxAvailableHeight * 1.58);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: double.infinity,
                  alignment: Alignment.center,
                  color: Colors.black.withOpacity(0.6),
                  child: SizedBox(
                    width: previewWidth,
                    child: InteractiveCard(
                      builder: (context, xAngle, yAngle) {
                        return ShiningCard(
                          hehCount: _totalHehReceived,
                          xAngle: xAngle, yAngle: yAngle,
                          child: _buildCardBase(isPreview: true),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
                numberOfParticles: 30,
                gravity: 0.1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardBase({required bool isPreview}) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        decoration: _getCardDecoration(_totalHehReceived, isPreview),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isPreview
                  ? Text(_nicknameController.text.isEmpty ? 'ニックネーム' : _nicknameController.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                  : _buildNicknameField(),
              const Divider(color: Colors.black, thickness: 2, height: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Expanded(
                              child: _buildPhotoBox(
                                  label: '写真', icon: Icons.person,
                                  file: _profileImage, imageUrl: null,
                                  onTap: isPreview ? null : () => _pickImage(true))),
                          const SizedBox(height: 4),
                          Expanded(
                              child: _buildPhotoBox(
                                  label: 'AI画像', icon: Icons.smart_toy,
                                  file: _triviaAiImage, imageUrl: _triviaAiImageUrl,
                                  onTap: isPreview ? null : () => _pickImage(false))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem('誕生日', _birthdayController.text, isPreview, _selectDate),
                          _buildInfoItem('出身地', _birthplaceController.text, isPreview, _selectPrefecture),
                          Expanded(child: _buildTriviaAndHeh(isPreview)),
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
    );
  }

  Widget _buildNicknameField() {
    return SizedBox(
      height: 35,
      child: TextFormField(
        controller: _nicknameController,
        decoration: const InputDecoration(
            labelText: 'ニックネーム', isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isPreview, VoidCallback? onTap) {
    if (isPreview) {
      return Text('$label: ${value.isEmpty ? "未入力" : value}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
    }
    return SizedBox(
      height: 32,
      child: TextFormField(
        controller: TextEditingController(text: value),
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
            labelText: label, isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 16)),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildTriviaAndHeh(bool isPreview) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.all(4),
            child: isPreview
                ? Text('トリビア: ${_triviaController.text}',
                    style: const TextStyle(fontSize: 9), maxLines: 3, overflow: TextOverflow.ellipsis)
                : TextField(
                    controller: _triviaController, maxLines: null,
                    decoration: const InputDecoration(hintText: 'トリビア', border: InputBorder.none, isDense: true),
                    style: const TextStyle(fontSize: 10),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(4)),
          child: isPreview
              ? Text('$_totalHehReceived',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))
              : TextField(
                  controller: _hehController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
        ),
      ],
    );
  }

  Widget _buildPhotoBox({
    required String label, required IconData icon,
    required File? file, required String? imageUrl,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _buildImageContent(file, imageUrl, icon),
        ),
      ),
    );
  }

  Widget _buildImageContent(File? file, String? imageUrl, IconData icon) {
    if (file != null) {
      return Image.file(file, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, size: 18)),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    } else {
      return Icon(icon, color: Colors.grey, size: 18);
    }
  }

  // --- ピッカー類 ---
  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    int tempMonth = 1; int tempDay = 1;
    await showModalBottomSheet(context: context, builder: (BuildContext context) {
      return Container(height: 250, color: Colors.white, child: Column(children: [
        _buildPickerToolbar(onDone: () { setState(() => _birthdayController.text = '$tempMonth月$tempDay日'); Navigator.pop(context); }),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildWheel(12, (i) => tempMonth = i + 1, '月'), const SizedBox(width: 20), _buildWheel(31, (i) => tempDay = i + 1, '日'),
        ])),
      ]));
    });
  }

  Future<void> _selectPrefecture() async {
    FocusScope.of(context).unfocus();
    final prefectures = ['北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県', '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県', '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県', '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県', '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'];
    int tempIndex = 0;
    await showModalBottomSheet(context: context, builder: (context) {
      return Container(height: 250, color: Colors.white, child: Column(children: [
        _buildPickerToolbar(onDone: () { setState(() => _birthplaceController.text = prefectures[tempIndex]); Navigator.pop(context); }),
        Expanded(child: ListWheelScrollView.useDelegate(
          itemExtent: 40, physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) => tempIndex = i,
          childDelegate: ListWheelChildBuilderDelegate(builder: (c, i) => Center(child: Text(prefectures[i], style: const TextStyle(fontSize: 18))), childCount: prefectures.length),
        )),
      ]));
    });
  }

  Widget _buildPickerToolbar({required VoidCallback onDone}) {
    return Container(height: 50, color: Colors.grey[100], padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        TextButton(onPressed: onDone, child: const Text('完了', style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildWheel(int count, Function(int) onChanged, String unit) {
    return Row(children: [
      SizedBox(width: 60, child: ListWheelScrollView.useDelegate(
        itemExtent: 40, physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(builder: (c, i) => Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 20))), childCount: count),
      )),
      Text(unit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.68;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('プロフィール作成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, toolbarHeight: 50,
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'デバッグ: AI画像取得',
              onPressed: _debugSimulateAiImageFetch,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カード部分
                SizedBox(width: cardWidth, child: _buildCardBase(isPreview: false)),
                const SizedBox(width: 10),
                // ボタン部分
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildSideButton(label: 'カードを見る', icon: Icons.visibility, onPressed: _showCardPreview, color: Colors.blue),
                    const SizedBox(height: 8),
                    _buildSideButton(label: '登録する', icon: Icons.check, onPressed: _saveProfile, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton({required String label, required IconData icon, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      width: 80, height: 55,
      child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: color),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: Colors.white), Text(label, style: const TextStyle(fontSize: 9, color: Colors.white))])),
    );
  }
}