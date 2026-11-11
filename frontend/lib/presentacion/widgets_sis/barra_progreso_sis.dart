import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class BarraProgresoSis extends StatefulWidget {
  const BarraProgresoSis({super.key});

  @override
  State<BarraProgresoSis> createState() => _BarraProgresoSisState();
}

class _BarraProgresoSisState extends State<BarraProgresoSis> with SingleTickerProviderStateMixin {
  late final AnimationController _desliz = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _desliz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: ColoredBox(
          color: ColoresSis.pista,
          child: LayoutBuilder(
            builder: (context, limites) {
              final ancho = limites.maxWidth * 0.38;
              return AnimatedBuilder(
                animation: _desliz,
                builder: (context, _) {
                  final x = (limites.maxWidth + ancho) * _desliz.value - ancho;
                  return Stack(
                    children: [
                      Positioned(
                        left: x,
                        top: 0,
                        bottom: 0,
                        width: ancho,
                        child: const DecoratedBox(decoration: BoxDecoration(gradient: GradientesSis.barra)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
