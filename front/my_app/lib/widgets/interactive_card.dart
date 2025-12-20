import 'package:flutter/material.dart';

class InteractiveCard extends StatefulWidget {
  // child の代わりに、角度を受け取る builder 関数を設定
  final Widget Function(BuildContext context, double xAngle, double yAngle) builder;
  const InteractiveCard({super.key, required this.builder});

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  double _xAngle = 0;
  double _yAngle = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // 感度を少し上げ、よりダイナミックに
          _yAngle += details.delta.dx * 0.15;
          _xAngle -= details.delta.dy * 0.15;

          // 最大角度を少し広げる
          _xAngle = _xAngle.clamp(-0.25, 0.25);
          _yAngle = _yAngle.clamp(-0.25, 0.25);
        });
      },
      onPanEnd: (_) => setState(() { _xAngle = 0; _yAngle = 0; }),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) 
          ..rotateX(_xAngle)
          ..rotateY(_yAngle),
        alignment: FractionalOffset.center,
        // ここで builder を呼び出し、現在の角度を渡す
        child: widget.builder(context, _xAngle, _yAngle),
      ),
    );
  }
}