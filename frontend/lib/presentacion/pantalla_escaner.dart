import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../dominio/codigo_manilla.dart';
import '../tema/tema_sis.dart';
import 'camara_manilla.dart';
import 'pantalla_confirmacion.dart';
import 'pantalla_puesto.dart';
import 'widgets_sis/widgets_sis.dart';

class PantallaEscaner extends StatefulWidget {
  const PantallaEscaner({
    super.key,
    required this.ajustes,
    required this.alGuardar,
    required this.alSalir,
  });

  final AjustesPuesto ajustes;
  final Future<void> Function(AjustesPuesto ajustes) alGuardar;
  final Future<void> Function() alSalir;

  @override
  State<PantallaEscaner> createState() => _PantallaEscanerState();
}

class _PantallaEscanerState extends State<PantallaEscaner> {
  final _codigo = TextEditingController();
  var _ocupado = false;
  String? _error;
  String? _ultimoAjeno;

  bool get _conCamara =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _alDetectarQr(String valor) {
    if (_ocupado) return;
    final codigo = CodigoManilla.leer(
      valor,
      empresaSiSoloHayCaso: widget.ajustes.codigoEmpresa,
    );
    if (codigo == null) {
      final texto = valor.trim().toLowerCase();
      if (texto.startsWith('http://') || texto.startsWith('https://')) return;
      if (valor == _ultimoAjeno) return;
      _ultimoAjeno = valor;
      setState(() {
        _codigo.text = valor.trim();
        _error = 'Ese QR no es el de la manilla. El caso es el consecutivo, por ejemplo C30-1.';
      });
      return;
    }
    if (codigo.codigoEmpresa != widget.ajustes.codigoEmpresa) {
      setState(() => _error = 'Esta manilla es de ${codigo.codigoEmpresa}. El puesto está en ${widget.ajustes.nombreEmpresa}.');
      return;
    }
    _ultimoAjeno = null;
    _codigo.text = codigo.texto;
    _continuar();
  }

  Future<void> _cambiarPuesto() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PantallaPuesto(
          iniciales: widget.ajustes,
          alGuardar: widget.alGuardar,
        ),
      ),
    );
  }

  Future<void> _continuar() async {
    if (_ocupado) return;
    final codigo = CodigoManilla.leer(
      _codigo.text,
      empresaSiSoloHayCaso: widget.ajustes.codigoEmpresa,
    );
    if (codigo == null) {
      setState(() => _error = 'El caso es el consecutivo del ingreso. Escríbelo como C30-1 o solo el número.');
      return;
    }
    if (codigo.codigoEmpresa != widget.ajustes.codigoEmpresa) {
      setState(() => _error = 'Esta manilla es de ${codigo.codigoEmpresa}. El puesto está en ${widget.ajustes.nombreEmpresa}.');
      return;
    }

    setState(() {
      _ocupado = true;
      _error = null;
    });

    final api = ApiTrazabilidad(widget.ajustes);
    final resultado = await api.consultarPaciente(codigo.texto);
    if (!mounted) return;

    setState(() => _ocupado = false);
    switch (resultado) {
      case OkApi(valor: final paciente):
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PantallaConfirmacion(
              ajustes: widget.ajustes,
              codigo: codigo,
              paciente: paciente,
            ),
          ),
        );
        if (mounted) _codigo.clear();
      case FalloApi(mensaje: final mensaje):
        setState(() => _error = mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FondoSis(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 72,
          title: const CabeceraSis(titulo: 'Leer manilla', compacta: true),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: BotonSis(
                texto: 'Servicio',
                variante: VarianteBotonSis.normal,
                compacto: true,
                onPressed: _ocupado ? null : _cambiarPuesto,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: BotonSis(
                texto: 'Salir',
                variante: VarianteBotonSis.peligro,
                compacto: true,
                onPressed: _ocupado ? null : widget.alSalir,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PanelSis(
                difuminar: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ajustes.nombreEmpresa, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.ajustes.codigoEmpresa} · ${widget.ajustes.servicio}',
                      style: FuentesSis.inter(color: ColoresSis.suave),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Centra solo el QR de la manilla. Los demás QR, como facturas, se ignoran.',
                style: FuentesSis.inter(tamano: 14, color: ColoresSis.suave),
              ),
              if (_conCamara) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColoresSis.linea),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final alto = constraints.maxWidth.clamp(300.0, 520.0);
                        final cuadro = alto * 0.34;
                        return SizedBox(
                          height: alto,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CamaraManilla(alDetectar: _alDetectarQr),
                              _MarcoQr(lado: cuadro),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _codigo,
                textCapitalization: TextCapitalization.characters,
                style: FuentesSis.mono(),
                decoration: const InputDecoration(
                  labelText: 'Código QR',
                  hintText: 'C30-1',
                ),
                onSubmitted: (_) => _ocupado ? null : _continuar(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                MensajeErrorSis(mensaje: _error!),
              ],
              const SizedBox(height: 20),
              BotonSis(
                texto: _ocupado ? 'Consultando...' : 'Consultar paciente',
                ocupado: _ocupado,
                onPressed: _ocupado ? null : _continuar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarcoQr extends StatelessWidget {
  const _MarcoQr({required this.lado});

  final double lado;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: lado,
            height: lado,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Text(
            'Solo se lee el QR de la manilla dentro del cuadro',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
