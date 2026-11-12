using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class DirectorioUsuariosPendiente : IDirectorioUsuarios, ICatalogoServidores, IConsultaServidoresApi
{
    public Task<IReadOnlyList<ServidorPublico>> Listar(CancellationToken cancelacion) =>
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");

    public Task<IReadOnlyList<ServidorApi>> Listar(
        string token,
        string servidor,
        CancellationToken cancelacion) =>
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");

    public Task<UsuarioAutenticado?> Autenticar(
        string usuario,
        string contrasena,
        string servidor,
        CancellationToken cancelacion)
    {
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");
    }
}
