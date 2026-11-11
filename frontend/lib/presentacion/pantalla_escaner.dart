import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../dominio/codigo_manilla.dart';
import 'pantalla_confirmacion.dart';
import 'pantalla_puesto.dart';

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

  bool get _conCamara => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
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
    final codigo = CodigoManilla.leer(_codigo.text);
    if (codigo == null) {
      setState(() => _error = 'El código debe tener la forma C30-100001.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leer manilla'),
        actions: [
          TextButton(onPressed: _ocupado ? null : _cambiarPuesto, child: const Text('Servicio')),
          TextButton(onPressed: _ocupado ? null : widget.alSalir, child: const Text('Salir')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.ajustes.nombreEmpresa, style: Theme.of(context).textTheme.titleLarge),
            Text('${widget.ajustes.codigoEmpresa} · ${widget.ajustes.servicio}'),
            const SizedBox(height: 8),
            Text(
              'Apunta la cámara al QR o escribe el código. La empresa y el caso van separados por un guion.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_conCamara) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 240,
                  child: MobileScanner(
                    onDetect: (captura) {
                      if (_ocupado || captura.barcodes.isEmpty) return;
                      final valor = captura.barcodes.first.rawValue;
                      if (valor == null || valor.isEmpty) return;
                      _codigo.text = valor;
                      _continuar();
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _codigo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código QR',
                hintText: 'C30-100001',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _ocupado ? null : _continuar(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _ocupado ? null : _continuar,
              child: Text(_ocupado ? 'Consultando...' : 'Consultar paciente'),
            ),
          ],
        ),
      ),
    );
  }
}
