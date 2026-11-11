import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class SpinnerSis extends StatefulWidget {
  const SpinnerSis({super.key, this.tamano = 28});

  final double tamano;

  @override
  State<SpinnerSis> createState() => _SpinnerSisState();
}

class _SpinnerSisState extends State<SpinnerSis> with SingleTickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _giro,
      child: CustomPaint(
        size: Size.square(widget.tamano),
        painter: const _ArcoSis(),
      ),
    );
  }
}

class _ArcoSis extends CustomPainter {
  const _ArcoSis();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final anillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.12
      ..strokeCap = StrokeCap.round
      ..color = ColoresSis.anilloSpinner;
    final avance = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.12
      ..strokeCap = StrokeCap.round
      ..color = ColoresSis.verde;
    final area = rect.deflate(size.shortestSide * 0.08);
    canvas.drawArc(area, 0, 6.28318, false, anillo);
    canvas.drawArc(area, -1.2, 2.2, false, avance);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
