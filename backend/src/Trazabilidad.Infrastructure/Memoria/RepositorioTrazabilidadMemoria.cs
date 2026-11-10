using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class RepositorioTrazabilidadMemoria : IRepositorioTrazabilidad
{
    private readonly object _puerta = new();
    private readonly Dictionary<long, TrazabilidadManilla> _porId = new();
    private readonly Dictionary<string, TrazabilidadManilla> _porCasoServicio = new(StringComparer.Ordinal);
    private long _siguienteId;

    public Task<TrazabilidadManilla?> Obtener(long id, CancellationToken cancelacion)
    {
        lock (_puerta)
        {
            _porId.TryGetValue(id, out var fila);
            return Task.FromResult(fila);
        }
    }

    public Task<TrazabilidadManilla?> ObtenerPorCasoYServicio(
        string numeroCaso,
        string servicio,
        CancellationToken cancelacion)
    {
        lock (_puerta)
        {
            _porCasoServicio.TryGetValue(Clave(numeroCaso, servicio), out var fila);
            return Task.FromResult(fila);
        }
    }

    public Task<IReadOnlyList<TrazabilidadManilla>> ListarPorCaso(
        string numeroCaso,
        int limite,
        long? despuesDeId,
        CancellationToken cancelacion)
    {
        lock (_puerta)
        {
            var filas = _porId.Values
                .Where(fila => fila.NumeroCaso == numeroCaso && (despuesDeId is null || fila.Id > despuesDeId))
                .OrderBy(fila => fila.Id)
                .Take(limite)
                .ToArray();

            return Task.FromResult<IReadOnlyList<TrazabilidadManilla>>(filas);
        }
    }

    public Task<(TrazabilidadManilla Fila, bool Creada)> Agregar(
        NuevaTrazabilidad nueva,
        CancellationToken cancelacion)
    {
        lock (_puerta)
        {
            var clave = Clave(nueva.NumeroCaso, nueva.Servicio);
            if (_porCasoServicio.TryGetValue(clave, out var existente))
                return Task.FromResult((existente, false));

            var fila = new TrazabilidadManilla(
                ++_siguienteId,
                nueva.NumeroCaso,
                nueva.Nombre,
                nueva.Apellido,
                nueva.NumeroIdentificacion,
                nueva.Servicio,
                nueva.FechaHoraCaptura);

            _porId[fila.Id] = fila;
            _porCasoServicio[clave] = fila;
            return Task.FromResult((fila, true));
        }
    }

    private static string Clave(string numeroCaso, string servicio) => numeroCaso + "\u001f" + servicio;
}
