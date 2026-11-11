import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../dominio/servicios_lectura.dart';

class PantallaPuesto extends StatefulWidget {
  const PantallaPuesto({super.key, required this.iniciales, required this.alGuardar});

  final AjustesPuesto iniciales;
  final Future<void> Function(AjustesPuesto ajustes) alGuardar;

  @override
  State<PantallaPuesto> createState() => _PantallaPuestoState();
}

class _PantallaPuestoState extends State<PantallaPuesto> {
  late String _servicio;

  @override
  void initState() {
    super.initState();
    _servicio = widget.iniciales.servicio;
  }

  Future<void> _guardar() async {
    final ajustes = widget.iniciales.copiar(servicio: _servicio);
    await widget.alGuardar(ajustes);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servicio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.iniciales.nombreEmpresa, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _servicio,
              decoration: const InputDecoration(
                labelText: 'Servicio de este puesto',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final servicio in serviciosLectura) DropdownMenuItem(value: servicio, child: Text(servicio)),
              ],
              onChanged: (valor) {
                if (valor != null) setState(() => _servicio = valor);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
