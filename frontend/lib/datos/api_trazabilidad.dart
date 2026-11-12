import 'dart:async';
import 'dart:convert';

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
  const ServidorConexion({
    required this.nombre,
    required this.ip,
    required this.puerto,
    required this.baseDatos,
    required this.usuarioBd,
    required this.claveBd,
  });

  final String nombre;
  final String ip;
  final int puerto;
  final String baseDatos;
  final String usuarioBd;
  final String claveBd;
}

class ApiTrazabilidad {
  ApiTrazabilidad(this.ajustes, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final AjustesPuesto ajustes;
  final http.Client _cliente;

  Map<String, String> get _encabezados => {
        'Authorization': 'Bearer ${ajustes.token}',
        'Accept': 'application/json',
        'X-Codigo-Empresa': ajustes.codigoEmpresa,
      };

  static final Uri _catalogoCampbell = Uri.parse(
    'https://appsintranet.esculapiosis.com/ApiCampbell/api/Usuarios/obtener-servidores',
  );
  static final Uri _servidoresCampbell = Uri.parse(
    'https://appsintranet.esculapiosis.com/ApiCampbell/api/Usuarios/obtener-ApiServidores',
  );
  static final Uri _tokenCampbell = Uri.parse(
    'https://appsintranet.esculapiosis.com/ApiCampbell/api/authtoken/tokenjwt',
  );
  static final Uri _empresasCampbell = Uri.parse(
    'https://appsintranet.esculapiosis.com/ApiCampbell/api/Usuarios/obtener-ApiListaEmpresas',
  );

  Future<ResultadoApi<List<ServidorConexion>>> listarServidores() async {
    final sedes = await _listarSedes();
    if (sedes is FalloApi<List<ServidorConexion>>) return sedes;
    final origen = (sedes as OkApi<List<ServidorConexion>>).valor;

    final servidores = <ServidorConexion>[];
    final vistos = <String>{};
    for (final sede in origen) {
      final consulta = await _listarServidoresDe(sede);
      if (consulta is FalloApi<List<ServidorConexion>>) return consulta;
      for (final servidor in (consulta as OkApi<List<ServidorConexion>>).valor) {
        if (vistos.add(servidor.nombre.toLowerCase())) servidores.add(servidor);
      }
    }
    if (servidores.isEmpty) {
      return OkApi(origen, 200);
    }
    servidores.sort((a, b) => a.nombre.compareTo(b.nombre));
    return OkApi(servidores, 200);
  }

  Future<ResultadoApi<List<ServidorConexion>>> _listarSedes() async {
    try {
      final respuesta = await _cliente
          .get(_catalogoCampbell, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return FalloApi('No se pudo obtener los servidores.', respuesta.statusCode);
      }
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is! List) {
        return const FalloApi('La lista de servidores no se pudo leer.', 0);
      }
      final sedes = <ServidorConexion>[];
      for (final item in decodificado.whereType<Map>()) {
        final servidor = _servidorConexionDesde(item);
        if (servidor != null) sedes.add(servidor);
      }
      return OkApi(sedes, respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  Future<ResultadoApi<List<ServidorConexion>>> _listarServidoresDe(ServidorConexion sede) async {
    try {
      final uri = _servidoresCampbell.replace(
        queryParameters: {'IpConexion': sede.ip},
      );
      final respuesta = await _cliente
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
        return OkApi([sede], respuesta.statusCode);
      }
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return FalloApi('No se pudo obtener los servidores.', respuesta.statusCode);
      }
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is! List) {
        return const FalloApi('La lista de servidores no se pudo leer.', 0);
      }
      final servidores = <ServidorConexion>[];
      for (final item in decodificado.whereType<Map>()) {
        final nombre = (item['Descripcion'] ?? item['descripcion'] ?? '').toString().trim();
        if (nombre.isEmpty) continue;
        servidores.add(ServidorConexion(
          nombre: nombre,
          ip: sede.ip,
          puerto: sede.puerto,
          baseDatos: sede.baseDatos,
          usuarioBd: sede.usuarioBd,
          claveBd: sede.claveBd,
        ));
      }
      return OkApi(servidores, respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  ServidorConexion? _servidorConexionDesde(Map<dynamic, dynamic> item) {
    final nombre = (item['Descripcion'] ?? item['descripcion'] ?? '').toString().trim();
    final ip = (item['Ip_Conexion'] ?? '').toString().trim();
    final puerto = int.tryParse('${item['Puerto']}') ?? 0;
    final baseDatos = (item['BaseDatos'] ?? '').toString().trim();
    final usuarioBd = (item['Usuario'] ?? '').toString().trim();
    final claveBd = (item['Clave'] ?? '').toString();
    if (nombre.isEmpty || ip.isEmpty || puerto <= 0 || baseDatos.isEmpty || usuarioBd.isEmpty || claveBd.isEmpty) {
      return null;
    }
    return ServidorConexion(
      nombre: nombre,
      ip: ip,
      puerto: puerto,
      baseDatos: baseDatos,
      usuarioBd: usuarioBd,
      claveBd: claveBd,
    );
  }

  Future<ResultadoApi<Ingreso>> iniciarSesion({
    required String usuario,
    required String contrasena,
    required ServidorConexion servidor,
  }) async {
    try {
      final tokenRespuesta = await _cliente
          .post(
            _tokenCampbell,
            headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
            body: jsonEncode({
              'Username': usuario,
              'PassWordUsu': contrasena,
              'Nombre': '',
              'Cedula': '',
              'Ip_Conexion': servidor.ip,
              'Puerto': servidor.puerto,
              'BaseDatos': servidor.baseDatos,
              'Usuario': servidor.usuarioBd,
              'Clave': servidor.claveBd,
              'Role': '',
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (tokenRespuesta.statusCode < 200 || tokenRespuesta.statusCode >= 300) {
        return const FalloApi('Usuario o contraseña incorrectos.', 401);
      }
      final tokenJson = jsonDecode(tokenRespuesta.body);
      final token = tokenJson is Map ? (tokenJson['token'] ?? tokenJson['Token'] ?? '').toString() : '';
      if (token.isEmpty) {
        return const FalloApi('Usuario o contraseña incorrectos.', 401);
      }

      final empresasRespuesta = await _cliente
          .post(
            _empresasCampbell,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'IpConexion': servidor.ip,
              'Usuario': usuario,
              'PasswordUsu': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (empresasRespuesta.statusCode == 401 || empresasRespuesta.statusCode == 403) {
        return const FalloApi('Usuario o contraseña incorrectos.', 401);
      }
      if (empresasRespuesta.statusCode < 200 || empresasRespuesta.statusCode >= 300) {
        return FalloApi('No se pudieron consultar las empresas.', empresasRespuesta.statusCode);
      }
      final empresasJson = jsonDecode(empresasRespuesta.body);
      if (empresasJson is! List) {
        return const FalloApi('La lista de empresas no se pudo leer.', 0);
      }
      final empresas = <EmpresaAsociada>[];
      for (final item in empresasJson.whereType<Map>()) {
        final codigo = (item['Empresa'] ?? item['empresa'] ?? '').toString().trim();
        var nombre = (item['Nombre_Empresa'] ?? item['nombre_Empresa'] ?? item['nombre'] ?? '').toString().trim();
        if (codigo.isEmpty) continue;
        if (nombre.isEmpty) nombre = codigo;
        empresas.add(EmpresaAsociada(codigo: codigo, nombre: nombre));
      }
      if (empresas.isEmpty) {
        return const FalloApi('El usuario no tiene empresas asociadas.', 401);
      }
      return OkApi(Ingreso(token: token, usuario: usuario, empresas: empresas), empresasRespuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
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
