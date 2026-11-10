namespace Trazabilidad.Domain;

public sealed record Paciente(
    string CodigoEmpresa,
    string NumeroCaso,
    string NumeroIdentificacion,
    string Nombre,
    string Apellido);
