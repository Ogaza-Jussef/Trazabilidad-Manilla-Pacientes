using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class DirectorioCampbell : IDirectorioUsuarios, ICatalogoServidores
{
    private readonly HttpClient _cliente;

    public DirectorioCampbell(HttpClient cliente)
    {
        _cliente = cliente;
    }

    private static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = null,
        PropertyNameCaseInsensitive = true,
    };

    public async Task<IReadOnlyList<ServidorPublico>> Listar(CancellationToken cancelacion)
    {
        var servidores = await ObtenerServidores(cancelacion);
        return servidores
            .Select(servidor => servidor.Descripcion.Trim())
            .Where(nombre => nombre.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(nombre => nombre, StringComparer.OrdinalIgnoreCase)
            .Select(nombre => new ServidorPublico(nombre))
            .ToArray();
    }

    public async Task<UsuarioAutenticado?> Autenticar(
        string usuario,
        string contrasena,
        string servidor,
        CancellationToken cancelacion)
    {
        var sede = (await ObtenerServidores(cancelacion))
            .FirstOrDefault(item => string.Equals(item.Descripcion.Trim(), servidor, StringComparison.OrdinalIgnoreCase));
        if (sede is null)
            return null;

        var token = await PedirToken(_cliente, sede, usuario, contrasena, cancelacion);
        if (token.Length == 0)
            return null;

        var empresas = await PedirEmpresas(_cliente, sede.IpConexion, usuario, contrasena, token, cancelacion);
        if (empresas.Count == 0)
            return null;

        return new UsuarioAutenticado(usuario, empresas);
    }

    private async Task<IReadOnlyList<ServidorCampbell>> ObtenerServidores(CancellationToken cancelacion)
    {
        using var respuesta = await _cliente.GetAsync("api/Usuarios/obtener-servidores", cancelacion);
        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("No se pudo obtener la lista de servidores.");

        List<ServidorCampbellDto>? lista;
        try
        {
            lista = await respuesta.Content.ReadFromJsonAsync<List<ServidorCampbellDto>>(Json, cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("La lista de servidores no se pudo leer.");
        }

        if (lista is null)
            throw new ErrorDependencia("La lista de servidores no se pudo leer.");

        return lista
            .Where(item => !string.IsNullOrWhiteSpace(item.Descripcion) && !string.IsNullOrWhiteSpace(item.Ip_Conexion))
            .Select(item => new ServidorCampbell(
                item.Ip_Conexion!.Trim(),
                item.Descripcion!.Trim(),
                item.Puerto,
                item.BaseDatos?.Trim() ?? "",
                item.Usuario?.Trim() ?? "",
                item.Clave ?? ""))
            .Where(item => item.Puerto > 0 && item.BaseDatos.Length > 0 && item.UsuarioBd.Length > 0 && item.ClaveBd.Length > 0)
            .ToArray();
    }

    private static async Task<string> PedirToken(
        HttpClient cliente,
        ServidorCampbell sede,
        string usuario,
        string contrasena,
        CancellationToken cancelacion)
    {
        using var respuesta = await cliente.PostAsJsonAsync(
            "api/authtoken/tokenjwt",
            new LoginConexionDto
            {
                Username = usuario,
                PassWordUsu = contrasena,
                Ip_Conexion = sede.IpConexion,
                Puerto = sede.Puerto,
                BaseDatos = sede.BaseDatos,
                Usuario = sede.UsuarioBd,
                Clave = sede.ClaveBd,
            },
            Json,
            cancelacion);

        if (!respuesta.IsSuccessStatusCode)
            return "";

        TokenDto? token;
        try
        {
            token = await respuesta.Content.ReadFromJsonAsync<TokenDto>(Json, cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("La validación del usuario no se pudo leer.");
        }

        return token?.Token?.Trim() ?? "";
    }

    private static async Task<IReadOnlyList<Empresa>> PedirEmpresas(
        HttpClient cliente,
        string ip,
        string usuario,
        string contrasena,
        string token,
        CancellationToken cancelacion)
    {
        using var solicitud = new HttpRequestMessage(HttpMethod.Post, "api/Usuarios/obtener-ApiListaEmpresas")
        {
            Content = JsonContent.Create(
                new ListaEmpresasDto
                {
                    IpConexion = ip,
                    Usuario = usuario,
                    PasswordUsu = contrasena,
                },
                options: Json),
        };
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        using var respuesta = await cliente.SendAsync(solicitud, cancelacion);
        if (respuesta.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            return [];

        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("No se pudieron consultar las empresas del usuario.");

        List<EmpresaCampbellDto>? lista;
        try
        {
            lista = await respuesta.Content.ReadFromJsonAsync<List<EmpresaCampbellDto>>(Json, cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("La lista de empresas no se pudo leer.");
        }

        if (lista is null)
            throw new ErrorDependencia("La lista de empresas no se pudo leer.");

        return lista
            .Where(item => !string.IsNullOrWhiteSpace(item.Empresa))
            .Select(item =>
            {
                var codigo = item.Empresa!.Trim();
                var nombre = (item.Nombre_Empresa ?? "").Trim();
                if (nombre.Length == 0)
                    nombre = codigo;
                return new Empresa(codigo, nombre);
            })
            .Where(item => item.Codigo.Length is >= 1 and <= 10 && item.Nombre.Length <= 120)
            .DistinctBy(item => item.Codigo, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private sealed record ServidorCampbell(
        string IpConexion,
        string Descripcion,
        int Puerto,
        string BaseDatos,
        string UsuarioBd,
        string ClaveBd);

    private sealed class ServidorCampbellDto
    {
        public string? Ip_Conexion { get; set; }

        public string? Descripcion { get; set; }

        public int Puerto { get; set; }

        public string? BaseDatos { get; set; }

        public string? Usuario { get; set; }

        public string? Clave { get; set; }
    }

    private sealed class LoginConexionDto
    {
        public string Username { get; set; } = "";

        public string PassWordUsu { get; set; } = "";

        public string Nombre { get; set; } = "";

        public string Cedula { get; set; } = "";

        public string Ip_Conexion { get; set; } = "";

        public int Puerto { get; set; }

        public string BaseDatos { get; set; } = "";

        public string Usuario { get; set; } = "";

        public string Clave { get; set; } = "";

        public string Role { get; set; } = "";
    }

    private sealed class TokenDto
    {
        public string? Token { get; set; }
    }

    private sealed class ListaEmpresasDto
    {
        public string IpConexion { get; set; } = "";

        public string Usuario { get; set; } = "";

        public string PasswordUsu { get; set; } = "";
    }

    private sealed class EmpresaCampbellDto
    {
        public string? Empresa { get; set; }

        public string? Nombre_Empresa { get; set; }
    }
}
