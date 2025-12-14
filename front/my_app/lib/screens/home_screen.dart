import 'package:flutter/material.dart';

class PlazaScreen extends StatefulWidget {
  const PlazaScreen({super.key});

  @override
  State<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends State<PlazaScreen> {
  // 選択中のページ番号
  int _selectedIndex = 0;

  // メニューをスライドさせるためのコントローラー
  // viewportFraction: 0.25 にすることで、画面に4〜5個のアイコンを同時に見せます
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 真ん中に初期ページが来るように設定
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.25);
  }

  // ■画面データのリスト
  final List<Map<String, dynamic>> _screens = [
    {
      'title': 'ホーム',
      'icon': Icons.home_rounded,
      'color': Colors.green.shade600,
      'content': 'いつもの場所',
    },
    {
      'title': 'マイプロフィール',
      'icon': Icons.person_rounded,
      'color': Colors.blue.shade400,
      'content': 'あなたの情報',
    },
    {
      'title': '出身地埋め',
      'icon': Icons.map_rounded,
      'color': Colors.orange.shade400,
      'content': '日本地図を埋めよう',
    },
    {
      'title': '誕生日埋め',
      'icon': Icons.cake_rounded,
      'color': Colors.pink.shade400,
      'content': '祝ってあげよう',
    },
    {
      'title': '広場',
      'icon': Icons.people_alt_rounded,
      'color': Colors.teal.shade400,
      'content': 'みんなが集まる場所',
    },
    {
      'title': 'トロフィー',
      'icon': Icons.emoji_events_rounded,
      'color': Colors.amber.shade600,
      'content': '実績解除！',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ■背景：すれちがい広場っぽい緑色
      backgroundColor: const Color(0xFF8BC34A), // 明るいライトグリーン

      // ■メインコンテンツエリア（上の広い部分）
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                // 画面ごとに少し色を変えたカードを表示
                color: _screens[_selectedIndex]['color'],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 画面タイトル
                  Text(
                    _screens[_selectedIndex]['title'],
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // アイコン
                  Icon(
                    _screens[_selectedIndex]['icon'],
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(height: 20),
                  // 説明文
                  Text(
                    _screens[_selectedIndex]['content'],
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ■下のスライド式メニューエリア
          Container(
            height: 140, // メニューの高さ
            decoration: const BoxDecoration(
              color: Color(0xFF689F38), // 少し濃い緑で地面っぽく
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _screens.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              // アイコンの構築
              itemBuilder: (context, index) {
                // 真ん中（選択中）かどうか判定
                final bool isSelected = index == _selectedIndex;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  margin: EdgeInsets.only(
                    top: isSelected ? 10 : 30, // 選択中は上に浮き上がる
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                                color: Colors.black26, blurRadius: 10, spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _screens[index]['icon'],
                        size: isSelected ? 40 : 25, // 選択中は大きく
                        color: isSelected ? const Color(0xFF689F38) : Colors.white,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          _screens[index]['title'],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF689F38),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}