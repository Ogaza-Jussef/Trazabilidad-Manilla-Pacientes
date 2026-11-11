import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class NumeroPasoSis extends StatelessWidget {
  const NumeroPasoSis({super.key, required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: GradientesSis.paso),
      child: Text(
        '$numero',
        style: FuentesSis.inter(tamano: 14, peso: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
