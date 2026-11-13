using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed class ListarServiciosManilla
{
    private readonly IServiciosManilla _servicios;

    public ListarServiciosManilla(IServiciosManilla servicios)
    {
        _servicios = servicios;
    }

    public async Task<IReadOnlyList<ServicioManilla>> Ejecutar(
        SesionActiva sesion,
        string? empresa,
        CancellationToken cancelacion)
    {
        var codigo = empresa?.Trim() ?? "";
        if (codigo.Length is < 1 or > 10)
        {
            throw new ErrorValidacion(
                "La empresa es obligatoria.",
                new DetalleValidacion("empresa", "requerido"));
        }

        if (!sesion.Empresas.Any(item => string.Equals(item.Codigo, codigo, StringComparison.OrdinalIgnoreCase)))
            throw new ErrorProhibido("Este usuario no tiene esa empresa asociada.");

        return await _servicios.Listar(sesion.TokenConexion, sesion.Usuario, codigo, cancelacion);
    }
}
