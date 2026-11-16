class CodigoManilla {
  const CodigoManilla({required this.codigoEmpresa, required this.numeroCaso});

  final String codigoEmpresa;
  final String numeroCaso;

  static final RegExp _conEmpresa = RegExp(r'^([A-Za-z0-9]+)-([0-9]+)$');
  static final RegExp _soloCaso = RegExp(r'^[0-9]+$');

  /// El caso es el consecutivo del ingreso: 1, 2, 3… sin ceros a la izquierda.
  /// Si el QR trae solo ese número, [empresaSiSoloHayCaso] es la empresa del puesto.
  static CodigoManilla? leer(String bruto, {String? empresaSiSoloHayCaso}) {
    final texto = bruto.trim();
    if (texto.isEmpty || texto.length > 40) return null;

    final conEmpresa = _conEmpresa.firstMatch(texto);
    if (conEmpresa != null) {
      final empresa = conEmpresa.group(1)!.toUpperCase();
      final caso = _consecutivo(conEmpresa.group(2)!);
      if (empresa.isEmpty || empresa.length > 10 || caso == null) return null;
      return CodigoManilla(codigoEmpresa: empresa, numeroCaso: caso);
    }

    final empresaPuesto = empresaSiSoloHayCaso?.trim().toUpperCase() ?? '';
    if (empresaPuesto.isEmpty || empresaPuesto.length > 10 || !_soloCaso.hasMatch(texto)) {
      return null;
    }
    final caso = _consecutivo(texto);
    if (caso == null) return null;
    return CodigoManilla(codigoEmpresa: empresaPuesto, numeroCaso: caso);
  }

  static String? _consecutivo(String digitos) {
    if (digitos.isEmpty || digitos.length > 18 || digitos.startsWith('0')) return null;
    return digitos;
  }

  String get texto => '$codigoEmpresa-$numeroCaso';
}
