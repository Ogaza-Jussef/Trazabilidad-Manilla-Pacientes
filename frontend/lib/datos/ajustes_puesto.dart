import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AjustesPuesto {
  const AjustesPuesto({
    required this.baseUrl,
    required this.claveApi,
    required this.servicio,
  });

  final String baseUrl;
  final String claveApi;
  final String servicio;

  String get urlBase {
    final texto = baseUrl.trim();
    return texto.endsWith('/') ? texto.substring(0, texto.length - 1) : texto;
  }

  Map<String, String> toJson() => {
        'baseUrl': baseUrl.trim(),
        'claveApi': claveApi,
        'servicio': servicio,
      };

  static AjustesPuesto? desdeJson(Map<String, dynamic> json) {
    final baseUrl = json['baseUrl'] as String? ?? '';
    final clave = json['claveApi'] as String? ?? '';
    final servicio = json['servicio'] as String? ?? '';
    if (baseUrl.isEmpty || clave.isEmpty || servicio.isEmpty) return null;
    return AjustesPuesto(baseUrl: baseUrl, claveApi: clave, servicio: servicio);
  }
}

class AlmacenAjustes {
  static const _clave = 'ajustes_puesto';

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
}
