import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class ScreenBirthday extends StatefulWidget {
  const ScreenBirthday({super.key});

  @override
  State<ScreenBirthday> createState() => _ScreenBirthdayState();
}

class _ScreenBirthdayState extends State<ScreenBirthday> {
  final int _initialCalendarPage = 1000;
  late PageController _calendarPageController;
  late DateTime _baseMonth;
  DateTime _currentDisplayMonth = DateTime.now();

  // JSON 読み込み済み誕生日データ
  Map<String, bool> _birthdayData = {};
  bool _isLoading = true;
  Map<String, String> _triviaData = {};

  @override
  void initState() {
    super.initState();
    _calendarPageController = PageController(initialPage: _initialCalendarPage);
    _baseMonth = DateTime.now();
    _currentDisplayMonth = _baseMonth;

    _loadBirthdayJson();
  }

 Future<void> _loadBirthdayJson() async {
  try {
    // 1. 獲得状況 (true/false) を読み込む
    final statusString = await rootBundle.loadString('lib/json/birthday.json');
    final Map<String, dynamic> statusMap = json.decode(statusString);

    // 2. トリビア文言を読み込む
    final triviaString = await rootBundle.loadString('lib/json/birthday_trivia.json');
    final Map<String, dynamic> triviaMap = json.decode(triviaString);

    setState(() {
      _birthdayData = statusMap.map((key, value) => MapEntry(key, value as bool));
      // dynamic型をString型に変換して格納
      _triviaData = triviaMap.map((key, value) => MapEntry(key, value.toString()));
      _isLoading = false;
    });
  } catch (e) {
    debugPrint("読み込み失敗: $e");
    setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _calendarPageController.dispose();
    super.dispose();
  }

  void _moveMonth(int offset) {
    _calendarPageController.animateToPage(
      _calendarPageController.page!.toInt() + offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onCalendarPageChanged(int pageIndex) {
    setState(() {
      final monthDiff = pageIndex - _initialCalendarPage;
      _currentDisplayMonth = DateTime(_baseMonth.year, _baseMonth.month + monthDiff, 1);
    });
  }

Widget _buildDateCell(int day, int month) {
  // JSONのキー形式 "01/01" に合わせる
  final String key = "${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}";
  
  // データの存在確認。まだ読み込み中やキーがない場合は false にする
  final bool isCollected = _birthdayData[key] ?? false;
  
  // トリビアを取得（タップした時に使う）
  final String triviaText = _triviaData[key] ?? "この日のトリビアを読み込み中です...";

  return AnimatedContainer(
    // AnimatedContainerには必ず duration（アニメーション時間）が必要です
    duration: const Duration(milliseconds: 500),
    margin: const EdgeInsets.all(2), // 隣のセルとの隙間
    decoration: BoxDecoration(
      // 獲得済みならピンク、未獲得ならグレー
      color: isCollected ? Colors.pinkAccent : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isCollected ? Colors.redAccent : Colors.grey.shade400,
        width: 2,
      ),
      boxShadow: isCollected
          ? [BoxShadow(color: Colors.redAccent.withAlpha((0.5 * 255).round()), blurRadius: 4)]
          : [],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (isCollected) {
          _showTriviaDialog(month, day, triviaText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$month月$day日の人とすれ違うと解放されます！'),
              duration: const Duration(seconds: 1),
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

// ダイアログを表示する処理を外に切り出すとコードがスッキリします
void _showTriviaDialog(int month, int day, String trivia) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('✨ $month月$day日のトリビア ✨',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
      content: Text(trivia, style: const TextStyle(fontSize: 16, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    ),
  );
}


  Widget _buildMonthGrid(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final collectedCount = _birthdayData.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.pink.shade400,
        centerTitle: true,
        toolbarHeight: 40,
        title: Transform.translate(
          offset: const Offset(0, -5),
          child: const Text(
            '誕生日図鑑',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  '$collectedCount / 366',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
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
                      color: Colors.pink.shade800,
                    ),
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
    );
  }
}
