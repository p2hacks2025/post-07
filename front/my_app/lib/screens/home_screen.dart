import 'package:flutter/material.dart';

// ユーザー様ご提示のインポート群
import 'screen_one.dart';
import 'screen_profile.dart'; // さきほどいただいたファイル
import 'screen_map.dart';
import 'screen_birthday.dart';
import 'screen_ten.dart';
import 'screen_eleven.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 現在真ん中にあるアイコンの番号
  late PageController _pageController;

  // ■■■ 修正：プロフィール帳のデータを新しい入力項目に合わせました ■■■
  // 項目：ニックネーム, 誕生日, 出身地, トリビア
  final List<Map<String, dynamic>> _profiles = [
    {
      'nickname': 'タロウ',
      'birthday': '1月15日',
      'birthplace': '北海道',
      'trivia': '実は犬より猫派です。最近子猫を拾いました。',
      'color': Colors.blue.shade100,
      'icon': Icons.face,
    },
    {
      'nickname': 'はなちゃん',
      'birthday': '5月22日',
      'birthplace': '東京都',
      'trivia': 'カフェラテには砂糖を3本入れないと飲めません！',
      'color': Colors.pink.shade100,
      'icon': Icons.face_3,
    },
    {
      'nickname': 'イチロー',
      'birthday': '10月22日',
      'birthplace': '愛知県',
      'trivia': '毎週末キャンプに行っているので、焚き火の匂いが取れません。',
      'color': Colors.green.shade100,
      'icon': Icons.face_6,
    },
    {
      'nickname': 'ゆう',
      'birthday': '3月3日',
      'birthplace': '福岡県',
      'trivia': '音ゲーの全国大会に出たことがあります（一回戦負けですが...）',
      'color': Colors.orange.shade100,
      'icon': Icons.face_5,
    },
    {
      'nickname': 'ケンタ',
      'birthday': '8月10日',
      'birthplace': '大阪府',
      'trivia': '関西人ですが、実はお好み焼きをおかずにご飯を食べられません。',
      'color': Colors.purple.shade100,
      'icon': Icons.face_4,
    },
    {
      'nickname': 'みさき',
      'birthday': '7月20日',
      'birthplace': '沖縄県',
      'trivia': '泳げないダイバーです。海に潜るときは必死です。',
      'color': Colors.cyan.shade100,
      'icon': Icons.face_2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex, viewportFraction: 0.1);
  }

  // メニューのデータ
  final List<Map<String, dynamic>> _screens = [
    {'title': 'ホーム', 'icon': Icons.home_rounded, 'color': Colors.green.shade600},
    {'title': 'プロフィール編集', 'icon': Icons.edit_note_rounded, 'color': Colors.blue.shade400}, // アイコンと名前を少し変更
    {'title': '出身地埋め', 'icon': Icons.map_rounded, 'color': Colors.orange.shade400},
    {'title': '誕生日埋め', 'icon': Icons.cake_rounded, 'color': Colors.pink.shade400},
    {'title': '広場', 'icon': Icons.people_alt_rounded, 'color': Colors.teal.shade400},
    {'title': 'トロフィー', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber.shade600},
  ];

  void _onIconTapped(int index) {
    if (index == _selectedIndex) {
      if (index == 1) {
        // プロフィール編集画面へ遷移 (ScreenProfile)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenProfile()),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenMap()),
        );
      } else if (index == 3) {
        // ScreenThreeがscreen_birthday.dartにあると仮定
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenThree()),
        );
      } else if (index == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('ここがホームです')),
        );
      } else if (index == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenEleven()),
        );
      } else if (index == 5) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScreenTen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_screens[index]['title']} は準備中です')),
        );
      }
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ■■■ 修正：詳細ダイアログの表示内容を変更しました ■■■
  void _showProfileDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(data['icon'], size: 30),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  data['nickname'], // 名前 -> ニックネーム
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 出身地と誕生日を表示
              _buildInfoRow(Icons.location_on, '出身地', data['birthplace']),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.cake, '誕生日', data['birthday']),
              
              const Divider(height: 30, thickness: 1),
              
              // トリビア表示
              const Text('【私のトリビア】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['trivia'], // コメント/趣味 -> トリビア
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  // ダイアログ内の行を作るためのヘルパー関数
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label：', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                AppBar(
                  title: const Text('みんなのプロフィール帳'),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  titleTextStyle: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return Card(
                        elevation: 2,
                        color: profile['color'],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showProfileDetail(profile),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.5),
                                child: Icon(profile['icon'], color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              // ■■■ 修正：カードの表示内容も更新 ■■■
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  profile['nickname'], // ニックネーム
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                profile['birthplace'], // 出身地
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 下部メニュー (変更なし)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
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
                    onTap: () => _onIconTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(
                        top: isSelected ? 30 : 50,
                        bottom: isSelected ? 20 : 5,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _screens[index]['color'],
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          _screens[index]['icon'],
                          size: isSelected ? 40 : 25,
                          color: Colors.white,
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