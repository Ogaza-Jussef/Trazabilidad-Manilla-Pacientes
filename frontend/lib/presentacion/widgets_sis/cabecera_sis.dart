import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class LogoSis extends StatelessWidget {
  const LogoSis({super.key, this.alto = 100});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: Image.asset(
        'assets/images/logo_sis.png',
        package: 'trazabilidad_manillas',
        fit: BoxFit.contain,
        alignment: Alignment.center,
        semanticLabel: 'SIS Servicios Integrales en Sistemas',
      ),
    );
  }
}

class CabeceraSis extends StatelessWidget {
  const CabeceraSis({super.key, required this.titulo, this.compacta = false});

  final String titulo;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final logo = LogoSis(alto: compacta ? 36 : 100);
    final texto = Text(
      titulo,
      style: FuentesSis.inter(tamano: compacta ? 18 : 28, peso: FontWeight.w800, color: ColoresSis.navy, titulo: true),
    );
    if (compacta) {
      return Row(
        children: [
          logo,
          const SizedBox(width: 10),
          Flexible(child: texto),
        ],
      );
    }
    return Column(
      children: [
        logo,
        const SizedBox(height: 12),
        texto,
      ],
    );
  }
}
