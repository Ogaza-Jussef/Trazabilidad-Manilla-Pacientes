using System.Security.Cryptography;
using Trazabilidad.Application;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class AlmacenSesionesMemoria : IAlmacenSesiones
{
    private readonly object _puerta = new();
    private readonly Dictionary<string, SesionActiva> _sesiones = new(StringComparer.Ordinal);

    public SesionActiva Crear(UsuarioAutenticado usuario, string servidor)
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var sesion = new SesionActiva(token, usuario.Usuario, usuario.Empresas, servidor, usuario.TokenConexion);
        lock (_puerta)
            _sesiones[token] = sesion;
        return sesion;
    }

    public SesionActiva? Obtener(string token)
    {
        lock (_puerta)
        {
            _sesiones.TryGetValue(token, out var sesion);
            return sesion;
        }
    }
}
