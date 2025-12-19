import 'package:flutter/material.dart';

class ScreenAchieve extends StatefulWidget {
  const ScreenAchieve({super.key});

  @override
  State<ScreenAchieve> createState() => _ScreenAchieveState();
}

class _ScreenAchieveState extends State<ScreenAchieve> {
  // UI確認用のサンプル数値
  final int _encounteredCount = 12; // 交換した人数
  final int _prefectureCount = 5;    // 集めた都道府県
  final int _birthdayCount = 8;      // 集めた誕生日
  final int _heeCount = 45;          // ★追加：へぇをもらった数

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
      body: Container(
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
                    progress: _encounteredCount / 100,
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
                    progress: _birthdayCount / 31,
                  ),

                  // 4. ★追加：へぇをもらった数
                  _buildAchieveCard(
                    title: '「へぇ」をもらった数',
                    value: '$_heeCount',
                    unit: '回',
                    icon: Icons.lightbulb_outline, // 電球アイコン
                    color: Colors.yellow.shade100, // 黄色系
                    progress: _heeCount / 500, // 500回を目標とする例
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