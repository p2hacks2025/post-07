import 'dart:math';
import 'package:flutter/material.dart';

class ShiningCard extends StatefulWidget {
  final Widget child;
  final int hehCount;
  final double xAngle;
  final double yAngle;

  const ShiningCard({
    super.key,
    required this.child,
    required this.hehCount,
    this.xAngle = 0.0,
    this.yAngle = 0.0,
  });

  @override
  State<ShiningCard> createState() => _ShiningCardState();
}

class _ShiningCardState extends State<ShiningCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double opacity = 0.5;
    Color highlightColor = Colors.white;

    // --- 光の色の詳細設定 ---
    if (widget.hehCount >= 300) { // 虹
      opacity = 0.9;
    } else if (widget.hehCount >= 200) { // ゴールド
      highlightColor = const Color(0xFFFFF9C4);
      opacity = 0.8;
    } else if (widget.hehCount >= 100) { // プラチナ
      highlightColor = const Color(0xFFE0F7FA);
      opacity = 0.75;
    } else if (widget.hehCount >= 50) { // シルバー
      highlightColor = Colors.white;
      opacity = 0.7;
    } else if (widget.hehCount >= 20) { // ブロンズ
      highlightColor = const Color(0xFFFFCCBC);
      opacity = 0.6;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double tiltOffset = widget.yAngle * 1.5; 
        double currentPos = (_controller.value + tiltOffset) % 1.0;
        Alignment begin = Alignment(-1.0 - widget.yAngle * 2, -1.0 + widget.xAngle * 2);
        Alignment end = Alignment(1.0 - widget.yAngle * 2, 1.0 + widget.xAngle * 2);

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: begin,
                      end: end,
                      colors: [
                        highlightColor.withAlpha(0),
                        highlightColor.withAlpha((opacity * 255).round()),
                        highlightColor.withAlpha(((opacity * 0.5) * 255).round()),
                        highlightColor.withAlpha(0),
                      ],
                      stops: [
                        (currentPos - 0.1).clamp(0.0, 1.0),
                        currentPos.clamp(0.0, 1.0),
                        (currentPos + 0.05).clamp(0.0, 1.0),
                        (currentPos + 0.15).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.hehCount >= 300)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: begin, end: end,
                        colors: [
                            Colors.purple.withAlpha((0.2 * 255).round()),
                          Colors.blue.withAlpha((0.2 * 255).round()),
                          Colors.green.withAlpha((0.2 * 255).round()),
                          Colors.yellow.withAlpha((0.2 * 255).round()),
                          Colors.red.withAlpha((0.2 * 255).round()),
                        ],
                        stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
                        transform: GradientRotation(_controller.value * 2 * pi),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}