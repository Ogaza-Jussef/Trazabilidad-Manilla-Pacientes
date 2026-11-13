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
  const ServidorConexion({required this.nombre});

  final String nombre;
}

class ApiTrazabilidad {
  /// El navegador habla con esta API. Campbell no acepta llamadas desde otra página,
  /// y la IP del servidor la resuelve la API según el nombre que eligió la persona.
  ApiTrazabilidad(this.ajustes, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final AjustesPuesto ajustes;
  final http.Client _cliente;

  Map<String, String> get _encabezados => {
        'Authorization': 'Bearer ${ajustes.token}',
        'Accept': 'application/json',
        'X-Codigo-Empresa': ajustes.codigoEmpresa,
      };

  static const _json = {'Accept': 'application/json', 'Content-Type': 'application/json'};
  static const _espera = Duration(seconds: 20);

  /// Pide a la API la lista de servidores de este usuario. La respuesta solo trae nombres.
  Future<ResultadoApi<List<ServidorConexion>>> listarServidores({
    required String usuario,
    required String contrasena,
  }) {
    return _listarServidoresLocal(usuario, contrasena);
  }

  /// Entra con el nombre del servidor elegido. La API usa la IP de ese servidor.
  Future<ResultadoApi<Ingreso>> iniciarSesion({
    required String usuario,
    required String contrasena,
    required ServidorConexion servidor,
  }) {
    return _iniciarSesionLocal(usuario, contrasena, servidor.nombre);
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
              ServidorConexion(nombre: item['nombre'].toString().trim()),
        ];
      },
    );
  }

  /// Servicios de manilla del usuario en la empresa que acaba de elegir.
  Future<ResultadoApi<List<String>>> listarServiciosManilla(String codigoEmpresa) {
    final uri = Uri.parse('${ajustes.urlBase}/api/v1/servicios-manilla').replace(
      queryParameters: {'empresa': codigoEmpresa},
    );
    return _enviar(
      () => _cliente.get(uri, headers: _encabezados).timeout(_espera),
      (json, estado) {
        final items = json['items'];
        if (items is! List) return const <String>[];
        return [
          for (final item in items.whereType<Map>())
            if ((item['nombre'] ?? '').toString().trim().isNotEmpty) item['nombre'].toString().trim(),
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
