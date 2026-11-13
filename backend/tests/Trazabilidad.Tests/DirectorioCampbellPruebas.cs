using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Trazabilidad.Domain;
using Trazabilidad.Infrastructure.SistemaActual;

namespace Trazabilidad.Tests;

public class DirectorioCampbellPruebas
{
    private const string IpInicial = "10.0.0.1";
    private const string IpSede = "10.0.0.8";

    [Fact]
    public async Task Debe_pedir_el_token_antes_de_listar_los_servidores()
    {
        var llamadas = new List<string>();
        var controlador = new Controlador(async solicitud =>
        {
            var ruta = solicitud.RequestUri?.AbsolutePath ?? "";
            llamadas.Add(ruta);
            if (ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal))
            {
                var cuerpo = await LeerCuerpo(solicitud);
                Assert.Equal(IpInicial, cuerpo.GetProperty("Ip_Conexion").GetString());
                Assert.Equal("ana", cuerpo.GetProperty("Username").GetString());
                Assert.Equal("clave", cuerpo.GetProperty("PassWordUsu").GetString());
                return Json(HttpStatusCode.OK, new { token = "token-inicial" });
            }

            Assert.EndsWith("/api/Usuarios/obtener-ApiServidores", ruta, StringComparison.Ordinal);
            Assert.Equal(HttpMethod.Get, solicitud.Method);
            Assert.Equal("Bearer", solicitud.Headers.Authorization?.Scheme);
            Assert.Equal("token-inicial", solicitud.Headers.Authorization?.Parameter);
            return Json(HttpStatusCode.OK, new[]
            {
                new { Ip_Conexion = IpSede, Descripcion = "Campbell" },
                new { Ip_Conexion = "10.0.0.9", Descripcion = "Bahia" },
            });
        });
        var directorio = Directorio(controlador);

        var servidores = await directorio.Listar("ana", "clave", CancellationToken.None);

        Assert.Equal(["Bahia", "Campbell"], servidores.Select(servidor => servidor.Nombre).ToArray());
        Assert.Equal(2, llamadas.Count);
        Assert.EndsWith("/api/authtoken/tokenjwt", llamadas[0], StringComparison.Ordinal);
    }

    [Fact]
    public async Task Debe_fallar_si_los_servidores_rechazan_el_token()
    {
        var controlador = new Controlador(solicitud =>
        {
            var ruta = solicitud.RequestUri?.AbsolutePath ?? "";
            return Task.FromResult(ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal)
                ? Json(HttpStatusCode.OK, new { token = "token-inicial" })
                : new HttpResponseMessage(HttpStatusCode.Unauthorized));
        });
        var directorio = Directorio(controlador);

        await Assert.ThrowsAsync<ErrorNoAutenticado>(
            () => directorio.Listar("ana", "clave", CancellationToken.None));
    }

    [Fact]
    public async Task Debe_entrar_con_el_token_de_la_sede_y_las_empresas_del_usuario()
    {
        var controlador = new Controlador(async solicitud =>
        {
            var ruta = solicitud.RequestUri?.AbsolutePath ?? "";
            if (ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal))
            {
                var ip = (await LeerCuerpo(solicitud)).GetProperty("Ip_Conexion").GetString();
                return Json(HttpStatusCode.OK, new { token = ip == IpSede ? "token-sede" : "token-inicial" });
            }

            if (ruta.EndsWith("/api/Usuarios/obtener-ApiServidores", StringComparison.Ordinal))
            {
                return Json(HttpStatusCode.OK, new[]
                {
                    new { Ip_Conexion = IpSede, Descripcion = "Campbell" },
                });
            }

            Assert.EndsWith("/api/Usuarios/obtener-ApiUsuariosxEmpresas", ruta, StringComparison.Ordinal);
            Assert.Equal("Bearer", solicitud.Headers.Authorization?.Scheme);
            Assert.Equal("token-sede", solicitud.Headers.Authorization?.Parameter);
            var cuerpo = await LeerCuerpo(solicitud);
            Assert.Equal(IpSede, cuerpo.GetProperty("IpConexion").GetString());
            Assert.Equal("ana", cuerpo.GetProperty("Usuario").GetString());
            Assert.Equal("clave", cuerpo.GetProperty("PasswordUsu").GetString());
            return Json(HttpStatusCode.OK, new[]
            {
                new { Empresa = "C30", Nombre_Empresa = "Fundacion Campbell" },
            });
        });
        var directorio = Directorio(controlador);

        var usuario = await directorio.Autenticar("ana", "clave", "Campbell", CancellationToken.None);

        Assert.NotNull(usuario);
        var empresa = Assert.Single(usuario!.Empresas);
        Assert.Equal("C30", empresa.Codigo);
        Assert.Equal("Fundacion Campbell", empresa.Nombre);
    }

    [Fact]
    public async Task Debe_rechazar_un_usuario_no_autorizado()
    {
        var controlador = new Controlador(solicitud =>
        {
            var ruta = solicitud.RequestUri?.AbsolutePath ?? "";
            if (ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal))
                return Task.FromResult(Json(HttpStatusCode.OK, new { token = "token-campbell" }));

            if (ruta.EndsWith("/api/Usuarios/obtener-ApiServidores", StringComparison.Ordinal))
            {
                return Task.FromResult(Json(HttpStatusCode.OK, new[]
                {
                    new { Ip_Conexion = IpSede, Descripcion = "Campbell" },
                }));
            }

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.Unauthorized));
        });
        var directorio = Directorio(controlador);

        var usuario = await directorio.Autenticar("ana", "clave", "Campbell", CancellationToken.None);

        Assert.Null(usuario);
    }

    private static DirectorioCampbell Directorio(Controlador controlador)
    {
        var cliente = new HttpClient(controlador) { BaseAddress = new Uri("http://campbell.local/") };
        return new DirectorioCampbell(cliente, new OpcionesCampbell(IpInicial));
    }

    private static async Task<JsonElement> LeerCuerpo(HttpRequestMessage solicitud)
    {
        var texto = await solicitud.Content!.ReadAsStringAsync();
        using var documento = JsonDocument.Parse(texto);
        return documento.RootElement.Clone();
    }

    private static HttpResponseMessage Json(HttpStatusCode estado, object cuerpo) =>
        new(estado) { Content = JsonContent.Create(cuerpo, options: new JsonSerializerOptions { PropertyNamingPolicy = null }) };

    private sealed class Controlador : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, Task<HttpResponseMessage>> _responder;

        public Controlador(Func<HttpRequestMessage, Task<HttpResponseMessage>> responder)
        {
            _responder = responder;
        }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) =>
            _responder(request);
    }
}
