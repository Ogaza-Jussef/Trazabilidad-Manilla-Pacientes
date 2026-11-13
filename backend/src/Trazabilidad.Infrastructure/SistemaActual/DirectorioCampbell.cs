using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class DirectorioCampbell : IDirectorioUsuarios, ICatalogoServidores, IServiciosManilla
{
    private static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = null,
        PropertyNameCaseInsensitive = true,
    };

    // Campbell exige Ip_Conexion para emitir el token. La lista no depende de ese valor:
    // el servidor del usuario, Campbell u otro, se toma de la lista al entrar.
    private const string AperturaCatalogo = "catalogo";

    private readonly HttpClient _cliente;

    public DirectorioCampbell(HttpClient cliente)
    {
        _cliente = cliente;
    }

    public async Task<IReadOnlyList<ServidorPublico>> Listar(
        string usuario,
        string contrasena,
        CancellationToken cancelacion)
    {
        var servidores = await ObtenerServidores(usuario, contrasena, cancelacion);
        return servidores
            .Select(servidor => servidor.Nombre)
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
        var sede = (await ObtenerServidores(usuario, contrasena, cancelacion))
            .FirstOrDefault(item => string.Equals(item.Nombre, servidor, StringComparison.OrdinalIgnoreCase));
        if (sede is null)
            return null;

        var token = await PedirToken(sede.Ip, usuario, contrasena, cancelacion);
        if (token.Length == 0)
            return null;

        var empresas = await PedirEmpresas(sede.Ip, usuario, contrasena, token, cancelacion);
        if (empresas.Count == 0)
            return null;

        return new UsuarioAutenticado(usuario, empresas, token);
    }

    public async Task<IReadOnlyList<ServicioManilla>> Listar(
        string tokenConexion,
        string usuario,
        string empresa,
        CancellationToken cancelacion)
    {
        if (string.IsNullOrWhiteSpace(tokenConexion))
            throw new ErrorNoAutenticado("No se pudo validar el usuario.");

        using var solicitud = new HttpRequestMessage(HttpMethod.Post, "api/Usuarios/obtener-ApiTrzServiciosManilla")
        {
            Content = JsonContent.Create(
                new ServiciosManillaRequestDto { Empresa = empresa, Usuario = usuario },
                options: Json),
        };
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokenConexion);

        using var respuesta = await _cliente.SendAsync(solicitud, cancelacion);
        if (respuesta.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            throw new ErrorNoAutenticado("No se pudo validar el usuario.");

        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("No se pudieron consultar los servicios del usuario.");

        string texto;
        try
        {
            texto = await respuesta.Content.ReadAsStringAsync(cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("La lista de servicios no se pudo leer.");
        }

        return LeerServicios(texto);
    }

    private static IReadOnlyList<ServicioManilla> LeerServicios(string texto)
    {
        JsonDocument documento;
        try
        {
            documento = JsonDocument.Parse(texto);
        }
        catch (JsonException)
        {
            throw new ErrorDependencia("La lista de servicios no se pudo leer.");
        }

        using (documento)
        {
            if (documento.RootElement.ValueKind != JsonValueKind.Array)
                throw new ErrorDependencia("La lista de servicios no se pudo leer.");

            var servicios = new List<ServicioManilla>();
            var vistos = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var item in documento.RootElement.EnumerateArray())
            {
                var nombre = NombreServicio(item);
                if (nombre.Length is < 1 or > 120 || !vistos.Add(nombre))
                    continue;
                servicios.Add(new ServicioManilla(nombre));
            }

            return servicios;
        }
    }

    private static string NombreServicio(JsonElement item)
    {
        if (item.ValueKind == JsonValueKind.String)
            return item.GetString()?.Trim() ?? "";

        if (item.ValueKind != JsonValueKind.Object)
            return "";

        foreach (var campo in new[] { "Descripcion", "Nombre", "Nombre_Servicio", "Servicio", "Id_Servicio" })
        {
            foreach (var propiedad in item.EnumerateObject())
            {
                if (!string.Equals(propiedad.Name, campo, StringComparison.OrdinalIgnoreCase))
                    continue;
                var texto = propiedad.Value.ValueKind switch
                {
                    JsonValueKind.String => propiedad.Value.GetString()?.Trim() ?? "",
                    JsonValueKind.Number => propiedad.Value.GetRawText(),
                    _ => "",
                };
                if (texto.Length > 0)
                    return texto;
            }
        }

        return "";
    }

    private async Task<IReadOnlyList<ServidorCampbell>> ObtenerServidores(
        string usuario,
        string contrasena,
        CancellationToken cancelacion)
    {
        var token = await PedirToken(AperturaCatalogo, usuario, contrasena, cancelacion);
        if (token.Length == 0)
            throw new ErrorNoAutenticado("No se pudo validar el usuario.");

        using var solicitud = new HttpRequestMessage(HttpMethod.Get, "api/Usuarios/obtener-ApiServidores");
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        using var respuesta = await _cliente.SendAsync(solicitud, cancelacion);
        if (respuesta.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            throw new ErrorNoAutenticado("No se pudo validar el usuario.");

        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("No se pudo obtener la lista de servidores.");

        List<ServidorDto>? lista;
        try
        {
            lista = await respuesta.Content.ReadFromJsonAsync<List<ServidorDto>>(Json, cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("La lista de servidores no se pudo leer.");
        }

        if (lista is null)
            throw new ErrorDependencia("La lista de servidores no se pudo leer.");

        return lista
            .Where(item => !string.IsNullOrWhiteSpace(item.Descripcion) && !string.IsNullOrWhiteSpace(item.Ip_Conexion))
            .Select(item => new ServidorCampbell(item.Ip_Conexion!.Trim(), item.Descripcion!.Trim()))
            .ToArray();
    }

    private async Task<string> PedirToken(
        string ip,
        string usuario,
        string contrasena,
        CancellationToken cancelacion)
    {
        using var respuesta = await _cliente.PostAsJsonAsync(
            "api/authtoken/tokenjwt",
            new TokenRequestDto
            {
                Ip_Conexion = ip,
                Username = usuario,
                PassWordUsu = contrasena,
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

    private async Task<IReadOnlyList<Empresa>> PedirEmpresas(
        string ip,
        string usuario,
        string contrasena,
        string token,
        CancellationToken cancelacion)
    {
        using var solicitud = new HttpRequestMessage(HttpMethod.Post, "api/Usuarios/obtener-ApiUsuariosxEmpresas")
        {
            Content = JsonContent.Create(
                new UsuarioEmpresasRequestDto
                {
                    IpConexion = ip,
                    Usuario = usuario,
                    PasswordUsu = contrasena,
                },
                options: Json),
        };
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        using var respuesta = await _cliente.SendAsync(solicitud, cancelacion);
        if (respuesta.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            return [];

        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("No se pudieron consultar las empresas del usuario.");

        List<EmpresaDto>? lista;
        try
        {
            lista = await respuesta.Content.ReadFromJsonAsync<List<EmpresaDto>>(Json, cancelacion);
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

    private sealed record ServidorCampbell(string Ip, string Nombre);

    private sealed class ServidorDto
    {
        public string? Ip_Conexion { get; set; }

        public string? Descripcion { get; set; }
    }

    private sealed class TokenRequestDto
    {
        public string Ip_Conexion { get; set; } = "";

        public string Username { get; set; } = "";

        public string PassWordUsu { get; set; } = "";
    }

    private sealed class TokenDto
    {
        public string? Token { get; set; }
    }

    private sealed class UsuarioEmpresasRequestDto
    {
        public string IpConexion { get; set; } = "";

        public string Usuario { get; set; } = "";

        public string PasswordUsu { get; set; } = "";
    }

    private sealed class ServiciosManillaRequestDto
    {
        public string Empresa { get; set; } = "";

        public string Usuario { get; set; } = "";
    }

    private sealed class EmpresaDto
    {
        public string? Empresa { get; set; }

        public string? Nombre_Empresa { get; set; }
    }
}
