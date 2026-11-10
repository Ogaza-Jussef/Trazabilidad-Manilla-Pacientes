using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.Mysql;

public sealed class RepositorioTrazabilidadMySql : IRepositorioTrazabilidad
{
    public Task<TrazabilidadManilla?> Obtener(long id, CancellationToken cancelacion) =>
        Pendiente();

    public Task<TrazabilidadManilla?> ObtenerPorCasoYServicio(
        string numeroCaso,
        string servicio,
        CancellationToken cancelacion) =>
        Pendiente();

    public Task<IReadOnlyList<TrazabilidadManilla>> ListarPorCaso(
        string numeroCaso,
        int limite,
        long? despuesDeId,
        CancellationToken cancelacion) =>
        PendienteLista();

    public Task<(TrazabilidadManilla Fila, bool Creada)> Agregar(
        NuevaTrazabilidad nueva,
        CancellationToken cancelacion) =>
        PendienteCreacion();

    private static Task<TrazabilidadManilla?> Pendiente() =>
        throw new ErrorDependencia("La conexión a la base de datos está pendiente.");

    private static Task<IReadOnlyList<TrazabilidadManilla>> PendienteLista() =>
        throw new ErrorDependencia("La conexión a la base de datos está pendiente.");

    private static Task<(TrazabilidadManilla Fila, bool Creada)> PendienteCreacion() =>
        throw new ErrorDependencia("La conexión a la base de datos está pendiente.");
}
