/// Dirección de la API según dónde está abierta la página.
///
/// En el servidor la página y la API son la misma aplicación de IIS.
/// Una ruta hermana como /TrazabilidadApi corta la conexión en el navegador.
String urlApiPara(Uri pagina, {required bool esWeb}) {
  if (!esWeb) return 'http://10.0.2.2:5080';
  final host = pagina.host;
  if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
    return 'http://localhost:5080';
  }

  var ruta = pagina.path;
  const paginaInicial = '/index.html';
  if (ruta.endsWith(paginaInicial)) {
    ruta = ruta.substring(0, ruta.length - paginaInicial.length);
  }
  if (ruta.endsWith('/')) ruta = ruta.substring(0, ruta.length - 1);
  return '${pagina.origin}$ruta';
}
