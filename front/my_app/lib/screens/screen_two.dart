import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _triviaController = TextEditingController();
  
  int? _selectedMonth;
  int? _selectedDay;

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdayController.dispose();
    _birthplaceController.dispose();
    _triviaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    // 初期値の設定
    int initialMonth = _selectedMonth ?? DateTime.now().month;
    int initialDay = _selectedDay ?? DateTime.now().day;
    
    // 月の日数を取得
    int getDaysInMonth(int month) {
      if (month == 2) return 29; // うるう年を考慮して29日まで
      if ([4, 6, 9, 11].contains(month)) return 30;
      return 31;
    }

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int tempMonth = initialMonth;
        int tempDay = initialDay;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            int maxDays = getDaysInMonth(tempMonth);
            if (tempDay > maxDays) {
              tempDay = maxDays;
            }
            
            return Container(
              height: 300,
              color: Colors.white,
              child: Column(
                children: [
                  // ヘッダー
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        const Text(
                          '誕生日を選択',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = tempMonth;
                              _selectedDay = tempDay;
                              _birthdayController.text = '$tempMonth月$tempDay日';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('完了'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // ピッカー
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 月のピッカー
                          SizedBox(
                            width: 80,
                            height: 150,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempMonth = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                int month = index + 1;
                                bool isSelected = month == tempMonth;
                                return Center(
                                  child: Text(
                                    '$month',
                                    style: TextStyle(
                                      fontSize: isSelected ? 28 : 20,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                              childCount: 12,
                            ),
                            controller: FixedExtentScrollController(
                              initialItem: tempMonth - 1,
                            ),
                          ),
                        ),
                        const Text(
                          '月',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 20),
                        // 日のピッカー
                        SizedBox(
                          width: 80,
                          height: 150,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempDay = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                int day = index + 1;
                                bool isSelected = day == tempDay;
                                return Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: isSelected ? 28 : 20,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                              childCount: maxDays,
                            ),
                            controller: FixedExtentScrollController(
                              initialItem: tempDay - 1,
                            ),
                          ),
                        ),
                        const Text(
                          '日',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // APIのエンドポイントURL（ご自身のサーバーURLに変更してください）
        final url = Uri.parse('http://localhost:5000/api/profile');
        
        // 送信するデータ
        final data = {
          'nickname': _nicknameController.text,
          'birthday': _birthdayController.text,
          'birthplace': _birthplaceController.text,
          'trivia': _triviaController.text,
        };
        
        // API呼び出し（ローディング表示）
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存中...')),
        );
        
        // POSTリクエストを送信
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(data),
        );
        
        if (!mounted) return;
        
        // レスポンスの確認
        if (response.statusCode == 200) {
          // 成功した場合
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('プロフィールを保存しました')),
          );
          Navigator.pop(context);
        } else {
          // エラーが発生した場合
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存に失敗しました: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // ネットワークエラーなどの例外処理
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: Colors.blue[300],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // プロフィール写真エリア
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.blue[200],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '写真を変更',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // フォームエリア
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ニックネーム
                    const Text(
                      'ニックネーム',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: 'ニックネームを入力',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ニックネームを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // 誕生日
                    const Text(
                      '誕生日',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _birthdayController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: '誕生日を選択',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '誕生日を選択してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // 出身地
                    const Text(
                      '出身地',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _birthplaceController,
                      decoration: InputDecoration(
                        hintText: '出身地を入力',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '出身地を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // トリビアの写真
                    const Text(
                      'トリビアの写真',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 30, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('写真を追加', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // トリビアの文章
                    const Text(
                      'トリビア',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _triviaController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'あなたのトリビアを入力',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'トリビアを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 保存ボタン
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 45),
                          backgroundColor: Colors.blue[300],
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
