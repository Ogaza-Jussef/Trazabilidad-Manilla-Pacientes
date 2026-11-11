import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import 'pantalla_empresas.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key, required this.almacen, required this.alGuardar});

  final AlmacenAjustes almacen;
  final void Function(AjustesPuesto ajustes) alGuardar;

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  static const _urlApi = 'http://10.0.2.2:5080';

  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  var _servidores = const <String>[];
  String? _servidor;
  var _ocultar = true;
  var _cargandoServidores = true;
  var _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarServidores();
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  ApiTrazabilidad get _api => ApiTrazabilidad(AjustesPuesto(
        baseUrl: _urlApi,
        token: '',
        usuario: _usuario.text.trim(),
        codigoEmpresa: '',
        nombreEmpresa: '',
        servicio: 'Colocación de manilla',
      ));

  Future<void> _cargarServidores() async {
    setState(() {
      _cargandoServidores = true;
      _error = null;
    });
    final resultado = await _api.listarServidores();
    if (!mounted) return;
    switch (resultado) {
      case OkApi(valor: final nombres):
        setState(() {
          _cargandoServidores = false;
          _servidores = nombres;
          if (_servidor != null && !nombres.contains(_servidor)) _servidor = null;
          _error = nombres.isEmpty ? 'No hay servidores disponibles.' : null;
        });
      case FalloApi(mensaje: final mensaje):
        setState(() {
          _cargandoServidores = false;
          _error = mensaje;
        });
    }
  }

  Future<void> _entrar() async {
    final servidor = _servidor;
    if (_usuario.text.trim().isEmpty || _contrasena.text.isEmpty) {
      setState(() => _error = 'Escribe el usuario y la contraseña.');
      return;
    }
    if (servidor == null) {
      setState(() => _error = 'Elige el servidor.');
      return;
    }

    setState(() {
      _ocupado = true;
      _error = null;
    });

    final resultado = await _api.iniciarSesion(
      usuario: _usuario.text.trim(),
      contrasena: _contrasena.text,
      servidor: servidor,
    );
    if (!mounted) return;
    setState(() => _ocupado = false);

    switch (resultado) {
      case OkApi(valor: final ingreso):
        if (ingreso.empresas.isEmpty || ingreso.token.isEmpty) {
          setState(() => _error = 'El usuario no tiene empresas asociadas.');
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PantallaEmpresas(
              almacen: widget.almacen,
              servidor: _urlApi,
              ingreso: ingreso,
              alGuardar: widget.alGuardar,
            ),
          ),
        );
      case FalloApi(mensaje: final mensaje):
        setState(() => _error = mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Text('Trazabilidad de manillas', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colores.primary)),
            const SizedBox(height: 8),
            Text('Ingreso', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Entra con tu usuario para ver las empresas asignadas.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colores.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usuario,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contrasena,
              obscureText: _ocultar,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                  icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_cargandoServidores)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _servidor,
                decoration: const InputDecoration(
                  labelText: 'Servidor',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final nombre in _servidores) DropdownMenuItem(value: nombre, child: Text(nombre)),
                ],
                onChanged: _ocupado ? null : (valor) => setState(() => _servidor = valor),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colores.error)),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _ocupado || _cargandoServidores ? null : _entrar,
              child: Text(_ocupado ? 'Entrando...' : 'Entrar'),
            ),
            if (!_cargandoServidores && _servidores.isEmpty) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: _cargarServidores, child: const Text('Reintentar servidores')),
            ],
          ],
        ),
      ),
    );
  }
}
