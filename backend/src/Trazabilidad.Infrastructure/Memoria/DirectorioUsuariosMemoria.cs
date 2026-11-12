using System.Security.Cryptography;
using System.Text;
using Trazabilidad.Application;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class DirectorioUsuariosMemoria : IDirectorioUsuarios, ICatalogoServidores, IConsultaServidoresApi
{
    private readonly UsuarioAutenticado _usuario;
    private readonly byte[] _contrasena;

    public DirectorioUsuariosMemoria()
    {
        _usuario = new UsuarioAutenticado(SemillaDesarrollo.Usuario, SemillaDesarrollo.Empresas);
        _contrasena = Encoding.UTF8.GetBytes(SemillaDesarrollo.Contrasena);
    }

    public Task<IReadOnlyList<ServidorPublico>> Listar(CancellationToken cancelacion) =>
        Task.FromResult<IReadOnlyList<ServidorPublico>>([new ServidorPublico("Desarrollo")]);

    public Task<IReadOnlyList<ServidorApi>> Listar(
        string token,
        string servidor,
        CancellationToken cancelacion) =>
        Task.FromResult<IReadOnlyList<ServidorApi>>(SemillaDesarrollo.Servidores);

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
}
