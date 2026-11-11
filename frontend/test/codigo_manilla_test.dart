import 'package:flutter_test/flutter_test.dart';
import 'package:trazabilidad_manillas/dominio/codigo_manilla.dart';

void main() {
  test('separa empresa y caso', () {
    final codigo = CodigoManilla.leer('c30-100001');
    expect(codigo, isNotNull);
    expect(codigo!.codigoEmpresa, 'C30');
    expect(codigo.numeroCaso, '100001');
    expect(codigo.texto, 'C30-100001');
  });

  test('rechaza un código sin caso numérico', () {
    expect(CodigoManilla.leer('C30-ABC'), isNull);
  });
}
