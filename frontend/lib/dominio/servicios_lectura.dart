/// Une el servicio ya elegido con la lista de la empresa, sin repetir ni dejar el valor fuera.
List<String> opcionesServicio(String actual, Iterable<String> remotos) {
  final vistos = <String>{};
  final lista = <String>[];
  for (final servicio in [actual, ...remotos]) {
    final nombre = servicio.trim();
    if (nombre.isEmpty || !vistos.add(nombre)) continue;
    lista.add(nombre);
  }
  return lista;
}
