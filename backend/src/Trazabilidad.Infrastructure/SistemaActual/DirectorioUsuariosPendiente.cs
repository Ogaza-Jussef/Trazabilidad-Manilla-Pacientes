using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class DirectorioUsuariosPendiente : IDirectorioUsuarios
{
    public Task<UsuarioAutenticado?> Autenticar(string usuario, string contrasena, CancellationToken cancelacion)
    {
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");
    }
}
