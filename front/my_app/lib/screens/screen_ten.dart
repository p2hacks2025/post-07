import 'package:flutter/material.dart';

class ScreenTen extends StatefulWidget {
  const ScreenTen({super.key});

  @override
  State<ScreenTen> createState() => _ScreenTenState();
}

class _ScreenTenState extends State<ScreenTen> {
  // タスクとその達成状態を管理
  final List<Map<String, dynamic>> _tasks = [
    {'title': '朝ごはんを食べる', 'completed': true},
    {'title': '運動する', 'completed': false},
    {'title': '本を読む', 'completed': true},
    {'title': '友達に連絡する', 'completed': false},
    {'title': '部屋を掃除する', 'completed': false},
    {'title': '新しいレシピを試す', 'completed': true},
    {'title': '日記を書く', 'completed': false},
    {'title': '植物に水をやる', 'completed': true},
    {'title': '瞑想する', 'completed': false},
    {'title': '感謝の気持ちを表す', 'completed': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お祝いリスト'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '🎉 達成したタスク ${_tasks.where((task) => task['completed'] == true).length}/${_tasks.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isCompleted = task['completed'] as bool;
                
                return Card(
                  color: isCompleted 
                      ? Colors.green.shade50 
                      : Colors.grey.shade100,
                  elevation: isCompleted ? 3 : 1,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: CheckboxListTile(
                    title: Text(
                      '${index + 1}. ${task['title'] as String}',
                      style: TextStyle(
                        fontSize: 72,
                        color: isCompleted 
                            ? Colors.black87 
                            : Colors.grey.shade400,
                      ),
                    ),
                    value: isCompleted,
                    activeColor: Colors.green,
                    onChanged: (bool? value) {
                      setState(() {
                        _tasks[index]['completed'] = value ?? false;
                      });
                    },
                    secondary: Icon(
                      isCompleted ? Icons.celebration : Icons.radio_button_unchecked,
                      color: isCompleted ? Colors.green : Colors.grey.shade300,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.green,
              ),
              child: const Text('メイン画面に戻る'),
            ),
          ),
        ],
      ),
    );
  }
}
