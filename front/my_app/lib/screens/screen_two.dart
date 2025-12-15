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

  Future<void> _selectPrefecture() async {
    final prefectures = [
      '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
      '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
      '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
      '岐阜県', '静岡県', '愛知県', '三重県',
      '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
      '鳥取県', '島根県', '岡山県', '広島県', '山口県',
      '徳島県', '香川県', '愛媛県', '高知県',
      '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
    ];

    int initialIndex = 0;
    if (_birthplaceController.text.isNotEmpty) {
      final index = prefectures.indexOf(_birthplaceController.text);
      if (index != -1) {
        initialIndex = index;
      }
    }

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int tempIndex = initialIndex;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                          '出身地を選択',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _birthplaceController.text = prefectures[tempIndex];
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
                      child: SizedBox(
                        width: 200,
                        height: 150,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempIndex = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              bool isSelected = index == tempIndex;
                              return Center(
                                child: Text(
                                  prefectures[index],
                                  style: TextStyle(
                                    fontSize: isSelected ? 24 : 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : Colors.grey,
                                  ),
                                ),
                              );
                            },
                            childCount: prefectures.length,
                          ),
                          controller: FixedExtentScrollController(
                            initialItem: tempIndex,
                          ),
                        ),
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
        final url = Uri.parse('https://cylinderlike-dana-cryoscopic.ngrok-free.dev/');
        
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
            'ngrok-skip-browser-warning': 'true',
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
        title: const Text('プロフィール編集', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ニックネーム（横一杯）
              const Text(
                'ニックネーム',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(fontSize: 28),
                decoration: InputDecoration(
                  hintText: 'ニックネームを入力',
                  hintStyle: const TextStyle(fontSize: 28),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ニックネームを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 下部：2列レイアウト
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左列：写真2つ
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // プロフィール写真
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'プロフィール写真',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey, width: 2),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.person, size: 120, color: Colors.grey),
                                    Positioned(
                                      bottom: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          '写真を変更',
                                          style: TextStyle(color: Colors.white, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // トリビアの写真
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'トリビアの写真',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey, width: 2),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 110, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('写真を追加', style: TextStyle(color: Colors.grey, fontSize: 22)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // 右列：誕生日・出身地・トリビア・保存ボタン
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 誕生日
                          const Text(
                            '誕生日',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _birthdayController,
                            readOnly: true,
                            style: const TextStyle(fontSize: 22),
                            decoration: InputDecoration(
                              hintText: '誕生日を選択',
                              hintStyle: const TextStyle(fontSize: 22),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
                              suffixIcon: const Icon(Icons.calendar_today, size: 28),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 16),
                          
                          // 出身地
                          const Text(
                            '出身地',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _birthplaceController,
                            readOnly: true,
                            style: const TextStyle(fontSize: 22),
                            decoration: InputDecoration(
                              hintText: '出身地を選択',
                              hintStyle: const TextStyle(fontSize: 22),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
                              suffixIcon: const Icon(Icons.location_on, size: 28),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: _selectPrefecture,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '出身地を選択してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // トリビアテキスト
                          const Text(
                            'トリビア',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _triviaController,
                            maxLines: 9,
                            style: const TextStyle(fontSize: 20),
                            decoration: InputDecoration(
                              hintText: 'あなたのトリビアを入力',
                              hintStyle: const TextStyle(fontSize: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'トリビアを入力してください';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 保存ボタン（画面中央）
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 55),
                    backgroundColor: Colors.blue[300],
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}