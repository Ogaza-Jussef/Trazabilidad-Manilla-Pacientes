import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ajustes_puesto.dart';
import 'modelos.dart';

sealed class ResultadoApi<T> {
  const ResultadoApi();
}

class OkApi<T> extends ResultadoApi<T> {
  const OkApi(this.valor, this.estado);
  final T valor;
  final int estado;
}

class FalloApi<T> extends ResultadoApi<T> {
  const FalloApi(this.mensaje, this.estado);
  final String mensaje;
  final int estado;
}

class ServidorConexion {
  const ServidorConexion({required this.nombre, required this.ip});

  final String nombre;

  /// Vacía cuando la lista llega por la API local, que no publica la IP.
  final String ip;
}

class ApiTrazabilidad {
  /// [porApiLocal] hace el ingreso por la API local en vez de llamar a Campbell.
  /// El navegador lo necesita porque Campbell no acepta llamadas desde otra página.
  ApiTrazabilidad(this.ajustes, {http.Client? cliente, bool? porApiLocal})
      : _cliente = cliente ?? http.Client(),
        _porApiLocal = porApiLocal ?? kIsWeb;

  final AjustesPuesto ajustes;
  final http.Client _cliente;
  final bool _porApiLocal;

  Map<String, String> get _encabezados => {
        'Authorization': 'Bearer ${ajustes.token}',
        'Accept': 'application/json',
        'X-Codigo-Empresa': ajustes.codigoEmpresa,
      };

  /// Servidor con el que se pide el primer token, antes de que el usuario elija uno.
  static const ipInicial = '192.168.2.3';

  static const _campbell = 'https://appsintranet.esculapiosis.com/ApiCampbell';
  static final Uri _tokenCampbell = Uri.parse('$_campbell/api/authtoken/tokenjwt');
  static final Uri _servidoresCampbell = Uri.parse('$_campbell/api/Usuarios/obtener-ApiServidores');
  static final Uri _empresasCampbell = Uri.parse('$_campbell/api/Usuarios/obtener-ApiUsuariosxEmpresas');

  static const _json = {'Accept': 'application/json', 'Content-Type': 'application/json'};
  static const _espera = Duration(seconds: 20);

