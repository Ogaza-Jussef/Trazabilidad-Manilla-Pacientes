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
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _servidor = TextEditingController(text: 'http://10.0.2.2:5080');
  var _ocultar = true;
  var _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _servidor.dispose();
    super.dispose();
  }

  String? _servidorValido() {
    final texto = _servidor.text.trim();
    final uri = Uri.tryParse(texto);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return texto;
  }

  Future<void> _entrar() async {
    final servidor = _servidorValido();
    if (_usuario.text.trim().isEmpty || _contrasena.text.isEmpty) {
      setState(() => _error = 'Escribe el usuario y la contraseña.');
      return;
    }
    if (servidor == null) {
      setState(() => _error = 'Escribe el servidor, por ejemplo http://192.168.1.20:5080.');
      return;
    }

    setState(() {
      _ocupado = true;
      _error = null;
    });

    final api = ApiTrazabilidad(AjustesPuesto(
      baseUrl: servidor,
      token: '',
      usuario: _usuario.text.trim(),
      codigoEmpresa: '',
      nombreEmpresa: '',
      servicio: 'Colocación de manilla',
    ));
    final resultado = await api.iniciarSesion(
      servidor: servidor,
      usuario: _usuario.text.trim(),
      contrasena: _contrasena.text,
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
              servidor: servidor,
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
            TextField(
              controller: _servidor,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Servidor',
                hintText: 'http://192.168.1.20:5080',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colores.error)),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _ocupado ? null : _entrar,
              child: Text(_ocupado ? 'Entrando...' : 'Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
