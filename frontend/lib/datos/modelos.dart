class Paciente {
  const Paciente({
    required this.codigoEmpresa,
    required this.numeroCaso,
    required this.numeroIdentificacion,
    required this.nombre,
    required this.apellido,
  });

  final String codigoEmpresa;
  final String numeroCaso;
  final String numeroIdentificacion;
  final String nombre;
  final String apellido;

  String get nombreCompleto => '$nombre $apellido';

  factory Paciente.desdeJson(Map<String, dynamic> json) {
    return Paciente(
      codigoEmpresa: json['codigoEmpresa'] as String? ?? '',
      numeroCaso: json['numeroCaso'] as String? ?? '',
      numeroIdentificacion: json['numeroIdentificacion'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
    );
  }
}

class Lectura {
  const Lectura({
    required this.id,
    required this.numeroCaso,
    required this.nombre,
    required this.apellido,
    required this.numeroIdentificacion,
    required this.servicio,
    required this.fechaHoraCaptura,
    required this.nueva,
  });

  final int id;
  final String numeroCaso;
  final String nombre;
  final String apellido;
  final String numeroIdentificacion;
  final String servicio;
  final String fechaHoraCaptura;
  final bool nueva;

  String get nombreCompleto => '$nombre $apellido';

  factory Lectura.desdeJson(Map<String, dynamic> json, {required bool nueva}) {
    return Lectura(
      id: (json['id'] as num).toInt(),
      numeroCaso: json['numeroCaso'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      numeroIdentificacion: json['numeroIdentificacion'] as String? ?? '',
      servicio: json['servicio'] as String? ?? '',
      fechaHoraCaptura: json['fechaHoraCaptura'] as String? ?? '',
      nueva: nueva,
    );
  }
}
