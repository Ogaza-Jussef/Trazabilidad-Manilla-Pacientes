using System.Security.Cryptography;
using System.Text;
using Trazabilidad.Application;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class DirectorioUsuariosMemoria : IDirectorioUsuarios
{
    private readonly UsuarioAutenticado _usuario;
    private readonly byte[] _contrasena;

    public DirectorioUsuariosMemoria()
    {
        _usuario = new UsuarioAutenticado(SemillaDesarrollo.Usuario, SemillaDesarrollo.Empresas);
        _contrasena = Encoding.UTF8.GetBytes(SemillaDesarrollo.Contrasena);
    }

    public Task<UsuarioAutenticado?> Autenticar(string usuario, string contrasena, CancellationToken cancelacion)
    {
        var nombre = Encoding.UTF8.GetBytes(usuario);
        var esperado = Encoding.UTF8.GetBytes(_usuario.Usuario);
        var clave = Encoding.UTF8.GetBytes(contrasena);
        var usuarioOk = nombre.Length == esperado.Length && CryptographicOperations.FixedTimeEquals(nombre, esperado);
        var claveOk = clave.Length == _contrasena.Length && CryptographicOperations.FixedTimeEquals(clave, _contrasena);
        return Task.FromResult(usuarioOk && claveOk ? _usuario : null);
    }
}
