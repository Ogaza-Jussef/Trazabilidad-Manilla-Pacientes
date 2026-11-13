using System.Security.Cryptography;
using System.Text;
using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class DirectorioUsuariosMemoria : IDirectorioUsuarios, ICatalogoServidores, IServiciosManilla, IRegistroCapturaManilla
{
    private readonly UsuarioAutenticado _usuario;
    private readonly byte[] _contrasena;

    public DirectorioUsuariosMemoria()
    {
        _usuario = new UsuarioAutenticado(SemillaDesarrollo.Usuario, SemillaDesarrollo.Empresas, "");
        _contrasena = Encoding.UTF8.GetBytes(SemillaDesarrollo.Contrasena);
    }

    public Task<IReadOnlyList<ServidorPublico>> Listar(
        string usuario,
        string contrasena,
        CancellationToken cancelacion) =>
        Task.FromResult<IReadOnlyList<ServidorPublico>>([new ServidorPublico("Desarrollo")]);

    public Task<UsuarioAutenticado?> Autenticar(
        string usuario,
        string contrasena,
        string servidor,
        CancellationToken cancelacion)
    {
        if (servidor.Length == 0)
            return Task.FromResult<UsuarioAutenticado?>(null);

        var nombre = Encoding.UTF8.GetBytes(usuario);
        var esperado = Encoding.UTF8.GetBytes(_usuario.Usuario);
        var clave = Encoding.UTF8.GetBytes(contrasena);
        var usuarioOk = nombre.Length == esperado.Length && CryptographicOperations.FixedTimeEquals(nombre, esperado);
        var claveOk = clave.Length == _contrasena.Length && CryptographicOperations.FixedTimeEquals(clave, _contrasena);
        return Task.FromResult(usuarioOk && claveOk ? _usuario : null);
    }

    public Task<IReadOnlyList<ServicioManilla>> Listar(
        string tokenConexion,
        string usuario,
        string empresa,
        CancellationToken cancelacion) =>
        Task.FromResult<IReadOnlyList<ServicioManilla>>(
            ServiciosLectura.Orden.Select(servicio => new ServicioManilla(servicio.Nombre)).ToArray());

    public Task Registrar(
        string tokenConexion,
        string empresa,
        string idServicio,
        string noCuenta,
        DateTime fechaHoraCaptura,
        string usuario,
        CancellationToken cancelacion) =>
        Task.CompletedTask;
}
