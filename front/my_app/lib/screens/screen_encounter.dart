import 'package:flutter/material.dart';

class ScreenEncounter extends StatelessWidget {
  const ScreenEncounter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれ違い検出'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Center(
        child: Text(
          'すれ違いました！',
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
