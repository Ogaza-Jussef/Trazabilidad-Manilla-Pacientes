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

    public async Task<SesionActiva> Ejecutar(
        string? usuario,
        string? contrasena,
        string? servidor,
        CancellationToken cancelacion)
    {
        var nombre = usuario?.Trim() ?? "";
        var clave = contrasena ?? "";
        var sede = servidor?.Trim() ?? "";
        if (nombre.Length is < 1 or > 40 || clave.Length is < 1 or > 80 || sede.Length is < 1 or > 80)
        {
            throw new ErrorValidacion(
                "El usuario, la contraseña y el servidor son obligatorios.",
                new DetalleValidacion("usuario", "requerido"),
                new DetalleValidacion("contrasena", "requerido"),
                new DetalleValidacion("servidor", "requerido"));
        }

        var autenticado = await _directorio.Autenticar(nombre, clave, sede, cancelacion);
        if (autenticado is null || autenticado.Empresas.Count == 0)
            throw new ErrorNoAutenticado("Usuario o contraseña incorrectos.");

        return _sesiones.Crear(autenticado, sede);
    }
}
