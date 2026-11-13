using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class DirectorioUsuariosPendiente : IDirectorioUsuarios, ICatalogoServidores, IServiciosManilla, IRegistroCapturaManilla
{
    public Task<IReadOnlyList<ServidorPublico>> Listar(
        string usuario,
        string contrasena,
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

    public Task<IReadOnlyList<ServicioManilla>> Listar(
        string tokenConexion,
        string usuario,
        string empresa,
        CancellationToken cancelacion) =>
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");

    public Task Registrar(
        string tokenConexion,
        string empresa,
        string idServicio,
        string noCuenta,
        DateTime fechaHoraCaptura,
        string usuario,
        CancellationToken cancelacion) =>
        throw new ErrorDependencia("La conexión al directorio de usuarios está pendiente.");
}
