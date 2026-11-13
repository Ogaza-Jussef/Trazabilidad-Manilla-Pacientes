import 'package:flutter_test/flutter_test.dart';
import 'package:trazabilidad_manillas/datos/url_api.dart';

void main() {
  test('en el sitio publicado la API va en la misma carpeta que la página', () {
    final pagina = Uri.parse('https://appsintranet.esculapiosis.com/TrazabilidadManillas/');
    expect(
      urlApiPara(pagina, esWeb: true),
      'https://appsintranet.esculapiosis.com/TrazabilidadManillas',
    );
  });

  test('en el equipo de desarrollo la web sigue usando el puerto 5080', () {
    expect(
      urlApiPara(Uri.parse('http://localhost:8080/'), esWeb: true),
      'http://localhost:5080',
    );
  });
}
