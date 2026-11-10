namespace Trazabilidad.Domain;

public sealed record TrazabilidadManilla(
    long Id,
    string NumeroCaso,
    string Nombre,
    string Apellido,
    string NumeroIdentificacion,
    string Servicio,
    DateTime FechaHoraCaptura);

public sealed record NuevaTrazabilidad(
    string NumeroCaso,
    string Nombre,
    string Apellido,
    string NumeroIdentificacion,
    string Servicio,
    DateTime FechaHoraCaptura);
