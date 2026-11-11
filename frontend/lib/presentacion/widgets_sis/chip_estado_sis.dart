import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

enum EstadoChipSis { procesando, exito, advertencia, error }

class ChipEstadoSis extends StatelessWidget {
  const ChipEstadoSis({super.key, required this.estado, required this.etiqueta});

  final EstadoChipSis estado;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final (fondo, borde, texto, punto) = switch (estado) {
      EstadoChipSis.procesando => (ColoresSis.procesandoFondo, ColoresSis.procesandoBorde, ColoresSis.azul, ColoresSis.azul),
      EstadoChipSis.exito => (ColoresSis.exitoFondo, ColoresSis.exitoBorde, ColoresSis.exitoTexto, ColoresSis.puntoOk),
      EstadoChipSis.advertencia => (ColoresSis.avisoFondo, ColoresSis.avisoBorde, ColoresSis.avisoTexto, ColoresSis.puntoAviso),
      EstadoChipSis.error => (ColoresSis.errorFondo, ColoresSis.errorBorde, ColoresSis.errorTexto, ColoresSis.puntoError),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: punto, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(etiqueta, style: FuentesSis.inter(tamano: 13, peso: FontWeight.w600, color: texto)),
        ],
      ),
    );
  }
}
