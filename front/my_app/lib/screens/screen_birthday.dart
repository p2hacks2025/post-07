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
      final jsonString = await rootBundle.loadString('lib/json/birthday.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

    

      setState(() {
        _birthdayData = jsonMap.map((key, value) => MapEntry(key, value as bool));
        _isLoading = false;

        
      });
    } catch (e) {
      setState(() {
        _birthdayData = {};
        _isLoading = false;
      });
      debugPrint("JSON読み込み失敗: $e");
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
  // JSONキーに合わせて "/" 区切りにする
  final key = "${month.toString().padLeft(2,'0')}/${day.toString().padLeft(2,'0')}";
  final isCollected = _birthdayData[key] ?? false;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    decoration: BoxDecoration(
      color: isCollected ? Colors.pinkAccent : Colors.grey.shade200, // trueならピンク、falseならグレー
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isCollected ? Colors.redAccent : Colors.grey.shade400,
        width: 2,
      ),
      boxShadow: isCollected
          ? [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 4)]
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                )
              ],
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
