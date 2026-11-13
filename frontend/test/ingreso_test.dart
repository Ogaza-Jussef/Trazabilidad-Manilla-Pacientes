import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trazabilidad_manillas/datos/ajustes_puesto.dart';
import 'package:trazabilidad_manillas/datos/api_trazabilidad.dart';

const _ajustes = AjustesPuesto(
  baseUrl: 'http://api.local:5080',
  token: '',
  usuario: 'ana',
  codigoEmpresa: '',
  nombreEmpresa: '',
  servicio: 'Colocación de manilla',
);

http.Response _json(Object cuerpo, [int estado = 200]) =>
    http.Response(jsonEncode(cuerpo), estado, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('la web pide los servidores por la API y solo recibe el nombre', () async {
    final llamadas = <String>[];
    final cliente = MockClient((solicitud) async {
      llamadas.add('${solicitud.method} ${solicitud.url}');
      expect(solicitud.url.host, 'api.local');
      expect(jsonDecode(solicitud.body), {'usuario': 'ana', 'contrasena': 'clave'});
      return _json({
        'items': [
          {'nombre': 'Campbell'},
          {'nombre': 'Bahia'},
        ],
      });
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente);

    final resultado = await api.listarServidores(usuario: 'ana', contrasena: 'clave');

    expect(llamadas, ['POST http://api.local:5080/api/v1/servidores']);
    expect((resultado as OkApi<List<ServidorConexion>>).valor.map((servidor) => servidor.nombre), ['Campbell', 'Bahia']);
  });

  test('entrar envía el nombre del servidor, Campbell u otro, sin una IP', () async {
    final cliente = MockClient((solicitud) async {
      expect(solicitud.url.path, '/api/v1/sesiones');
      expect(jsonDecode(solicitud.body), {'usuario': 'ana', 'contrasena': 'clave', 'servidor': 'Campbell'});
      return _json({
        'token': 'sesion-local',
        'usuario': 'ana',
        'empresas': [
          {'codigo': 'C30', 'nombre': 'Fundacion Campbell'},
        ],
      });
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente);

    final resultado = await api.iniciarSesion(
      usuario: 'ana',
      contrasena: 'clave',
      servidor: const ServidorConexion(nombre: 'Campbell'),
    );

    final ingreso = (resultado as OkApi).valor;
    expect(ingreso.token, 'sesion-local');
    expect(ingreso.empresas.single.codigo, 'C30');
    expect(ingreso.empresas.single.nombre, 'Fundacion Campbell');
  });
}
