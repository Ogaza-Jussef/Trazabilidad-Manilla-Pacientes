import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../tema/tema_sis.dart';
import 'pantalla_servicio_inicio.dart';
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

  void _entrarEmpresa() {
    final codigo = _codigo;
    if (codigo == null) return;
    final empresa = widget.ingreso.empresas.firstWhere((item) => item.codigo == codigo);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaServicioInicio(
          almacen: widget.almacen,
          servidor: widget.servidor,
          token: widget.ingreso.token,
          usuario: widget.ingreso.usuario,
          codigoEmpresa: empresa.codigo,
          nombreEmpresa: empresa.nombre,
          alGuardar: widget.alGuardar,
        ),
      ),
    );
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
                  if (valor == null) return;
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
              BotonSis(
                texto: 'Entrar',
                onPressed: _codigo == null ? null : _entrarEmpresa,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
