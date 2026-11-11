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

class ApiTrazabilidad {
  ApiTrazabilidad(this.ajustes, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final AjustesPuesto ajustes;
  final http.Client _cliente;

  Map<String, String> get _encabezados => {
        'Authorization': 'Bearer ${ajustes.token}',
        'Accept': 'application/json',
        'X-Codigo-Empresa': ajustes.codigoEmpresa,
      };

  static final Uri _servidoresCampbell = Uri.parse(
    'https://appsintranet.esculapiosis.com/ApiCampbell/api/Usuarios/obtener-servidores',
  );

  Future<ResultadoApi<List<String>>> listarServidores() async {
    try {
      final respuesta = await _cliente
          .get(_servidoresCampbell, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return FalloApi('No se pudo obtener los servidores.', respuesta.statusCode);
      }
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is! List) {
        return const FalloApi('La lista de servidores no se pudo leer.', 0);
      }
      final nombres = decodificado
          .whereType<Map>()
          .map((item) => (item['Descripcion'] ?? item['descripcion'] ?? '').toString().trim())
          .where((nombre) => nombre.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return OkApi(nombres, respuesta.statusCode);
    } on TimeoutException {
      return const FalloApi('La API no respondió a tiempo.', 0);
    } catch (_) {
      return const FalloApi('No se pudo conectar con el servidor.', 0);
    }
  }

  Future<ResultadoApi<Ingreso>> iniciarSesion({
    required String usuario,
    required String contrasena,
    required String servidor,
  }) async {
    final uri = Uri.parse('${ajustes.urlBase}/api/v1/sesiones');
    return _enviar(
      () => _cliente
          .post(
            uri,
            headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
            body: jsonEncode({'usuario': usuario, 'contrasena': contrasena, 'servidor': servidor}),
          )
          .timeout(const Duration(seconds: 20)),
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
