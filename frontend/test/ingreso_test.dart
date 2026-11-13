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
  test('pide el token y con ese token la lista de servidores', () async {
    final llamadas = <String>[];
    final cliente = MockClient((solicitud) async {
      llamadas.add('${solicitud.method} ${solicitud.url.path}');
      if (solicitud.url.path.endsWith('/api/authtoken/tokenjwt')) {
        expect(jsonDecode(solicitud.body), {
          'Ip_Conexion': ApiTrazabilidad.ipInicial,
          'Username': 'ana',
          'PassWordUsu': 'clave',
        });
        return _json({'token': 'token-inicial', 'tipo': 'Bearer'});
      }
      expect(solicitud.headers['Authorization'], 'Bearer token-inicial');
      return _json([
        {'Ip_Conexion': '10.0.0.8', 'Descripcion': 'Campbell'},
        {'Ip_Conexion': '10.0.0.9', 'Descripcion': 'Bahia'},
      ]);
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente, porApiLocal: false);

    final resultado = await api.listarServidores(usuario: 'ana', contrasena: 'clave');

    expect(llamadas, [
      'POST /ApiCampbell/api/authtoken/tokenjwt',
      'GET /ApiCampbell/api/Usuarios/obtener-ApiServidores',
    ]);
    final servidores = (resultado as OkApi<List<ServidorConexion>>).valor;
    expect(servidores.map((servidor) => servidor.nombre), ['Bahia', 'Campbell']);
    expect(servidores.last.ip, '10.0.0.8');
  });

  test('no pide los servidores si el token falla', () async {
    var llamadas = 0;
    final cliente = MockClient((solicitud) async {
      llamadas++;
      return _json({'Mensaje': 'Falta Seleccionar el Servidor en el body.'}, 400);
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente, porApiLocal: false);

    final resultado = await api.listarServidores(usuario: 'ana', contrasena: 'clave');

    expect(llamadas, 1);
    expect((resultado as FalloApi<List<ServidorConexion>>).estado, 400);
  });

  test('entrar pide el token del servidor elegido y las empresas del usuario', () async {
    final llamadas = <String>[];
    final cliente = MockClient((solicitud) async {
      llamadas.add('${solicitud.method} ${solicitud.url.path}');
      if (solicitud.url.path.endsWith('/api/authtoken/tokenjwt')) {
        expect(jsonDecode(solicitud.body)['Ip_Conexion'], '10.0.0.8');
        return _json({'token': 'token-sede'});
      }
      expect(solicitud.headers['Authorization'], 'Bearer token-sede');
      expect(jsonDecode(solicitud.body), {'IpConexion': '10.0.0.8', 'Usuario': 'ana', 'PasswordUsu': 'clave'});
      return _json([
        {'Empresa': 'C30', 'Nombre_Empresa': 'Fundacion Campbell'},
      ]);
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente, porApiLocal: false);

    final resultado = await api.iniciarSesion(
      usuario: 'ana',
      contrasena: 'clave',
      servidor: const ServidorConexion(nombre: 'Campbell', ip: '10.0.0.8'),
    );

    expect(llamadas, [
      'POST /ApiCampbell/api/authtoken/tokenjwt',
      'POST /ApiCampbell/api/Usuarios/obtener-ApiUsuariosxEmpresas',
    ]);
    final ingreso = (resultado as OkApi).valor;
    expect(ingreso.token, 'token-sede');
    expect(ingreso.empresas.single.codigo, 'C30');
    expect(ingreso.empresas.single.nombre, 'Fundacion Campbell');
  });

  test('entrar rechaza un usuario no autorizado', () async {
    final cliente = MockClient((solicitud) async {
      if (solicitud.url.path.endsWith('/api/authtoken/tokenjwt')) return _json({'token': 'token-sede'});
      return _json({'Mensaje': 'Usuario No Autorizado: ana'}, 401);
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente, porApiLocal: false);

    final resultado = await api.iniciarSesion(
      usuario: 'ana',
      contrasena: 'clave',
      servidor: const ServidorConexion(nombre: 'Campbell', ip: '10.0.0.8'),
    );

    expect((resultado as FalloApi).estado, 401);
  });

  test('en la web el ingreso pasa por la API local', () async {
    final llamadas = <String>[];
    final cliente = MockClient((solicitud) async {
      llamadas.add('${solicitud.method} ${solicitud.url}');
      if (solicitud.url.path == '/api/v1/servidores') {
        expect(jsonDecode(solicitud.body), {'usuario': 'ana', 'contrasena': 'clave'});
        return _json({
          'items': [
            {'nombre': 'Campbell'},
          ],
        });
      }
      expect(jsonDecode(solicitud.body), {'usuario': 'ana', 'contrasena': 'clave', 'servidor': 'Campbell'});
      return _json({
        'token': 'sesion-local',
        'usuario': 'ana',
        'empresas': [
          {'codigo': 'C30', 'nombre': 'Fundacion Campbell'},
        ],
      });
    });
    final api = ApiTrazabilidad(_ajustes, cliente: cliente, porApiLocal: true);

    final servidores = await api.listarServidores(usuario: 'ana', contrasena: 'clave');
    final elegido = (servidores as OkApi<List<ServidorConexion>>).valor.single;
    final ingreso = await api.iniciarSesion(usuario: 'ana', contrasena: 'clave', servidor: elegido);

    expect(llamadas, [
      'POST http://api.local:5080/api/v1/servidores',
      'POST http://api.local:5080/api/v1/sesiones',
    ]);
    expect(elegido.ip, isEmpty);
    expect((ingreso as OkApi).valor.token, 'sesion-local');
  });
}
