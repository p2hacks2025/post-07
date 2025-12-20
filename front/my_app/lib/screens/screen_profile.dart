import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart'; // 紙吹雪パッケージ
import '../widgets/shining_card.dart';
import '../widgets/interactive_card.dart';
import 'dart:convert';
import 'dart:math'; 
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../models/encounter.dart';

class ScreenProfile extends StatefulWidget {
  const ScreenProfile({super.key});

  @override
  State<ScreenProfile> createState() => _ScreenProfileState();
}

class _ScreenProfileState extends State<ScreenProfile> {
  // --- 各種コントローラー ---
  final _nicknameController = TextEditingController();
  final _triviaController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _hehController = TextEditingController(text: '0');
  
  // 紙吹雪用のコントローラー
  late ConfettiController _confettiController;

  final ProfileService _profileService = ProfileService();

  int _totalHehReceived = 0; 
  File? _profileImage;
  File? _triviaAiImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 紙吹雪の再生時間を2秒に設定
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    _loadMyProfileData();
    
    // へぇ数の入力に合わせてリアルタイムでカードの色を更新
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
    _confettiController.dispose(); // メモリ解放
    super.dispose();
  }

  // --- データの読み込み ---
  Future<void> _loadMyProfileData() async {
    final myProfile = await _profileService.loadMyProfile();
    if (myProfile != null) {
      setState(() {
        _nicknameController.text = myProfile.nickname;
        _birthdayController.text = myProfile.birthday;
        _birthplaceController.text = myProfile.birthplace;
        _triviaController.text = myProfile.trivia;
        _totalHehReceived = myProfile.totalHeh;
        _hehController.text = _totalHehReceived.toString();
      });
    }
  }

  // --- ランクに応じたカードの背景デザイン（6段階） ---
  BoxDecoration _getCardDecoration(int heh, bool isPreview) {
    List<Color> colors = [Colors.white, Colors.white];
    
    if (heh >= 300) {
      // 【虹】
      colors = [const Color(0xFFFFE0F0), const Color(0xFFE0F0FF), const Color(0xFFF0FFE0), const Color(0xFFFFE0F0)];
    } else if (heh >= 200) {
      // 【ゴールド】
      colors = [const Color(0xFFFFD700), const Color(0xFFFFF8E1), const Color(0xFFD4AF37)];
    } else if (heh >= 100) {
      // 【プラチナ】
      colors = [const Color(0xFFE5E4E2), const Color(0xFFF8FBFF), const Color(0xFFA1B2C3)];
    } else if (heh >= 50) {
      // 【シルバー】
      colors = [const Color(0xFFC0C0C0), const Color(0xFFF5F5F5), const Color(0xFFB0B0B0)];
    } else if (heh >= 20) {
      // 【ブロンズ】
      colors = [const Color(0xFFCD7F32), const Color(0xFFFFE0B2), const Color(0xFF8D6E63)];
    }

    return BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      border: Border.all(color: Colors.black, width: isPreview ? 5.0 : 4.0),
      borderRadius: BorderRadius.circular(16),
      boxShadow: isPreview ? [const BoxShadow(color: Colors.black45, blurRadius: 25, offset: Offset(0, 12))] : [],
    );
  }

  // --- プレビュー表示のダイアログ ---
  void _showCardPreview() {
    // ブロンズ（20へぇ）以上なら紙吹雪を鳴らす
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
                          xAngle: xAngle,
                          yAngle: yAngle,
                          child: _buildCardBase(isPreview: true),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // 紙吹雪をダイアログの最前面に配置
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

  // --- カード本体のUI ---
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
                          Expanded(child: _buildPhotoBox(label: '写真', icon: Icons.person, file: _profileImage, onTap: isPreview ? null : () => _pickImage(true))),
                          const SizedBox(height: 4),
                          Expanded(child: _buildPhotoBox(label: 'AI画像', icon: Icons.smart_toy, file: _triviaAiImage, onTap: isPreview ? null : () => _pickImage(false))),
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

  // --- 各パーツのウィジェット群 ---
  Widget _buildNicknameField() {
    return SizedBox(
      height: 35,
      child: TextFormField(
        controller: _nicknameController,
        decoration: const InputDecoration(labelText: 'ニックネーム', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isPreview, VoidCallback? onTap) {
    if (isPreview) {
      return Text('$label: ${value.isEmpty ? "未入力" : value}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
    }
    return SizedBox(
      height: 32,
      child: TextFormField(
        controller: TextEditingController(text: value),
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8), suffixIcon: const Icon(Icons.arrow_drop_down, size: 16)),
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
              ? Text('トリビア: ${_triviaController.text}', style: const TextStyle(fontSize: 9), maxLines: 3, overflow: TextOverflow.ellipsis)
              : TextField(
                  controller: _triviaController,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: 'トリビア', border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontSize: 10),
                ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.blue[50], border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(4)),
          child: isPreview 
            ? Text('$_totalHehReceived', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))
            : TextField(
                controller: _hehController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              ),
        ),
      ],
    );
  }

  // --- 写真関連 ---
  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (isProfile) _profileImage = File(pickedFile.path);
          else _triviaAiImage = File(pickedFile.path);
        });
      }
    } catch (e) { debugPrint('画像選択エラー: $e'); }
  }

  Widget _buildPhotoBox({required String label, required IconData icon, required File? file, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
        child: file != null ? ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.file(file, fit: BoxFit.cover)) : Icon(icon, color: Colors.grey, size: 18),
      ),
    );
  }

  // --- 各種選択ピッカー ---
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

  // --- 保存処理 ---
  Future<void> _saveProfile() async {
    try {
      final url = Uri.parse('https://cylinderlike-dana-cryoscopic.ngrok-free.dev/save_profile');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'birthday': _birthdayController.text,
          'birthplace': _birthplaceController.text,
          'trivia': _triviaController.text,
          'total_heh': int.tryParse(_hehController.text) ?? 0,
        }),
      );
      if (response.statusCode == 200) {
        final profile = Profile(
          profileId: _profileService.generateProfileId(),
          nickname: _nicknameController.text, birthday: _birthdayController.text,
          birthplace: _birthplaceController.text, trivia: _triviaController.text,
          totalHeh: int.tryParse(_hehController.text) ?? 0,
        );
        await _profileService.saveMyProfile(profile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
    }
  }

  // --- 全体のビルド ---
  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.68;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('プロフィール編集', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
          toolbarHeight: 50,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 編集中のカード（色が変わる！）
              SizedBox(width: cardWidth, child: _buildCardBase(isPreview: false)),
              const SizedBox(width: 10),
              // 右側のボタン
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSideButton(label: 'カードを見る', icon: Icons.visibility, onPressed: _showCardPreview, color: Colors.blue),
                  const SizedBox(height: 8),
                  _buildSideButton(label: '登録', icon: Icons.check, onPressed: _saveProfile, color: Colors.green),
                  const SizedBox(height: 8),
                  _buildSideButton(label: '戻る', icon: Icons.arrow_back, onPressed: () => Navigator.pop(context), color: Colors.grey, isOutlined: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton({required String label, required IconData icon, required VoidCallback onPressed, required Color color, bool isOutlined = false}) {
    return SizedBox(
      width: 80, height: 55,
      child: isOutlined
          ? OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: BorderSide(color: color)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: color), Text(label, style: TextStyle(fontSize: 9, color: color))]))
          : ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: color),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: Colors.white), Text(label, style: const TextStyle(fontSize: 9, color: Colors.white))])),
    );
  }
}