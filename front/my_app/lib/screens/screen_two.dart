import 'package:flutter/material.dart';
import 'dart:math';

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  // メニューの初期位置（地図画面なので index: 2）
  int _selectedIndex = 2; 
  late PageController _pageController;

  // メニューデータ
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'route': '/home'},
    {'title': 'マイプロフィール', 'icon': Icons.person_rounded, 'route': '/profile'},
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'route': '/map'}, // 現在地
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'route': '/birthday'},
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'route': '/square'},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'route': '/trophy'},
  ];

  @override
  void initState() {
    super.initState();
    // ビューポートを調整してアイコンを詰め込みすぎないようにする
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.2);
  }

  // 画面遷移の処理
  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // ページコントローラーもアニメーションさせる
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeOut
    );

    // 実際の画面遷移ロジック
    if (index == 0) {
      // ホーム（0番）なら、戻る（pop）
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      // 地図（2番）なら何もしない（今の画面）
    } else {
      // その他の画面（未実装の場合はスナックバー表示）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_screens[index]['title']} 画面へ移動します（実装待ち）'),
          duration: const Duration(milliseconds: 500),
        ),
      );
      // 実装済みならここで Navigator.push(...) などを呼ぶ
      // Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
    }
  }

  // 都道府県データ
  final Map<String, Map<String, dynamic>> _prefectureData = {
    'Hokkaido': {'name': '北海道', 'trivia': '実は「北海道」という名前は、松浦武四郎という人が名付けたんだよ。', 'isCollected': false},
    'Aomori': {'name': '青森', 'trivia': '日本一のりんごの生産地！雪もすごいよ。', 'isCollected': false},
    'Iwate': {'name': '岩手', 'trivia': 'わんこそばが有名。実は面積が北海道に次いで広い！', 'isCollected': false},
    'Miyagi': {'name': '宮城', 'trivia': '仙台の牛タンは絶品。伊達政宗ゆかりの地。', 'isCollected': false},
    'Akita': {'name': '秋田', 'trivia': '秋田美人の・秋田犬・あきたこまち。', 'isCollected': false},
    'Yamagata': {'name': '山形', 'trivia': 'さくらんぼの生産量が日本一！', 'isCollected': false},
    'Fukushima': {'name': '福島', 'trivia': '面積は北海道、岩手に次いで全国3位。広い！', 'isCollected': false},
    'Ibaraki': {'name': '茨城', 'trivia': '「いばらぎ」じゃなくて「いばらき」だよ。納豆が有名。', 'isCollected': false},
    'Tochigi': {'name': '栃木', 'trivia': '日光東照宮があるよ。いちご（とちおとめ）も有名。', 'isCollected': false},
    'Gunma': {'name': '群馬', 'trivia': '草津温泉、伊香保温泉など温泉大国！かかあ天下。', 'isCollected': false},
    'Saitama': {'name': '埼玉', 'trivia': '「ダサイタマ」なんて言わせない！快晴日数が日本一多い県。', 'isCollected': false},
    'Chiba': {'name': '千葉', 'trivia': '東京ディズニーリゾートがあるのは千葉県浦安市だよ。', 'isCollected': false},
    'Tokyo': {'name': '東京', 'trivia': '日本の首都。新宿駅は世界一の乗降客数！', 'isCollected': false},
    'Kanagawa': {'name': '神奈川', 'trivia': '横浜中華街は日本最大級。人口は全国2位。', 'isCollected': false},
    'Niigata': {'name': '新潟', 'trivia': 'お米（コシヒカリ）と日本酒がおいしい雪国。', 'isCollected': false},
    'Toyama': {'name': '富山', 'trivia': '黒部ダムがあるよ。蜃気楼が見えることも。', 'isCollected': false},
    'Ishikawa': {'name': '石川', 'trivia': '金沢の兼六園は日本三名園の一つ。金箔も有名。', 'isCollected': false},
    'Fukui': {'name': '福井', 'trivia': '恐竜の化石がたくさん発掘されている「恐竜王国」。', 'isCollected': false},
    'Yamanashi': {'name': '山梨', 'trivia': '富士山があるよ（静岡との県境）。ぶどうと桃も有名。', 'isCollected': false},
    'Nagano': {'name': '長野', 'trivia': '日本アルプスがあり「日本の屋根」と呼ばれる。避暑地が多い。', 'isCollected': false},
    'Gifu': {'name': '岐阜', 'trivia': '世界遺産の白川郷（合掌造り）があるよ。', 'isCollected': false},
    'Shizuoka': {'name': '静岡', 'trivia': 'お茶の生産が盛ん。富士山（山梨との県境）も美しい。', 'isCollected': false},
    'Aichi': {'name': '愛知', 'trivia': 'トヨタ自動車の本社がある。喫茶店のモーニングが豪華。', 'isCollected': false},
    'Mie': {'name': '三重', 'trivia': '伊勢神宮があるよ。松阪牛も有名。', 'isCollected': false},
    'Shiga': {'name': '滋賀', 'trivia': '日本一大きい湖、琵琶湖があるよ。（県の面積の1/6！）', 'isCollected': false},
    'Kyoto': {'name': '京都', 'trivia': '千年の都。清水寺、金閣寺など歴史的建造物がたくさん。', 'isCollected': false},
    'Osaka': {'name': '大阪', 'trivia': '食い倒れの街。たこ焼き、お好み焼き！ユニバもあるよ。', 'isCollected': false},
    'Hyogo': {'name': '兵庫', 'trivia': '世界遺産の姫路城（白鷺城）が美しい。甲子園球場もあるよ。', 'isCollected': false},
    'Nara': {'name': '奈良', 'trivia': '東大寺の大仏様や、奈良公園の鹿が有名。', 'isCollected': false},
    'Wakayama': {'name': '和歌山', 'trivia': 'みかんと梅の生産量が日本一！パンダもたくさんいるよ。', 'isCollected': false},
    'Tottori': {'name': '鳥取', 'trivia': '鳥取砂丘が有名。人口が日本で一番少ない県。', 'isCollected': false},
    'Shimane': {'name': '島根', 'trivia': '縁結びの神様、出雲大社があるよ。', 'isCollected': false},
    'Okayama': {'name': '岡山', 'trivia': '「晴れの国」と呼ばれるほど雨が少ない。桃太郎伝説の地。', 'isCollected': false},
    'Hiroshima': {'name': '広島', 'trivia': '世界遺産の厳島神社（宮島）や原爆ドームがある。お好み焼きも。', 'isCollected': false},
    'Yamaguchi': {'name': '山口', 'trivia': '本州の最西端。秋芳洞という巨大な鍾乳洞があるよ。', 'isCollected': false},
    'Tokushima': {'name': '徳島', 'trivia': '阿波おどりが有名！鳴門の渦潮もすごい迫力。', 'isCollected': false},
    'Kagawa': {'name': '香川', 'trivia': '「うどん県」！面積が日本で一番小さい県。', 'isCollected': false},
    'Ehime': {'name': '愛媛', 'trivia': 'みかん（柑橘類）の生産が盛ん。道後温泉は日本最古の温泉の一つ。', 'isCollected': false},
    'Kochi': {'name': '高知', 'trivia': '坂本龍馬の出身地。カツオのたたきが絶品！', 'isCollected': false},
    'Fukuoka': {'name': '福岡', 'trivia': 'おいしいものがたくさん（ラーメン、明太子、もつ鍋）。屋台も楽しい。', 'isCollected': false},
    'Saga': {'name': '佐賀', 'trivia': '有田焼や伊万里焼などの陶磁器が有名。吉野ヶ里遺跡も。', 'isCollected': false},
    'Nagasaki': {'name': '長崎', 'trivia': '異国情緒あふれる街並み。カステラやちゃんぽんがおいしい。', 'isCollected': false},
    'Kumamoto': {'name': '熊本', 'trivia': '世界最大級のカルデラを持つ阿蘇山がある。くまモンも大人気。', 'isCollected': false},
    'Oita': {'name': '大分', 'trivia': '「おんせん県」！別府や湯布院など温泉の湧出量・源泉数日本一。', 'isCollected': false},
    'Miyazaki': {'name': '宮崎', 'trivia': '南国ムード満点。マンゴーや地鶏がおいしい。', 'isCollected': false},
    'Kagoshima': {'name': '鹿児島', 'trivia': '活火山の桜島があるよ。黒豚や焼酎も有名。', 'isCollected': false},
    'Okinawa': {'name': '沖縄', 'trivia': '美しい海と独自の文化。美ら海水族館が人気だよ。', 'isCollected': false},
  };

  void _simulateStreetPass() {
    final keys = _prefectureData.keys.toList();
    final randomKey = keys[Random().nextInt(keys.length)];
    setState(() {
      _prefectureData[randomKey]!['isCollected'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_prefectureData[randomKey]!['name']}の人とすれ違いました！'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ボックスをさらに大きく、横長に調整
  Widget _buildPrefBox(String id, String label, {double width = 50, double height = 35}) {
    final data = _prefectureData[id] ?? {'name': label, 'trivia': 'まだデータがないよ', 'isCollected': false};
    final bool isCollected = data['isCollected'];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.place, color: isCollected ? Colors.orange : Colors.grey),
                  const SizedBox(width: 8),
                  Text(data['name']),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCollected ? '★ 獲得済み！' : 'まだすれ違っていません', 
                       style: TextStyle(color: isCollected ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const Text('【豆知識】', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(isCollected ? data['trivia'] : '？？？？？？？？？？\n（すれ違うと豆知識が見れるよ！）'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('とじる'),
                ),
              ],
            );
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: width,
        height: height,
        margin: const EdgeInsets.all(2.0), // マージンを増やして間隔をあける
        decoration: BoxDecoration(
          color: isCollected ? Colors.orange : Colors.white,
          border: Border.all(color: Colors.grey.shade400, width: 1.0),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isCollected 
            ? [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)] 
            : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            color: isCollected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int collectedCount = _prefectureData.values.where((d) => d['isCollected'] == true).length;
    int totalCount = _prefectureData.length;

    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text('メニュー', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('ホームへ戻る'),
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('全国トリビア図鑑'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
           Center(
             child: Padding(
               padding: const EdgeInsets.only(right: 16.0),
               child: Text('$collectedCount / $totalCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             ),
           )
        ],
      ),
      
      body: Stack(
        children: [
          // ===================================================
          // 1. 地図表示エリア
          // ===================================================
          Positioned.fill(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // 縦スクロールのみ許可
              child: FittedBox(
                // ■■■ ここが重要: 横幅に合わせて強制フィット ■■■
                // これにより、画面の左右いっぱいまで地図が引き伸ばされます
                fit: BoxFit.fitWidth, 
                child: SizedBox(
                  // キャンバスの定義（横幅700に設定して要素を散りばめる）
                  width: 680, 
                  height: 850, 
                  child: Stack(
                    children: [
                      // --- 九州（左端 0px） ---
                      Positioned(
                        top: 550,
                        left: 20,
                        child: Column(
                          children: [
                            Row(children: [_buildPrefBox('Saga', '佐賀'), _buildPrefBox('Fukuoka', '福岡')]),
                            Row(children: [_buildPrefBox('Nagasaki', '長崎'), _buildPrefBox('Oita', '大分')]),
                            Row(children: [_buildPrefBox('Kumamoto', '熊本'), _buildPrefBox('Miyazaki', '宮崎')]),
                            _buildPrefBox('Kagoshima', '鹿児島'),
                          ],
                        ),
                      ),

                      // --- 中国（九州より右へ） ---
                      Positioned(
                        top: 480,
                        left: 140, 
                        child: Column(
                          children: [
                             Row(children: [_buildPrefBox('Shimane', '島根'), _buildPrefBox('Tottori', '鳥取'), _buildPrefBox('Okayama', '岡山')]),
                             Row(children: [_buildPrefBox('Yamaguchi', '山口'), _buildPrefBox('Hiroshima', '広島')]),
                          ],
                        ),
                      ),

                      // --- 四国 ---
                      Positioned(
                        top: 580,
                        left: 160, 
                        child: Column(
                          children: [
                            Row(children: [_buildPrefBox('Ehime', '愛媛'), _buildPrefBox('Kagawa', '香川')]),
                            Row(children: [_buildPrefBox('Kochi', '高知'), _buildPrefBox('Tokushima', '徳島')]),
                          ],
                        ),
                      ),

                      // --- 近畿 ---
                      Positioned(
                        top: 520,
                        left: 280, 
                        child: Column(
                          children: [
                            Row(children: [_buildPrefBox('Kyoto', '京都'), _buildPrefBox('Shiga', '滋賀'), _buildPrefBox('Mie', '三重')]),
                            Row(children: [_buildPrefBox('Hyogo', '兵庫'), _buildPrefBox('Osaka', '大阪'), _buildPrefBox('Nara', '奈良')]),
                            _buildPrefBox('Wakayama', '和歌山'),
                          ],
                        ),
                      ),

                      // --- 中部 ---
                      Positioned(
                        top: 402,
                        left: 305, 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(children: [_buildPrefBox('Niigata', '新潟'), _buildPrefBox('Nagano', '長野')]),
                            Row(children: [_buildPrefBox('Toyama', '富山'), _buildPrefBox('Gifu', '岐阜'), _buildPrefBox('Yamanashi', '山梨')]),
                            Row(children: [_buildPrefBox('Ishikawa', '石川'), _buildPrefBox('Fukui', '福井'), _buildPrefBox('Aichi', '愛知'), _buildPrefBox('Shizuoka', '静岡')]),
                          ],
                        ),
                      ),

                      // --- 関東 ---
                      Positioned(
                        top: 520,
                        left: 460, 
                        child: Column(
                          children: [
                            Row(children: [_buildPrefBox('Tochigi', '栃木'), _buildPrefBox('Ibaraki', '茨城')]),
                            Row(children: [_buildPrefBox('Gunma', '群馬'), _buildPrefBox('Saitama', '埼玉'), _buildPrefBox('Chiba', '千葉')]),
                            Row(children: [_buildPrefBox('Tokyo', '東京'), _buildPrefBox('Kanagawa', '神奈川')]),
                          ],
                        ),
                      ),

                      // --- 東北 ---
                      Positioned(
                        top: 360,
                        left: 520,
                        child: Column(
                          children: [
                            Row(children: [_buildPrefBox('Aomori', '青森'), _buildPrefBox('Iwate', '岩手')]),
                            Row(children: [_buildPrefBox('Akita', '秋田'), _buildPrefBox('Miyagi', '宮城')]),
                            Row(children: [_buildPrefBox('Yamagata', '山形'), _buildPrefBox('Fukushima', '福島')]),
                          ],
                        ),
                      ),

                      // --- 北海道（右端いっぱい 700px付近まで使用） ---
                      Positioned(
                        top: 240,
                        left: 520,
                        child: _buildPrefBox('Hokkaido', '北海道', width: 130, height: 90),
                      ),

                      // --- 沖縄 ---
                      Positioned(
                        top: 800,
                        left: 20,
                        child: _buildPrefBox('Okinawa', '沖縄', width: 100),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===================================================
          // 2. 下部メニューバー（タップで遷移可能）
          // ===================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              // グラデーションで少し見やすく
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
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

                  // アイコン自体をタップ可能にする
                  return GestureDetector(
                    onTap: () => _onMenuTap(index), // タップ時の処理
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50,
                        bottom: isSelected ? 20 : 5,
                      ),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.orange : Colors.white.withOpacity(0.2), // 選択中は背景色あり
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ]
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'],
                          size: isSelected ? 40 : 30,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
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
    );
  }
}