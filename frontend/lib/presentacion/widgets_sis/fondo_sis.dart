import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class FondoSis extends StatelessWidget {
  const FondoSis({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: GradientesSis.fondo),
      child: Stack(
        children: [
          const Positioned(
            left: -90,
            top: -110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color.fromRGBO(188, 214, 250, 0.65), Color.fromRGBO(188, 214, 250, 0)],
                  ),
                ),
                child: SizedBox(width: 320, height: 320),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
