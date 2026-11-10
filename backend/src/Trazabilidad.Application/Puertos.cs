using Trazabilidad.Domain;

namespace Trazabilidad.Application;

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
