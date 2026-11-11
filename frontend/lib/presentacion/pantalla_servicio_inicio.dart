import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../dominio/servicios_lectura.dart';
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
  var _servicio = serviciosLectura.first;
  var _ocupado = false;

  Future<void> _empezar() async {
    final ajustes = AjustesPuesto(
      baseUrl: widget.servidor,
      token: widget.token,
      usuario: widget.usuario,
      codigoEmpresa: widget.codigoEmpresa,
      nombreEmpresa: widget.nombreEmpresa,
      servicio: _servicio,
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
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _servicio,
                decoration: const InputDecoration(labelText: 'Servicio de este puesto'),
                items: [
                  for (final servicio in serviciosLectura) DropdownMenuItem(value: servicio, child: Text(servicio)),
                ],
                onChanged: _ocupado
                    ? null
                    : (valor) {
                        if (valor != null) setState(() => _servicio = valor);
                      },
              ),
              const SizedBox(height: 20),
              BotonSis(
                texto: 'Empezar',
                ocupado: _ocupado,
                onPressed: _ocupado ? null : _empezar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
