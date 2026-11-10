import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../dominio/servicios_lectura.dart';

class PantallaPuesto extends StatefulWidget {
  const PantallaPuesto({
    super.key,
    required this.almacen,
    this.iniciales,
    this.alGuardar,
  });

  final AlmacenAjustes almacen;
  final AjustesPuesto? iniciales;
  final void Function(AjustesPuesto ajustes)? alGuardar;

  @override
  State<PantallaPuesto> createState() => _PantallaPuestoState();
}

class _PantallaPuestoState extends State<PantallaPuesto> {
  late final TextEditingController _url;
  late final TextEditingController _clave;
  late String _servicio;
  var _ocupado = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.iniciales?.baseUrl ?? 'http://10.0.2.2:5080');
    _clave = TextEditingController(text: widget.iniciales?.claveApi ?? '');
    _servicio = widget.iniciales?.servicio ?? serviciosLectura.first;
  }

  @override
  void dispose() {
    _url.dispose();
    _clave.dispose();
    super.dispose();
  }

  AjustesPuesto? _leerFormulario() {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      setState(() => _aviso = 'Escribe la dirección de la API, por ejemplo http://192.168.1.20:5080.');
      return null;
    }
    if (_clave.text.trim().isEmpty) {
      setState(() => _aviso = 'Escribe la clave de acceso.');
      return null;
    }
    return AjustesPuesto(baseUrl: url, claveApi: _clave.text.trim(), servicio: _servicio);
  }

  Future<void> _guardar() async {
    final ajustes = _leerFormulario();
    if (ajustes == null) return;
    setState(() {
      _ocupado = true;
      _aviso = null;
    });
    await widget.almacen.guardar(ajustes);
    if (!mounted) return;
    widget.alGuardar?.call(ajustes);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(ajustes);
    }
  }

  Future<void> _probar() async {
    final ajustes = _leerFormulario();
    if (ajustes == null) return;
    setState(() {
      _ocupado = true;
      _aviso = null;
    });
    final resultado = await ApiTrazabilidad(ajustes).probarConexion();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _aviso = switch (resultado) {
        OkApi() => 'La API respondió.',
        FalloApi(mensaje: final mensaje) => mensaje,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puesto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Cada puesto queda fijo en un servicio del flujo.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Dirección de la API',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clave,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Clave de acceso',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _servicio,
              decoration: const InputDecoration(
                labelText: 'Servicio de este puesto',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final servicio in serviciosLectura)
                  DropdownMenuItem(value: servicio, child: Text(servicio)),
              ],
              onChanged: _ocupado ? null : (valor) {
                if (valor != null) setState(() => _servicio = valor);
              },
            ),
            if (_aviso != null) ...[
              const SizedBox(height: 12),
              Text(_aviso!),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _ocupado ? null : _probar,
              child: const Text('Probar conexión'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _ocupado ? null : _guardar,
              child: const Text('Guardar puesto'),
            ),
          ],
        ),
      ),
    );
  }
}
