using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed record Empresa(string Codigo, string Nombre);

public sealed record UsuarioAutenticado(string Usuario, IReadOnlyList<Empresa> Empresas);

public sealed record SesionActiva(string Token, string Usuario, IReadOnlyList<Empresa> Empresas);

public interface IDirectorioUsuarios
{
    Task<UsuarioAutenticado?> Autenticar(string usuario, string contrasena, CancellationToken cancelacion);
}

public interface IAlmacenSesiones
{
    SesionActiva Crear(UsuarioAutenticado usuario);

    SesionActiva? Obtener(string token);
}

public interface IConsultaPacientes
{
    Task<Paciente?> Obtener(string codigoEmpresa, string numeroCaso, CancellationToken cancelacion);
}

public interface IRepositorioTrazabilidad
{
    Task<TrazabilidadManilla?> Obtener(long id, CancellationToken cancelacion);

    Task<TrazabilidadManilla?> ObtenerPorCasoYServicio(
        string numeroCaso,
        string servicio,
        CancellationToken cancelacion);

    Task<IReadOnlyList<TrazabilidadManilla>> ListarPorCaso(
        string numeroCaso,
        int limite,
        long? despuesDeId,
        CancellationToken cancelacion);

    Task<(TrazabilidadManilla Fila, bool Creada)> Agregar(
        NuevaTrazabilidad nueva,
        CancellationToken cancelacion);
}
