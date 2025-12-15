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

  // ■ 修正点1: 画面遷移用の 'route' をリストに戻しました
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'route': '/home'},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded, 'route': '/profile'},
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'route': '/map'}, 
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'route': '/birthday'}, 
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'route': '/square'},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'route': '/trophy'},
  ];

  @override
  void initState() {
    super.initState();
    _menuPageController = PageController(initialPage: _initialMenuIndex, viewportFraction: 0.1);
    _calendarPageController = PageController(initialPage: _initialCalendarPage);
    _baseMonth = DateTime.now();
    _currentDisplayMonth = _baseMonth;
  }

  @override
  void dispose() {
    _menuPageController.dispose();
    _calendarPageController.dispose();
    super.dispose();
  }

  // ■ 修正点2: タップ時の画面遷移処理を実装
  void _onMenuTap(int index) {
    // まず見た目のアニメーション処理
    if (index != _selectedMenuIndex) {
      _menuPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() {
        _selectedMenuIndex = index;
      });
    }

    // 画面遷移ロジック
    final routeName = _screens[index]['route'];
    
    // 少し遅らせて遷移させるとアニメーションが見えて心地よいですが、
    // 即座に遷移させたい場合は Future.delayed を外してください。
    Future.delayed(const Duration(milliseconds: 200), () {
      if (routeName == '/home') {
        // ホームならスタックを全部消して戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (routeName == '/birthday') {
        // 自分自身の画面なら何もしない
      } else {
        // 他の画面へ遷移（main.dartでroutesが設定されている前提）
        Navigator.of(context).pushNamed(routeName);
      }
    });
  }

  // カレンダーの月移動
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

  Widget _buildDateCell(int day, int month) {
    final key = "${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    final isCollected = _collectedBirthdays.contains(key);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: isCollected ? Colors.pink.shade400 : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildMonthGrid(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: GridView.builder(
        // ■ 修正点: スクロール可能に戻しました（BouncingScrollPhysics）
        physics: const BouncingScrollPhysics(), 
        // メニューの裏までスクロールできるように下の余白を確保
        padding: const EdgeInsets.only(bottom: 120), 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
          childAspectRatio: 1.1, 
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
          Positioned.fill(
             child: Container(color: Colors.pink.shade50),
          ),

          Column(
            children: [
              const SizedBox(height: 5),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.pink, size: 24),
                      onPressed: () => _moveMonth(-1),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        '${_currentDisplayMonth.month}月', 
                        key: ValueKey<int>(_currentDisplayMonth.month),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold, 
                          color: Colors.pink.shade800
                        )
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.pink, size: 24),
                      onPressed: () => _moveMonth(1),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              Expanded(
                child: PageView.builder(
                  controller: _calendarPageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onCalendarPageChanged,
                  itemBuilder: (context, index) {
                    final monthDiff = index - _initialCalendarPage;
                    final monthDate = DateTime(_baseMonth.year, _baseMonth.month + monthDiff, 1);
                    return _buildMonthGrid(monthDate);
                  },
                ),
              ),
            ],
          ),

          // 下部メニュー
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
                   // 手動スワイプ時は遷移させず、アイコン選択状態だけ更新する（必要ならここでも遷移可能）
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