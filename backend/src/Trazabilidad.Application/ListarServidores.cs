using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed class ListarServidores
{
    private readonly ICatalogoServidores _catalogo;

    public ListarServidores(ICatalogoServidores catalogo)
    {
        _catalogo = catalogo;
    }

    public async Task<IReadOnlyList<ServidorPublico>> Ejecutar(
        string? usuario,
        string? contrasena,
        CancellationToken cancelacion)
    {
        var nombre = usuario?.Trim() ?? "";
        var clave = contrasena ?? "";
        if (nombre.Length is < 1 or > 40 || clave.Length is < 1 or > 80)
        {
            throw new ErrorValidacion(
                "El usuario y la contraseña son obligatorios.",
                new DetalleValidacion("usuario", "requerido"),
                new DetalleValidacion("contrasena", "requerido"));
        }

        return await _catalogo.Listar(nombre, clave, cancelacion);
    }
}
