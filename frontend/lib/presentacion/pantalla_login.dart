import 'package:flutter/material.dart';

import '../datos/ajustes_puesto.dart';
import '../datos/api_trazabilidad.dart';
import '../tema/tema_sis.dart';
import 'pantalla_empresas.dart';
import 'widgets_sis/widgets_sis.dart';

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
  final _focoUsuario = FocusNode();
  final _focoContrasena = FocusNode();
  var _servidores = const <ServidorConexion>[];
  String? _servidor;
  String? _usuarioCargado;
  var _ocultar = true;
  var _cargandoServidores = false;
  var _intentoServidores = false;
  var _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focoUsuario.addListener(() {
      if (!_focoUsuario.hasFocus) _alDejarUsuario();
    });
    _focoContrasena.addListener(() {
      if (_focoContrasena.hasFocus) _alDejarUsuario();
    });
  }

  @override
  void dispose() {
    _focoUsuario.dispose();
    _focoContrasena.dispose();
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

  Future<void> _alDejarUsuario() async {
    final usuario = _usuario.text.trim();
    if (usuario.isEmpty) {
      if (!mounted) return;
      setState(() {
        _servidores = const <ServidorConexion>[];
        _servidor = null;
        _usuarioCargado = null;
        _intentoServidores = false;
        _cargandoServidores = false;
      });
      return;
    }
    if (_cargandoServidores || _usuarioCargado == usuario) return;
    _usuarioCargado = usuario;
    await _cargarServidores();
  }

  Future<void> _cargarServidores() async {
    final usuario = _usuario.text.trim();
    if (usuario.isEmpty) {
      setState(() => _error = 'Escribe el usuario para ver los servidores.');
      return;
    }
    setState(() {
      _cargandoServidores = true;
      _intentoServidores = true;
      _error = null;
    });
    final resultado = await _api.listarServidores();
    if (!mounted || _usuario.text.trim() != usuario) return;
    switch (resultado) {
      case OkApi(valor: final lista):
        setState(() {
          _cargandoServidores = false;
          _servidores = lista;
          if (_servidor != null && !lista.any((item) => item.nombre == _servidor)) _servidor = null;
          _error = lista.isEmpty ? 'No hay servidores disponibles.' : null;
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

    final elegido = _servidores.where((item) => item.nombre == servidor).firstOrNull;
    if (elegido == null) {
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
      servidor: elegido,
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
    return FondoSis(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            children: [
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: PanelSis(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LogoSis(alto: 100),
                        const SizedBox(height: 8),
                        Text(
                          'Trazabilidad de manillas',
                          textAlign: TextAlign.center,
                          style: FuentesSis.inter(
                            tamano: 16,
                            peso: FontWeight.w500,
                            color: ColoresSis.suave,
                            estilo: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Ingreso', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Entra con tu usuario para ver las empresas asignadas.',
                          textAlign: TextAlign.center,
                          style: FuentesSis.inter(color: ColoresSis.suave),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _usuario,
                          focusNode: _focoUsuario,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(labelText: 'Usuario'),
                          onChanged: (valor) {
                            if (_usuarioCargado != null && valor.trim() != _usuarioCargado) {
                              setState(() {
                                _servidores = const <ServidorConexion>[];
                                _servidor = null;
                                _usuarioCargado = null;
                                _intentoServidores = false;
                              });
                            }
                          },
                          onEditingComplete: _alDejarUsuario,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contrasena,
                          focusNode: _focoContrasena,
                          obscureText: _ocultar,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _ocultar = !_ocultar),
                              icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_cargandoServidores) ...[
                          const SizedBox(height: 16),
                          const BarraProgresoSis(),
                        ],
                        if (_intentoServidores && !_cargandoServidores) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            // El valor controlado se limpia si el servidor deja de existir.
                            // ignore: deprecated_member_use
                            value: _servidor,
                            decoration: const InputDecoration(labelText: 'Servidor'),
                            items: [
                              for (final item in _servidores) DropdownMenuItem(value: item.nombre, child: Text(item.nombre)),
                            ],
                            onChanged: _ocupado ? null : (valor) => setState(() => _servidor = valor),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          MensajeErrorSis(mensaje: _error!),
                        ],
                        const SizedBox(height: 24),
                        BotonSis(
                          texto: _ocupado ? 'Entrando...' : 'Entrar',
                          ocupado: _ocupado,
                          onPressed: _ocupado || _cargandoServidores ? null : _entrar,
                        ),
                        if (_intentoServidores && !_cargandoServidores && _servidores.isEmpty) ...[
                          const SizedBox(height: 12),
                          BotonSis(
                            texto: 'Reintentar servidores',
                            variante: VarianteBotonSis.normal,
                            onPressed: _cargarServidores,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
