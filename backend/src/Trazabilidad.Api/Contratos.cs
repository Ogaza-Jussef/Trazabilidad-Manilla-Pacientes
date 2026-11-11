using Trazabilidad.Domain;

namespace Trazabilidad.Api;

public sealed record PacienteResponse(
    string CodigoEmpresa,
    string NumeroCaso,
    string NumeroIdentificacion,
    string Nombre,
    string Apellido);

public sealed record TrazabilidadResponse(
    long Id,
    string NumeroCaso,
    string Nombre,
    string Apellido,
    string NumeroIdentificacion,
    string Servicio,
    string FechaHoraCaptura);

public sealed record PaginaResponse(
    IReadOnlyList<TrazabilidadResponse> Items,
    string? NextCursor,
    int Limit);

public sealed record ServicioResponse(int Orden, string Nombre, string Area);

public sealed record EmpresaResponse(string Codigo, string Nombre);

public sealed record SesionResponse(string Token, string Usuario, IReadOnlyList<EmpresaResponse> Empresas);

public sealed record ServidorPublicoResponse(string Nombre);

public sealed class InicioSesionRequest
{
    public string? Usuario { get; set; }

    public string? Contrasena { get; set; }

    public string? Servidor { get; set; }
}

public sealed class CrearTrazabilidadRequest
{
    public string? CodigoQr { get; set; }

    public string? Servicio { get; set; }
}

public static class Mapeo
{
    public static PacienteResponse Desde(Paciente paciente) => new(
        paciente.CodigoEmpresa,
        paciente.NumeroCaso,
        paciente.NumeroIdentificacion,
        paciente.Nombre,
        paciente.Apellido);

    public static TrazabilidadResponse Desde(TrazabilidadManilla fila) => new(
        fila.Id,
        fila.NumeroCaso,
        fila.Nombre,
        fila.Apellido,
        fila.NumeroIdentificacion,
        fila.Servicio,
        fila.FechaHoraCaptura.ToString("yyyy-MM-ddTHH:mm:ss"));
}
