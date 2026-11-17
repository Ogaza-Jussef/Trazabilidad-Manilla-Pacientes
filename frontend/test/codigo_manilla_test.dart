import 'package:flutter_test/flutter_test.dart';
import 'package:trazabilidad_manillas/dominio/codigo_manilla.dart';

void main() {
  test('el caso es el consecutivo del ingreso', () {
    final codigo = CodigoManilla.leer('c30-1');
    expect(codigo, isNotNull);
    expect(codigo!.codigoEmpresa, 'C30');
    expect(codigo.numeroCaso, '1');
    expect(codigo.texto, 'C30-1');
  });

  test('si el QR trae solo el consecutivo, usa la empresa del puesto', () {
    final codigo = CodigoManilla.leer('42', empresaSiSoloHayCaso: 'c30');
    expect(codigo?.texto, 'C30-42');
  });

  test('rechaza el cero y un código sin caso numérico', () {
    expect(CodigoManilla.leer('C30-0'), isNull);
    expect(CodigoManilla.leer('C30-01'), isNull);
    expect(CodigoManilla.leer('C30-ABC'), isNull);
    expect(CodigoManilla.leer('0', empresaSiSoloHayCaso: 'C30'), isNull);
  });

  test('un QR de factura no es el caso del paciente', () {
    expect(
      CodigoManilla.leer(
        'https://catalogo-vpfe.dian.gov.co/document/123456',
        empresaSiSoloHayCaso: 'C30',
      ),
      isNull,
    );
  });
}
