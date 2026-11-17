import 'package:flutter/widgets.dart';

import 'camara_vista.dart' if (dart.library.html) 'camara_vista_web.dart' as vista;

/// Cámara que avisa cada QR que logra leer.
/// En el navegador solo mira el centro, donde va la manilla.
class CamaraManilla extends StatelessWidget {
  const CamaraManilla({super.key, required this.alDetectar});

  final void Function(String valor) alDetectar;

  @override
  Widget build(BuildContext context) => vista.construirCamara(alDetectar);
}
