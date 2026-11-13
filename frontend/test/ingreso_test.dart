import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trazabilidad_manillas/datos/ajustes_puesto.dart';
import 'package:trazabilidad_manillas/datos/api_trazabilidad.dart';
import 'package:trazabilidad_manillas/datos/modelos.dart';

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

  test('pide los servicios de la empresa elegida', () async {
    final cliente = MockClient((solicitud) async {
      expect(solicitud.method, 'GET');
      expect(solicitud.url.path, '/api/v1/servicios-manilla');
      expect(solicitud.url.queryParameters['empresa'], 'C30');
      expect(solicitud.headers['Authorization'], 'Bearer sesion-local');
      return _json({
        'items': [
          {'nombre': 'Colocación de manilla'},
          {'nombre': 'Paso a Qx'},
        ],
      });
    });
    final api = ApiTrazabilidad(
      const AjustesPuesto(
        baseUrl: 'http://api.local:5080',
        token: 'sesion-local',
        usuario: 'jogaza',
        codigoEmpresa: 'C30',
        nombreEmpresa: 'Fundacion Campbell',
        servicio: '',
      ),
      cliente: cliente,
    );

    final resultado = await api.listarServiciosManilla('C30');

    expect((resultado as OkApi<List<String>>).valor, ['Colocación de manilla', 'Paso a Qx']);
  });

  test('registra la captura con el servicio del puesto y el código del QR', () async {
    final cliente = MockClient((solicitud) async {
      expect(solicitud.method, 'POST');
      expect(solicitud.url.path, '/api/v1/trazabilidad');
      expect(solicitud.headers['Authorization'], 'Bearer sesion-local');
      expect(solicitud.headers['X-Codigo-Empresa'], 'C30');
      expect(solicitud.headers['X-Servicio-Puesto'], 'IQX');
      expect(jsonDecode(solicitud.body), {'codigoQr': 'C30-926667', 'servicio': 'IQX'});
      return _json({
        'id': 1,
        'numeroCaso': '926667',
        'nombre': 'Ana',
        'apellido': 'Perez',
        'numeroIdentificacion': '10000001',
        'servicio': 'IQX',
        'fechaHoraCaptura': '2026-11-13T15:21:00',
      }, 201);
    });
    final api = ApiTrazabilidad(
      const AjustesPuesto(
        baseUrl: 'http://api.local:5080',
        token: 'sesion-local',
        usuario: 'jogaza',
        codigoEmpresa: 'C30',
        nombreEmpresa: 'Fundacion Campbell',
        servicio: 'IQX',
      ),
      cliente: cliente,
    );

    final resultado = await api.registrarLectura('C30-926667');

    final lectura = (resultado as OkApi<Lectura>).valor;
    expect(lectura.nueva, isTrue);
    expect(lectura.numeroCaso, '926667');
    expect(lectura.servicio, 'IQX');
  });
}
