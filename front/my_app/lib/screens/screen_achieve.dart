import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // JSON読み込み用
import 'dart:convert'; // JSON変換用
import '../services/profile_service.dart'; // データベース操作用
// モデルの場所に合わせてimportを調整してください
import '../models/profile.dart'; 
import '../models/encounter.dart'; 

class ScreenAchieve extends StatefulWidget {
  const ScreenAchieve({super.key});

  @override
  State<ScreenAchieve> createState() => _ScreenAchieveState();
}

class _ScreenAchieveState extends State<ScreenAchieve> {
  // サービス初期化
  final ProfileService _profileService = ProfileService();

  // データを格納する変数（最初は0で初期化）
  int _encounteredCount = 0; 
  int _prefectureCount = 0;    
  int _birthdayCount = 0;      
  int _heeCount = 0;           
  
  bool _isLoading = true; // 読み込み中フラグ

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 画面が開かれたらデータを読み込む
  }

  // ★すべてのデータを読み込む処理
  Future<void> _loadAllData() async {
    try {
      // 1. 履歴データの取得（人数 & 都道府県）
      // ※ getHistory()がEncounterのリストを返すと仮定しています
      final List<Encounter> history = await _profileService.getHistory();
      
      // 人数 = リストの長さ
      final int peopleCount = history.length;

      // 都道府県 = 重複を排除して数える
      // Setを使うと自動的に重複が消えます
      final Set<String> uniquePrefectures = {};
      for (var encounter in history) {
        // Encounterのbirthplaceはprofile内にあるので、profile経由で参照します
        if (encounter.profile.birthplace.isNotEmpty) {
          uniquePrefectures.add(encounter.profile.birthplace);
        }
      }

      // 2. 自分のプロフィールの取得（へぇ数）
      final Profile? myProfile = await _profileService.loadMyProfile();
      final int myHeh = myProfile?.totalHeh ?? 0;

      // 3. 誕生日JSONの読み込み（誕生日数）
      final String jsonString = await rootBundle.loadString('lib/json/birthday.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      // 値が true になっているものだけをカウント
      final int birthdayCollected = jsonMap.values.where((val) => val == true).length;

      // 4. 画面更新
      if (mounted) {
        setState(() {
          _encounteredCount = peopleCount;
          _prefectureCount = uniquePrefectures.length;
          _heeCount = myHeh;
          _birthdayCount = birthdayCollected;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('トロフィー・達成項目', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) // 読み込み中はくるくるを表示
        : Container(
            color: Colors.green.shade600,
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // 達成項目リスト
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // 1. 交換した人数
                      _buildAchieveCard(
                        title: 'プロフィール交換',
                        value: '$_encounteredCount',
                        unit: '人',
                        icon: Icons.people,
                        color: Colors.blue.shade50,
                        progress: _encounteredCount / 100, // 目標100人
                      ),
                      
                      // 2. 集めた都道府県
                      _buildAchieveCard(
                        title: '都道府県コレクション',
                        value: '$_prefectureCount',
                        unit: '/ 47',
                        icon: Icons.map,
                        color: Colors.orange.shade50,
                        progress: _prefectureCount / 47,
                      ),
                      
                      // 3. 集めた誕生日
                      _buildAchieveCard(
                        title: '誕生日コレクション',
                        value: '$_birthdayCount',
                        unit: '種類',
                        icon: Icons.cake,
                        color: Colors.pink.shade50,
                        progress: _birthdayCount / 366, // 366日
                      ),

                      // 4. へぇをもらった数
                      _buildAchieveCard(
                        title: '「へぇ」をもらった数',
                        value: '$_heeCount',
                        unit: '回',
                        icon: Icons.lightbulb_outline, 
                        color: Colors.yellow.shade100, 
                        progress: _heeCount / 500, // 目標500回
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // 達成項目カード
  Widget _buildAchieveCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 130,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 35, color: Colors.black87),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(unit, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress > 1.0 ? 1.0 : progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.green,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}