  /// Pide el token con el usuario y la contraseña y, con ese token, la lista de servidores.
  Future<ResultadoApi<List<ServidorConexion>>> listarServidores({
    required String usuario,
    required String contrasena,
  }) async {
    if (_porApiLocal) return _listarServidoresLocal(usuario, contrasena);

    try {
      final token = await _pedirToken(ip: ipInicial, usuario: usuario, contrasena: contrasena);
      if (token is FalloApi<String>) return FalloApi(token.mensaje, token.estado);

      final respuesta = await _cliente.get(
        _servidoresCampbell,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${(token as OkApi<String>).valor}',
        },
      ).timeout(_espera);
      if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
        return FalloApi('El token no fue aceptado para listar los servidores.', respuesta.statusCode);
      }
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return FalloApi('No se pudo obtener los servidores.', respuesta.statusCode);
      }
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is! List) {
        return const FalloApi('La lista de servidores no se pudo leer.', 0);
      }
      final servidores = <ServidorConexion>[];
      final vistos = <String>{};
      for (final item in decodificado.whereType<Map>()) {
        final nombre = (item['Descripcion'] ?? item['descripcion'] ?? '').toString().trim();
        final ip = (item['Ip_Conexion'] ?? item['ip_Conexion'] ?? '').toString().trim();
        if (nombre.isEmpty || ip.isEmpty) continue;
        if (!vistos.add(nombre.toLowerCase())) continue;
        servidores.add(ServidorConexion(nombre: nombre, ip: ip));
      }
      servidores.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return OkApi(servidores, respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  /// Pide el token para el servidor elegido y consulta las empresas del usuario.
  Future<ResultadoApi<Ingreso>> iniciarSesion({
    required String usuario,
    required String contrasena,
    required ServidorConexion servidor,
  }) async {
    if (_porApiLocal) return _iniciarSesionLocal(usuario, contrasena, servidor.nombre);

    try {
      final resultado = await _pedirToken(ip: servidor.ip, usuario: usuario, contrasena: contrasena);
      if (resultado is FalloApi<String>) return FalloApi(resultado.mensaje, resultado.estado);
      final token = (resultado as OkApi<String>).valor;

      final respuesta = await _cliente
          .post(
            _empresasCampbell,
            headers: {..._json, 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'IpConexion': servidor.ip,
              'Usuario': usuario,
              'PasswordUsu': contrasena,
            }),
          )
          .timeout(_espera);
      if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
        return const FalloApi('Usuario o contraseña incorrectos.', 401);
      }
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return FalloApi('No se pudieron consultar las empresas.', respuesta.statusCode);
      }
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is! List) {
        return const FalloApi('La lista de empresas no se pudo leer.', 0);
      }
      final empresas = <EmpresaAsociada>[];
      final vistas = <String>{};
      for (final item in decodificado.whereType<Map>()) {
        final codigo = (item['Empresa'] ?? item['empresa'] ?? '').toString().trim();
        var nombre = (item['Nombre_Empresa'] ?? item['nombre_Empresa'] ?? '').toString().trim();
        if (codigo.isEmpty || !vistas.add(codigo.toLowerCase())) continue;
        if (nombre.isEmpty) nombre = codigo;
        empresas.add(EmpresaAsociada(codigo: codigo, nombre: nombre));
      }
      if (empresas.isEmpty) {
        return const FalloApi('El usuario no tiene empresas asociadas.', 401);
      }
      return OkApi(Ingreso(token: token, usuario: usuario, empresas: empresas), respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  Future<ResultadoApi<String>> _pedirToken({
    required String ip,
    required String usuario,
    required String contrasena,
  }) async {
    final respuesta = await _cliente
        .post(
          _tokenCampbell,
          headers: _json,
          body: jsonEncode({
            'Ip_Conexion': ip,
            'Username': usuario,
            'PassWordUsu': contrasena,
          }),
        )
        .timeout(_espera);
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      return FalloApi('No se pudo generar el token del usuario.', respuesta.statusCode);
    }
    final decodificado = jsonDecode(respuesta.body);
    final token = decodificado is Map ? (decodificado['token'] ?? decodificado['Token'] ?? '').toString().trim() : '';
    if (token.isEmpty) {
      return FalloApi('No se pudo generar el token del usuario.', respuesta.statusCode);
    }
    return OkApi(token, respuesta.statusCode);
  }

  Future<ResultadoApi<List<ServidorConexion>>> _listarServidoresLocal(String usuario, String contrasena) {
    return _enviar(
      () => _cliente
          .post(
            Uri.parse('${ajustes.urlBase}/api/v1/servidores'),
            headers: _json,
            body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
          )
          .timeout(_espera),
      (json, estado) {
        final items = json['items'];
        if (items is! List) return const <ServidorConexion>[];
        return [
          for (final item in items.whereType<Map>())
            if ((item['nombre'] ?? '').toString().trim().isNotEmpty)
              ServidorConexion(nombre: item['nombre'].toString().trim(), ip: ''),
        ];
      },
    );
  }

  Future<ResultadoApi<Ingreso>> _iniciarSesionLocal(String usuario, String contrasena, String servidor) {
    return _enviar(
      () => _cliente
          .post(
            Uri.parse('${ajustes.urlBase}/api/v1/sesiones'),
            headers: _json,
            body: jsonEncode({'usuario': usuario, 'contrasena': contrasena, 'servidor': servidor}),
          )
          .timeout(_espera),
      (json, estado) => Ingreso.desdeJson(json),
    );
  }

  Future<ResultadoApi<void>> probarConexion() async {
    try {
      final respuesta = await _cliente
          .get(Uri.parse('${_sinBarra(ajustes.baseUrl)}/health'), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) {
        return FalloApi('La API respondió ${respuesta.statusCode}.', respuesta.statusCode);
      }
      return const OkApi(null, 200);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con la API.', 0);
    }
  }

  Future<ResultadoApi<Paciente>> consultarPaciente(String codigoQr) async {
    final uri = Uri.parse('${ajustes.urlBase}/api/v1/pacientes').replace(
      queryParameters: {'codigoQr': codigoQr},
    );
    return _enviar(
      () => _cliente.get(uri, headers: _encabezados).timeout(const Duration(seconds: 10)),
      (json, estado) => Paciente.desdeJson(json),
    );
  }

  Future<ResultadoApi<Lectura>> registrarLectura(String codigoQr) async {
    final uri = Uri.parse('${ajustes.urlBase}/api/v1/trazabilidad');
    final encabezados = {
      ..._encabezados,
      'Content-Type': 'application/json',
      'X-Servicio-Puesto': ajustes.servicio,
    };
    final cuerpo = jsonEncode({
      'codigoQr': codigoQr,
      'servicio': ajustes.servicio,
    });
    return _enviar(
      () => _cliente.post(uri, headers: encabezados, body: cuerpo).timeout(const Duration(seconds: 10)),
      (json, estado) => Lectura.desdeJson(json, nueva: estado == 201),
    );
  }

  Future<ResultadoApi<List<Lectura>>> listar(String numeroCaso) async {
    final uri = Uri.parse('${ajustes.urlBase}/api/v1/trazabilidad').replace(
      queryParameters: {'numeroCaso': numeroCaso, 'limit': '20'},
    );
    return _enviar(
      () => _cliente.get(uri, headers: _encabezados).timeout(const Duration(seconds: 10)),
      (json, estado) {
        final items = json['items'];
        if (items is! List) return const <Lectura>[];
        return items
            .whereType<Map<String, dynamic>>()
            .map((item) => Lectura.desdeJson(item, nueva: false))
            .toList();
      },
    );
  }

  Future<ResultadoApi<T>> _enviar<T>(
    Future<http.Response> Function() llamada,
    T Function(Map<String, dynamic> json, int estado) leer,
  ) async {
    try {
      final respuesta = await llamada();
      Map<String, dynamic>? json;
      try {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is Map<String, dynamic>) json = decodificado;
      } catch (_) {
        json = null;
      }

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300 && json != null) {
        return OkApi(leer(json, respuesta.statusCode), respuesta.statusCode);
      }

      final error = json?['error'];
      final mensaje = error is Map && error['message'] is String
          ? error['message'] as String
          : 'No se pudo completar la operación.';
      return FalloApi(mensaje, respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  static String _sinBarra(String servidor) {
    final texto = servidor.trim();
    return texto.endsWith('/') ? texto.substring(0, texto.length - 1) : texto;
  }
}
