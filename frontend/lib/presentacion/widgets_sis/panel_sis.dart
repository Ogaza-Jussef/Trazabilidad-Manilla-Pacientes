import 'dart:ui';

import 'package:flutter/material.dart';

class PanelSis extends StatelessWidget {
  const PanelSis({super.key, required this.child, this.relleno = const EdgeInsets.all(20), this.difuminar = true});

  final Widget child;
  final EdgeInsets relleno;
  final bool difuminar;

  @override
  Widget build(BuildContext context) {
    final forma = BorderRadius.circular(18);
    final caja = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        borderRadius: forma,
        border: Border.all(color: const Color.fromRGBO(197, 211, 232, 0.75)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(30, 64, 120, 0.09), blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(padding: relleno, child: child),
    );
    if (!difuminar) return caja;
    return ClipRRect(
      borderRadius: forma,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: caja,
      ),
    );
  }
}
