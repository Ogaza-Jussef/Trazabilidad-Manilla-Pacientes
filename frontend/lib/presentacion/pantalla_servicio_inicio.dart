import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../tema/tema_sis.dart';
import 'widgets_sis/widgets_sis.dart';

class PantallaServicioInicio extends StatefulWidget {
  const PantallaServicioInicio({
    super.key,
    required this.almacen,
    required this.servidor,
    required this.token,
    required this.usuario,
    required this.codigoEmpresa,
    required this.nombreEmpresa,
    required this.alGuardar,
  });

  final AlmacenAjustes almacen;
  final String servidor;
  final String token;
  final String usuario;
  final String codigoEmpresa;
  final String nombreEmpresa;
  final void Function(AjustesPuesto ajustes) alGuardar;

  @override
  State<PantallaServicioInicio> createState() => _PantallaServicioInicioState();
}

class _PantallaServicioInicioState extends State<PantallaServicioInicio> {
  var _servicios = const <String>[];
  String? _servicio;
  var _cargando = true;
  var _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  ApiTrazabilidad get _api => ApiTrazabilidad(AjustesPuesto(
        baseUrl: widget.servidor,
        token: widget.token,
        usuario: widget.usuario,
        codigoEmpresa: widget.codigoEmpresa,
        nombreEmpresa: widget.nombreEmpresa,
        servicio: _servicio ?? '',
      ));

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resultado = await _api.listarServiciosManilla(widget.codigoEmpresa);
    if (!mounted) return;
    switch (resultado) {
      case OkApi(valor: final lista):
        setState(() {
          _cargando = false;
          _servicios = lista;
          _servicio = lista.contains(_servicio) ? _servicio : (lista.isEmpty ? null : lista.first);
          _error = lista.isEmpty ? 'No hay servicios para esta empresa.' : null;
        });
      case FalloApi(mensaje: final mensaje):
        setState(() {
          _cargando = false;
          _servicios = const <String>[];
          _servicio = null;
          _error = mensaje;
        });
    }
  }

  Future<void> _empezar() async {
    final servicio = _servicio;
    if (servicio == null) return;
    final ajustes = AjustesPuesto(
      baseUrl: widget.servidor,
      token: widget.token,
      usuario: widget.usuario,
      codigoEmpresa: widget.codigoEmpresa,
      nombreEmpresa: widget.nombreEmpresa,
      servicio: servicio,
    );
    setState(() => _ocupado = true);
    await widget.almacen.guardar(ajustes);
    if (!mounted) return;
    widget.alGuardar(ajustes);
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return FondoSis(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Servicio')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('${widget.codigoEmpresa} - ${widget.nombreEmpresa}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Elige el servicio de este puesto.',
                style: FuentesSis.inter(color: ColoresSis.suave),
              ),
              const SizedBox(height: 16),
              if (_cargando) const BarraProgresoSis(),
              if (!_cargando && _servicios.isNotEmpty)
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _servicio,
                  decoration: const InputDecoration(labelText: 'Servicio de este puesto'),
                  items: [
                    for (final servicio in _servicios) DropdownMenuItem(value: servicio, child: Text(servicio)),
                  ],
                  onChanged: _ocupado
                      ? null
                      : (valor) {
                          if (valor != null) setState(() => _servicio = valor);
                        },
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                MensajeErrorSis(mensaje: _error!),
              ],
              if (!_cargando && _servicios.isEmpty) ...[
                const SizedBox(height: 12),
                BotonSis(
                  texto: 'Reintentar',
                  variante: VarianteBotonSis.normal,
                  onPressed: _cargar,
                ),
              ],
              const SizedBox(height: 20),
              BotonSis(
                texto: 'Empezar',
                ocupado: _ocupado,
                onPressed: _ocupado || _cargando || _servicio == null ? null : _empezar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
