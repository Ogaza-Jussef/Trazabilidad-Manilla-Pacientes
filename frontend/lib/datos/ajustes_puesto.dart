import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EmpresaAsociada {
  const EmpresaAsociada({required this.codigo, required this.nombre});

  final String codigo;
  final String nombre;

  factory EmpresaAsociada.desdeJson(Map<String, dynamic> json) {
    return EmpresaAsociada(
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
    );
  }
}

class Ingreso {
  const Ingreso({required this.token, required this.usuario, required this.empresas});

  final String token;
  final String usuario;
  final List<EmpresaAsociada> empresas;

  factory Ingreso.desdeJson(Map<String, dynamic> json) {
    final lista = json['empresas'];
    final empresas = lista is List
        ? lista.whereType<Map<String, dynamic>>().map(EmpresaAsociada.desdeJson).where((empresa) => empresa.codigo.isNotEmpty).toList()
        : <EmpresaAsociada>[];
    return Ingreso(
      token: json['token'] as String? ?? '',
      usuario: json['usuario'] as String? ?? '',
      empresas: empresas,
    );
  }
}

class AjustesPuesto {
  const AjustesPuesto({
    required this.baseUrl,
    required this.token,
    required this.usuario,
    required this.codigoEmpresa,
    required this.nombreEmpresa,
    required this.servicio,
  });

  final String baseUrl;
  final String token;
  final String usuario;
  final String codigoEmpresa;
  final String nombreEmpresa;
  final String servicio;

  String get urlBase {
    final texto = baseUrl.trim();
    return texto.endsWith('/') ? texto.substring(0, texto.length - 1) : texto;
  }

  AjustesPuesto copiar({String? servicio}) {
    return AjustesPuesto(
      baseUrl: baseUrl,
      token: token,
      usuario: usuario,
      codigoEmpresa: codigoEmpresa,
      nombreEmpresa: nombreEmpresa,
      servicio: servicio ?? this.servicio,
    );
  }

  Map<String, String> toJson() => {
        'baseUrl': baseUrl.trim(),
        'token': token,
        'usuario': usuario,
        'codigoEmpresa': codigoEmpresa,
        'nombreEmpresa': nombreEmpresa,
        'servicio': servicio,
      };

  static AjustesPuesto? desdeJson(Map<String, dynamic> json) {
    final baseUrl = json['baseUrl'] as String? ?? '';
    final token = json['token'] as String? ?? '';
    final usuario = json['usuario'] as String? ?? '';
    final codigoEmpresa = json['codigoEmpresa'] as String? ?? '';
    final nombreEmpresa = json['nombreEmpresa'] as String? ?? '';
    final servicio = json['servicio'] as String? ?? '';
    if (baseUrl.isEmpty || token.isEmpty || usuario.isEmpty || codigoEmpresa.isEmpty || servicio.isEmpty) {
      return null;
    }
    return AjustesPuesto(
      baseUrl: baseUrl,
      token: token,
      usuario: usuario,
      codigoEmpresa: codigoEmpresa,
      nombreEmpresa: nombreEmpresa,
      servicio: servicio,
    );
  }
}

class AlmacenAjustes {
  static const _clave = 'sesion_puesto';

  Future<AjustesPuesto?> leer() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_clave);
    if (bruto == null || bruto.isEmpty) return null;
    final json = jsonDecode(bruto);
    if (json is! Map<String, dynamic>) return null;
    return AjustesPuesto.desdeJson(json);
  }

  Future<void> guardar(AjustesPuesto ajustes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(ajustes.toJson()));
  }

  Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
