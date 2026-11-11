import 'package:flutter/material.dart';

import '../../tema/tema_sis.dart';
import 'spinner_sis.dart';

enum VarianteBotonSis { principal, normal, peligro }

class BotonSis extends StatelessWidget {
  const BotonSis({
    super.key,
    required this.texto,
    required this.onPressed,
    this.variante = VarianteBotonSis.principal,
    this.ocupado = false,
    this.compacto = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final VarianteBotonSis variante;
  final bool ocupado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null && !ocupado;
    final principal = variante == VarianteBotonSis.principal;
    final peligro = variante == VarianteBotonSis.peligro;
    final radio = BorderRadius.circular(principal ? 16 : 13);
    final colorTexto = principal ? Colors.white : (peligro ? ColoresSis.errorTexto : ColoresSis.navy);
    final alto = compacto ? 48.0 : 52.0;

    final boton = Opacity(
      opacity: activo ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: principal
              ? GradientesSis.boton
              : peligro
                  ? GradientesSis.botonPeligro
                  : GradientesSis.botonNormal,
          borderRadius: radio,
          border: principal
              ? null
              : Border.all(color: peligro ? const Color(0xFFE29AA3) : const Color(0xFFD3DFF0)),
          boxShadow: principal && activo
              ? const [BoxShadow(color: Color.fromRGBO(0, 117, 31, 0.35), blurRadius: 16, offset: Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: activo ? onPressed : null,
            borderRadius: radio,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 48, minHeight: alto),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (principal)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: alto * 0.55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(principal ? 16 : 13)),
                          gradient: GradientesSis.brillo,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: compacto ? 12 : 16, vertical: 8),
                    child: Row(
                      mainAxisSize: compacto ? MainAxisSize.min : MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (ocupado) ...[
                          const SpinnerSis(tamano: 18),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            texto,
                            textAlign: TextAlign.center,
                            style: FuentesSis.inter(tamano: compacto ? 14 : 16, peso: FontWeight.w700, color: colorTexto),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (compacto) return boton;
    return SizedBox(width: double.infinity, child: boton);
  }
}
