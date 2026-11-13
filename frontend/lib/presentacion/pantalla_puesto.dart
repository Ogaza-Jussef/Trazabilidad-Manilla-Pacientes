import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../dominio/servicios_lectura.dart';
import 'widgets_sis/widgets_sis.dart';

class PantallaPuesto extends StatefulWidget {
  const PantallaPuesto({super.key, required this.iniciales, required this.alGuardar});

  final AjustesPuesto iniciales;
  final Future<void> Function(AjustesPuesto ajustes) alGuardar;

  @override
  State<PantallaPuesto> createState() => _PantallaPuestoState();
}

class _PantallaPuestoState extends State<PantallaPuesto> {
  late String _servicio;
  var _remotos = const <String>[];
  var _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _servicio = widget.iniciales.servicio;
    _cargar();
  }

  List<String> get _opciones => opcionesServicio(_servicio, _remotos);

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resultado = await ApiTrazabilidad(widget.iniciales).listarServiciosManilla(widget.iniciales.codigoEmpresa);
    if (!mounted) return;
    switch (resultado) {
      case OkApi(valor: final lista):
        setState(() {
          _cargando = false;
          _remotos = lista;
          _error = lista.isEmpty ? 'No hay servicios para esta empresa.' : null;
        });
      case FalloApi(mensaje: final mensaje):
        setState(() {
          _cargando = false;
          _remotos = const <String>[];
          _error = mensaje;
        });
    }
  }

  Future<void> _guardar() async {
    final servicio = _servicio.trim();
    if (servicio.isEmpty) return;
    final ajustes = widget.iniciales.copiar(servicio: servicio);
    await widget.alGuardar(ajustes);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final opciones = _opciones;
    final valor = opciones.contains(_servicio) ? _servicio : null;
    return FondoSis(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Servicio')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PanelSis(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.iniciales.nombreEmpresa, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (_cargando) const BarraProgresoSis(),
                    if (!_cargando && opciones.isNotEmpty)
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: valor,
                        decoration: const InputDecoration(labelText: 'Servicio de este puesto'),
                        items: [
                          for (final servicio in opciones) DropdownMenuItem(value: servicio, child: Text(servicio)),
                        ],
                        onChanged: (nuevo) {
                          if (nuevo != null) setState(() => _servicio = nuevo);
                        },
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                MensajeErrorSis(mensaje: _error!),
                const SizedBox(height: 12),
                BotonSis(
                  texto: 'Reintentar',
                  variante: VarianteBotonSis.normal,
                  onPressed: _cargar,
                ),
              ],
              const SizedBox(height: 20),
              BotonSis(texto: 'Guardar', onPressed: valor == null ? null : _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
