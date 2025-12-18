import 'package:flutter/material.dart';

class ScreenEncounter extends StatelessWidget {
  const ScreenEncounter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれ違い成功'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Center(
        child: Text(
          'すれ違い成功',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade600,
          ),
        ),
      ),
    );
  }
}
