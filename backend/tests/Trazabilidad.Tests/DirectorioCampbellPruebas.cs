using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Trazabilidad.Domain;
using Trazabilidad.Infrastructure.SistemaActual;

namespace Trazabilidad.Tests;

public class DirectorioCampbellPruebas
{
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
                Assert.Equal("catalogo", cuerpo.GetProperty("Ip_Conexion").GetString());
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
        Assert.Equal("token-sede", usuario.TokenConexion);
    }

    [Fact]
    public async Task Debe_pedir_los_servicios_de_la_empresa_con_el_token_de_la_sede()
    {
        var controlador = new Controlador(async solicitud =>
        {
            Assert.EndsWith("/api/Usuarios/obtener-ApiTrzServiciosManilla", solicitud.RequestUri?.AbsolutePath, StringComparison.Ordinal);
            Assert.Equal("Bearer", solicitud.Headers.Authorization?.Scheme);
            Assert.Equal("token-sede", solicitud.Headers.Authorization?.Parameter);
            var cuerpo = await LeerCuerpo(solicitud);
            Assert.Equal("C30", cuerpo.GetProperty("Empresa").GetString());
            Assert.Equal("ana", cuerpo.GetProperty("Usuario").GetString());
            return Json(HttpStatusCode.OK, new[]
            {
                new { Id_Servicio = "2", Descripcion = "Colocación de manilla" },
                new { Id_Servicio = "3", Descripcion = "Paso a Qx" },
            });
        });
        var directorio = Directorio(controlador);

        var servicios = await directorio.Listar("token-sede", "ana", "C30", CancellationToken.None);

        Assert.Equal(["Colocación de manilla", "Paso a Qx"], servicios.Select(servicio => servicio.Nombre).ToArray());
    }

    [Fact]
    public async Task Debe_avisar_si_campbell_no_puede_listar_los_servicios()
    {
        var controlador = new Controlador(_ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.InternalServerError)));
        var directorio = Directorio(controlador);

        var error = await Assert.ThrowsAsync<ErrorDependencia>(
            () => directorio.Listar("token-sede", "ana", "C30", CancellationToken.None));

        Assert.Equal("No se pudieron consultar los servicios del usuario.", error.Message);
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

    [Fact]
    public async Task Debe_registrar_la_captura_del_qr_con_el_token_de_la_sede()
    {
        var controlador = new Controlador(async solicitud =>
        {
            Assert.EndsWith("/api/Usuarios/ApiRegistrar-TrzManillasPaciente", solicitud.RequestUri?.AbsolutePath, StringComparison.Ordinal);
            Assert.Equal(HttpMethod.Post, solicitud.Method);
            Assert.Equal("Bearer", solicitud.Headers.Authorization?.Scheme);
            Assert.Equal("token-sede", solicitud.Headers.Authorization?.Parameter);
            var cuerpo = await LeerCuerpo(solicitud);
            Assert.Equal("C30", cuerpo.GetProperty("Empresa").GetString());
            Assert.Equal("IQX", cuerpo.GetProperty("Id_Servicio").GetString());
            Assert.Equal("926667", cuerpo.GetProperty("NoCuenta").GetString());
            Assert.Equal("2026-11-13 15:21:00", cuerpo.GetProperty("fecha_hora_captura").GetString());
            Assert.Equal("jogaza", cuerpo.GetProperty("Usuario").GetString());
            return Json(HttpStatusCode.OK, new { Mensaje = "Manilla de Paciente registrado correctamente." });
        });
        var directorio = Directorio(controlador);

        await directorio.Registrar(
            "token-sede",
            "C30",
            "IQX",
            "926667",
            new DateTime(2026, 11, 13, 15, 21, 0),
            "jogaza",
            CancellationToken.None);
    }

    [Fact]
    public async Task Debe_avisar_si_campbell_no_puede_registrar_la_captura()
    {
        var controlador = new Controlador(_ =>
            Task.FromResult(Json(HttpStatusCode.InternalServerError, new { Message = "Error." })));
        var directorio = Directorio(controlador);

        var error = await Assert.ThrowsAsync<ErrorDependencia>(() => directorio.Registrar(
            "token-sede",
            "C30",
            "IQX",
            "926667",
            new DateTime(2026, 11, 13, 15, 21, 0),
            "jogaza",
            CancellationToken.None));

        Assert.Equal("Error.", error.Message);
    }

    private static DirectorioCampbell Directorio(Controlador controlador)
    {
        var cliente = new HttpClient(controlador) { BaseAddress = new Uri("http://campbell.local/") };
        return new DirectorioCampbell(cliente);
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
