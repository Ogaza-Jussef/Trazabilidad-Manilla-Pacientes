/// Dirección de la API según dónde está abierta la página.
///
/// En el teléfono el puerto 5080 no responde: el firewall lo deja caer y la
/// página espera hasta el tiempo límite. En el servidor la API es otra
/// aplicación del mismo sitio, en el puerto 443.
String urlApiPara(Uri pagina, {required bool esWeb}) {
  if (!esWeb) return 'http://10.0.2.2:5080';
  final host = pagina.host;
  if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
    return 'http://localhost:5080';
  }
  return '${pagina.origin}/TrazabilidadApi';
}
