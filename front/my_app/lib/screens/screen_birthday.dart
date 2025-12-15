import 'package:flutter/material.dart';
import 'dart:math';

class ScreenThree extends StatefulWidget {
  const ScreenThree({super.key});

  @override
  State<ScreenThree> createState() => _ScreenThreeState();
}

class _ScreenThreeState extends State<ScreenThree> {
  // メニューの初期位置（誕生日画面は index: 3）
  int _selectedIndex = 3; 
  late PageController _pageController;
  
  // カレンダーの表示月（初期値は現在の月）
  DateTime _currentMonth = DateTime.now();

  // 獲得した誕生日を保存するセット (形式: "MM-DD")
  final Set<String> _collectedBirthdays = {};

  // メニューデータ
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'route': '/home'},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded, 'route': '/profile'},
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'route': '/map'}, 
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'route': '/birthday'}, // 現在地
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'route': '/square'},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'route': '/trophy'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.2);
  }

  // メニュータップ時の処理
  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeOut
    );

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 3) {
      // 現在の画面
    } else {
      // 地図画面へ戻る場合などの処理が必要ならここに追加
      // 今回は簡易的にスナックバー表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_screens[index]['title']} 画面へ移動します'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // 誕生日すれ違いシミュレーション
  void _simulateStreetPass() {
    final random = Random();
    // ランダムな月(1-12)と日(1-31)を生成
    // ※本来は各月の日数を厳密に計算すべきですが、簡易的に生成して無効な日付は無視などの処理をします
    // ここではDateTimeを使って実在する日付を生成します
    final randomMonth = random.nextInt(12) + 1;
    final randomDay = random.nextInt(31) + 1;
    
    // 日付の妥当性チェック（例: 2月30日などは除外）
    final date = DateTime(2024, randomMonth, randomDay); // 2024年はうるう年なので2/29も出る
    if (date.month != randomMonth) return; // 月が変わっていたら無効な日付（例: 4/31 -> 5/1）なので無視

    final key = "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    setState(() {
      _collectedBirthdays.add(key);
    });

    // カレンダーの表示月を獲得した月にする（演出）
    setState(() {
      _currentMonth = DateTime(2024, randomMonth, 1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cake, color: Colors.white),
            const SizedBox(width: 10),
            Text('${date.month}月${date.day}日の人とすれ違いました！'),
          ],
        ),
        backgroundColor: Colors.pinkAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 月を移動する
  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  // カレンダーの日付セルを作成
  Widget _buildDateCell(int day, int month) {
    if (day == 0) return const SizedBox(); // 空白セル

    final key = "${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    final isCollected = _collectedBirthdays.contains(key);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // 獲得済みならピンクで光らせる
        color: isCollected ? Colors.pink.shade400 : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCollected ? Colors.pinkAccent : Colors.grey.shade300,
          width: isCollected ? 2 : 1
        ),
        boxShadow: isCollected 
          ? [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] 
          : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isCollected) {
               showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('$month月$day日'),
                  content: const Text('この誕生日の人とすれ違いました！\nお祝いしましょう！🎉'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCollected ? Colors.white : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // カレンダー計算
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    // 日曜日始まりにするためのオフセット調整 (DateTimeのweekdayは 月=1 ... 日=7)
    // カレンダーの左上(日曜)を0とするため、日曜(7)なら0、月曜(1)なら1...とする
    final offset = (firstWeekday == 7) ? 0 : firstWeekday;

    final totalSlots = daysInMonth + offset;

    return Scaffold(
      backgroundColor: Colors.pink.shade50, // 背景は薄いピンク
      
      // デザインを統一したAppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.pink.shade400, // テーマカラー
        centerTitle: true,
        toolbarHeight: 40,
        title: Transform.translate(
          offset: const Offset(0, -5),
          child: const Text('誕生日図鑑', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        actions: [
           Center(
             child: Padding(
               padding: const EdgeInsets.only(right: 16.0),
               child: Transform.translate(
                 offset: const Offset(0, -5),
                 child: Text('${_collectedBirthdays.length} / 366', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
             ),
           )
        ],
      ),

      body: Stack(
        children: [
          // ===================================================
          // 1. メインコンテンツ（カレンダー）
          // ===================================================
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 月切り替えバー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.pink),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        '${_currentMonth.month}月',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink.shade800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.pink),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                // 曜日ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['日', '月', '火', '水', '木', '金', '土'].map((day) => 
                      SizedBox(
                        width: 40,
                        child: Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
                      )
                    ).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // カレンダーグリッド
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, // 1週間は7日
                        childAspectRatio: 1.0, // 正方形
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: totalSlots,
                      itemBuilder: (context, index) {
                        // オフセットより前は空白
                        if (index < offset) {
                          return _buildDateCell(0, _currentMonth.month);
                        }
                        // 日付を表示
                        final day = index - offset + 1;
                        return _buildDateCell(day, _currentMonth.month);
                      },
                    ),
                  ),
                ),
                
                // 下のメニューとかぶらないように余白
                const SizedBox(height: 120), 
              ],
            ),
          ),

          // ===================================================
          // 2. 下部メニューバー
          // ===================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withOpacity(0.9), // カレンダーが見やすいように白ベースのグラデ
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                   setState(() {
                     _selectedIndex = index;
                   });
                },
                itemBuilder: (context, index) {
                  final bool isSelected = index == _selectedIndex;

                  return GestureDetector(
                    onTap: () => _onMenuTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50,
                        bottom: isSelected ? 20 : 5,
                      ),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.pink.shade400 : Colors.white, // 選択色はピンク
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                          ]
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'],
                          size: isSelected ? 40 : 30,
                          color: isSelected ? Colors.white : Colors.pink.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      
      // テスト用ボタン（動作確認用）
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateStreetPass,
        label: const Text('誕生日ゲット'),
        icon: const Icon(Icons.cake),
        backgroundColor: Colors.pink.shade400,
      ),
    );
  }
}