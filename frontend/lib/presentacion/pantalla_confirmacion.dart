import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../datos/modelos.dart';
import '../dominio/codigo_manilla.dart';
import 'pantalla_resultado.dart';

class PantallaConfirmacion extends StatefulWidget {
  const PantallaConfirmacion({
    super.key,
    required this.ajustes,
    required this.codigo,
    required this.paciente,
  });

  final AjustesPuesto ajustes;
  final CodigoManilla codigo;
  final Paciente paciente;

  @override
  State<PantallaConfirmacion> createState() => _PantallaConfirmacionState();
}

class _PantallaConfirmacionState extends State<PantallaConfirmacion> {
  var _ocupado = false;
  String? _error;

  Future<void> _registrar() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final resultado = await ApiTrazabilidad(widget.ajustes).registrarLectura(widget.codigo.texto);
    if (!mounted) return;
    switch (resultado) {
      case OkApi(valor: final lectura):
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PantallaResultado(ajustes: widget.ajustes, lectura: lectura),
          ),
        );
      case FalloApi(mensaje: final mensaje):
        setState(() {
          _ocupado = false;
          _error = mensaje;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.paciente;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar paciente')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(paciente.nombreCompleto, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _Dato(etiqueta: 'Identificación', valor: paciente.numeroIdentificacion),
            _Dato(etiqueta: 'Caso', valor: paciente.numeroCaso),
            _Dato(etiqueta: 'Empresa', valor: paciente.codigoEmpresa),
            _Dato(etiqueta: 'Servicio', valor: widget.ajustes.servicio),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _ocupado ? null : _registrar,
              child: Text(_ocupado ? 'Guardando...' : 'Registrar lectura'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
          Text(valor, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
