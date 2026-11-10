import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../datos/modelos.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Lectura')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              lectura.nueva ? 'Lectura registrada' : 'Esta lectura ya estaba registrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(lectura.nombreCompleto, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('${lectura.servicio}'),
            Text(lectura.fechaHoraCaptura),
            const SizedBox(height: 24),
            Text('Recorrido del caso ${lectura.numeroCaso}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final paso in _lecturas)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(paso.servicio),
                subtitle: Text(paso.fechaHoraCaptura),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
              child: const Text('Escanear otra'),
            ),
          ],
        ),
      ),
    );
  }
}
