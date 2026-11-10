class CodigoManilla {
  const CodigoManilla({required this.codigoEmpresa, required this.numeroCaso});

  final String codigoEmpresa;
  final String numeroCaso;

  static final RegExp _patron = RegExp(r'^([A-Za-z0-9]+)-([0-9]+)$');

  static CodigoManilla? leer(String bruto) {
    final texto = bruto.trim();
    if (texto.length > 40) return null;
    final coincidencia = _patron.firstMatch(texto);
    if (coincidencia == null) return null;
    final empresa = coincidencia.group(1)!.toUpperCase();
    final caso = coincidencia.group(2)!;
    if (empresa.length > 10 || caso.length > 20) return null;
    return CodigoManilla(codigoEmpresa: empresa, numeroCaso: caso);
  }

  String get texto => '$codigoEmpresa-$numeroCaso';
}
