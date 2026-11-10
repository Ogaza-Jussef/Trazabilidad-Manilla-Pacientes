using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed class ObtenerTrazabilidad
{
    private readonly IRepositorioTrazabilidad _repositorio;

    public ObtenerTrazabilidad(IRepositorioTrazabilidad repositorio)
    {
        _repositorio = repositorio;
    }

    public async Task<TrazabilidadManilla> Ejecutar(long id, CancellationToken cancelacion)
    {
        if (id < 1)
        {
            throw new ErrorValidacion(
                "El identificador de la lectura no es válido.",
                new DetalleValidacion("id", "formato"));
        }

        var fila = await _repositorio.Obtener(id, cancelacion);
        if (fila is null)
            throw new ErrorNoEncontrado("No existe esa lectura.");

        return fila;
    }
}
