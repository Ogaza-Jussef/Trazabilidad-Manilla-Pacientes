import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';

class MensajeErrorSis extends StatelessWidget {
  const MensajeErrorSis({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresSis.errorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSis.errorBorde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: ColoresSis.errorTexto, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: FuentesSis.inter(tamano: 14, color: ColoresSis.errorTexto))),
        ],
      ),
    );
  }
}
