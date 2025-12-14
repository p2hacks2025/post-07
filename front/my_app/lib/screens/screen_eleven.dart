import 'package:flutter/material.dart';

class ScreenEleven extends StatelessWidget {
  const ScreenEleven({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画面11'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              '画面11',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.green,
              ),
              child: const Text('メイン画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
