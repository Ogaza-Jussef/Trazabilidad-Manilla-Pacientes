import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../datos/modelos.dart';
import '../tema/tema_sis.dart';
import 'widgets_sis/widgets_sis.dart';

class PantallaResultado extends StatefulWidget {
  const PantallaResultado({super.key, required this.ajustes, required this.lectura});

  final AjustesPuesto ajustes;
  final Lectura lectura;

  @override
  State<PantallaResultado> createState() => _PantallaResultadoState();
}

class _PantallaResultadoState extends State<PantallaResultado> {
  List<Lectura> _lecturas = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultado = await ApiTrazabilidad(widget.ajustes).listar(widget.lectura.numeroCaso);
    if (!mounted || resultado is! OkApi<List<Lectura>>) return;
    setState(() => _lecturas = resultado.valor);
  }

  @override
  Widget build(BuildContext context) {
    final lectura = widget.lectura;
    final nueva = lectura.nueva;
    return FondoSis(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Lectura')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: nueva ? ColoresSis.panelOk : ColoresSis.panelAviso,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: nueva ? ColoresSis.exitoBorde : ColoresSis.avisoBorde),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChipEstadoSis(
                        estado: nueva ? EstadoChipSis.exito : EstadoChipSis.advertencia,
                        etiqueta: nueva ? 'Registrada' : 'Ya registrada',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nueva ? 'Captura del QR registrada' : 'Esta lectura ya estaba registrada',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(lectura.nombreCompleto, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(lectura.servicio, style: FuentesSis.inter(color: ColoresSis.tinta)),
                      Text(lectura.fechaHoraCaptura, style: FuentesSis.mono(tamano: 13, color: ColoresSis.suave)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Recorrido del caso ${lectura.numeroCaso}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (var i = 0; i < _lecturas.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NumeroPasoSis(numero: i + 1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_lecturas[i].servicio, style: FuentesSis.inter(peso: FontWeight.w600, color: ColoresSis.tinta)),
                            const SizedBox(height: 2),
                            Text(_lecturas[i].fechaHoraCaptura, style: FuentesSis.mono(tamano: 13, color: ColoresSis.suave)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              BotonSis(
                texto: 'Escanear otra',
                onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
