using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed class IniciarSesion
{
    private readonly IDirectorioUsuarios _directorio;
    private readonly IAlmacenSesiones _sesiones;

    public IniciarSesion(IDirectorioUsuarios directorio, IAlmacenSesiones sesiones)
    {
        _directorio = directorio;
        _sesiones = sesiones;
    }

    public async Task<SesionActiva> Ejecutar(string? usuario, string? contrasena, CancellationToken cancelacion)
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

        var autenticado = await _directorio.Autenticar(nombre, clave, cancelacion);
        if (autenticado is null || autenticado.Empresas.Count == 0)
            throw new ErrorNoAutenticado("Usuario o contraseña incorrectos.");

        return _sesiones.Crear(autenticado);
    }
}
