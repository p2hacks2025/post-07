import 'package:flutter/material.dart';
import 'dart:math';

class ScreenThree extends StatefulWidget {
  const ScreenThree({super.key});

  @override
  State<ScreenThree> createState() => _ScreenThreeState();
}

class _ScreenThreeState extends State<ScreenThree> {
  // ■ メニュー用コントローラー
  final int _initialMenuIndex = 3; // 誕生日画面は3番目
  late PageController _menuPageController;
  int _selectedMenuIndex = 3;

  // ■ カレンダー用コントローラー
  // 月を無限にスワイプできるように、初期位置を大きな数字（真ん中）に設定します
  final int _initialCalendarPage = 1000;
  late PageController _calendarPageController;
  late DateTime _baseMonth; // 基準となる月（現在）
  DateTime _currentDisplayMonth = DateTime.now(); // 今表示している月

  // 獲得した誕生日リスト
  final Set<String> _collectedBirthdays = {};

  // メニューデータ
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded},
    {'title': '出身地埋め', 'icon': Icons.map_rounded}, 
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded}, 
    {'title': '広場', 'icon': Icons.people_alt_rounded},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // メニューのコントローラー初期化
    _menuPageController = PageController(initialPage: _initialMenuIndex, viewportFraction: 0.2);
    
    // カレンダーのコントローラー初期化
    _calendarPageController = PageController(initialPage: _initialCalendarPage);
    _baseMonth = DateTime.now(); // 今月を基準にする
    _currentDisplayMonth = _baseMonth;
  }

  @override
  void dispose() {
    _menuPageController.dispose();
    _calendarPageController.dispose();
    super.dispose();
  }

  // メニューアイコンをタップしたときの処理
  void _onMenuTap(int index) {
    if (index == _selectedMenuIndex) {
      // 既に選択されているアイコンをタップした場合の処理
      if (index == 0) {
        // ホームへ戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      // 他の画面への遷移は必要に応じて記述
    } else {
      // ■ 修正点: 選択されていないアイコンをタップしたら、アニメーションで真ん中に持ってくる
      _menuPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() {
        _selectedMenuIndex = index;
      });
    }
  }

  // カレンダーの月移動（矢印ボタン用）
  void _moveMonth(int offset) {
    _calendarPageController.animateToPage(
      _calendarPageController.page!.toInt() + offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ページ変更時に月情報を更新
  void _onCalendarPageChanged(int pageIndex) {
    setState(() {
      // 基準月からの差分を計算して、表示月を更新
      final monthDiff = pageIndex - _initialCalendarPage;
      _currentDisplayMonth = DateTime(_baseMonth.year, _baseMonth.month + monthDiff, 1);
    });
  }

  // 誕生日ゲットシミュレーション
  void _simulateStreetPass() {
    final random = Random();
    final randomMonth = random.nextInt(12) + 1;
    final randomDay = random.nextInt(28) + 1;
    
    final date = DateTime(2024, randomMonth, randomDay); 
    final key = "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    setState(() {
      _collectedBirthdays.add(key);
    });

    // 獲得した月へジャンプするために、その月が現在の基準から何ヶ月離れているか計算
    // （今回はシンプルに通知だけ出しますが、必要ならjumpToPageも可能です）

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

  // 1日分のセルを作成
  Widget _buildDateCell(int day, int month) {
    final key = "${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    final isCollected = _collectedBirthdays.contains(key);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: isCollected ? Colors.pink.shade400 : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8), // 少し角丸を戻しました
        border: Border.all(
          color: isCollected ? Colors.pinkAccent : Colors.pink.shade100,
          width: isCollected ? 2 : 1
        ),
        boxShadow: isCollected 
          ? [BoxShadow(color: Colors.pinkAccent.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)] 
          : [],
      ),
      child: InkWell(
        onTap: () {
          if (isCollected) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('$month月$day日'),
                content: const Text('獲得済みです！'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
              ),
            );
          }
        },
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCollected ? Colors.white : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // 1ヶ月分のグリッドを作成するウィジェット
  Widget _buildMonthGrid(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0), // 左右の余白
      child: GridView.builder(
        physics: const BouncingScrollPhysics(), // カレンダー内はスクロールできるようにしてある
        // ■ 修正点: アイコンの裏に隠れるように下のパディングを少し確保
        padding: const EdgeInsets.only(bottom: 80), 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
          // ■ 修正点: 縦長になりすぎないよう 1.1 (少し横長〜正方形) に修正
          childAspectRatio: 1.1, 
          // ■ 修正点: 行間を広げて画面全体に配置
          mainAxisSpacing: 12, 
          crossAxisSpacing: 8,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final day = index + 1;
          return _buildDateCell(day, monthDate.month);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.pink.shade400,
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
          // 背景色
          Positioned.fill(
             child: Container(color: Colors.pink.shade50),
          ),

          // メインコンテンツ
          Column(
            children: [
              const SizedBox(height: 5),
              
              // 月表示バー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.pink, size: 24),
                      onPressed: () => _moveMonth(-1), // 左へスライド
                    ),
                    // アニメーション付きで月が変わるように見えるが、今回はシンプルにテキスト更新
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        '${_currentDisplayMonth.month}月', 
                        key: ValueKey<int>(_currentDisplayMonth.month), // Keyを変えるとアニメーションする
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold, 
                          color: Colors.pink.shade800
                        )
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.pink, size: 24),
                      onPressed: () => _moveMonth(1), // 右へスライド
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // ■ 修正点: カレンダー部分を PageView に変更してスライド可能に
              Expanded(
                child: PageView.builder(
                  controller: _calendarPageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onCalendarPageChanged,
                  // 十分なページ数を確保して無限スクロールっぽく見せる
                  itemBuilder: (context, index) {
                    final monthDiff = index - _initialCalendarPage;
                    final monthDate = DateTime(_baseMonth.year, _baseMonth.month + monthDiff, 1);
                    return _buildMonthGrid(monthDate);
                  },
                ),
              ),
            ],
          ),

          // 下部メニュー (アイコンのみフローティング)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              color: Colors.transparent, 
              child: PageView.builder(
                controller: _menuPageController,
                itemCount: _screens.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                   setState(() {
                     _selectedMenuIndex = index;
                   });
                },
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedMenuIndex;
                  return GestureDetector(
                    onTap: () => _onMenuTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(top: isSelected ? 30 : 50, bottom: isSelected ? 20 : 5),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // 選択中以外は透明
                          color: isSelected ? Colors.pink.shade400 : Colors.transparent,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15), 
                              blurRadius: 8, 
                              offset: const Offset(0, 4)
                            )
                          ] : [],
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'], 
                          size: isSelected ? 40 : 30, 
                          color: isSelected ? Colors.white : Colors.pink.shade400,
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
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateStreetPass,
        label: const Text('誕生日ゲット'),
        icon: const Icon(Icons.cake),
        backgroundColor: Colors.pink.shade400,
      ),
    );
  }
}