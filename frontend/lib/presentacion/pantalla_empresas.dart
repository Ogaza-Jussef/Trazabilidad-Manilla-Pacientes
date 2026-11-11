import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../dominio/servicios_lectura.dart';
import '../tema/tema_sis.dart';
import 'widgets_sis/widgets_sis.dart';

class PantallaEmpresas extends StatefulWidget {
  const PantallaEmpresas({
    super.key,
    required this.almacen,
    required this.servidor,
    required this.ingreso,
    required this.alGuardar,
  });

  final AlmacenAjustes almacen;
  final String servidor;
  final Ingreso ingreso;
  final void Function(AjustesPuesto ajustes) alGuardar;

  @override
  State<PantallaEmpresas> createState() => _PantallaEmpresasState();
}

class _PantallaEmpresasState extends State<PantallaEmpresas> {
  String? _codigo;
  var _servicio = serviciosLectura.first;
  var _ocupado = false;

  Future<void> _empezar() async {
    final codigo = _codigo;
    if (codigo == null) return;
    final empresa = widget.ingreso.empresas.firstWhere((item) => item.codigo == codigo);
    final ajustes = AjustesPuesto(
      baseUrl: widget.servidor,
      token: widget.ingreso.token,
      usuario: widget.ingreso.usuario,
      codigoEmpresa: empresa.codigo,
      nombreEmpresa: empresa.nombre,
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
        appBar: AppBar(title: const Text('Empresas')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.ingreso.usuario, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Elige la empresa con la que vas a trabajar.',
                style: FuentesSis.inter(color: ColoresSis.suave),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: _codigo,
                onChanged: (valor) {
                  if (_ocupado || valor == null) return;
                  setState(() => _codigo = valor);
                },
                child: Column(
                  children: [
                    for (final empresa in widget.ingreso.empresas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _codigo == empresa.codigo ? ColoresSis.seleccion : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _codigo == empresa.codigo ? ColoresSis.verde : ColoresSis.linea,
                              width: _codigo == empresa.codigo ? 1.5 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: empresa.codigo,
                            title: Text(
                              '${empresa.codigo} - ${empresa.nombre}',
                              style: FuentesSis.inter(peso: FontWeight.w600, color: ColoresSis.tinta),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // El valor controlado sigue al servicio elegido; initialValue no lo actualiza.
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
                onPressed: _codigo == null || _ocupado ? null : _empezar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
