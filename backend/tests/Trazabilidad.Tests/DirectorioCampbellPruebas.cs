using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Trazabilidad.Infrastructure.SistemaActual;

namespace Trazabilidad.Tests;

public class DirectorioCampbellPruebas
{
    [Fact]
    public async Task Debe_publicar_solo_el_nombre_del_servidor()
    {
        var controlador = new Controlador(solicitud =>
        {
            Assert.EndsWith("/api/Usuarios/obtener-servidores", solicitud.RequestUri?.AbsolutePath, StringComparison.Ordinal);
            return Json(HttpStatusCode.OK, new[]
            {
                new
                {
                    Ip_Conexion = "10.0.0.8",
                    Descripcion = "Campbell",
                    Puerto = 3306,
                    BaseDatos = "bd",
                    Usuario = "cuenta",
                    Clave = "secreto",
                },
            });
        });
        var directorio = Directorio(controlador);

        var servidores = await directorio.Listar(CancellationToken.None);

        var unico = Assert.Single(servidores);
        Assert.Equal("Campbell", unico.Nombre);
    }

    [Fact]
    public async Task Debe_entrar_con_el_token_y_las_empresas_del_usuario()
    {
        var controlador = new Controlador(solicitud =>
        {
            var ruta = solicitud.RequestUri?.AbsolutePath ?? "";
            if (ruta.EndsWith("/api/Usuarios/obtener-servidores", StringComparison.Ordinal))
            {
                return Json(HttpStatusCode.OK, new[]
                {
                    new
                    {
                        Ip_Conexion = "10.0.0.8",
                        Descripcion = "Campbell",
                        Puerto = 3306,
                        BaseDatos = "bd",
                        Usuario = "cuenta",
                        Clave = "secreto",
                    },
                });
            }

            if (ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal))
            {
                return Json(HttpStatusCode.OK, new { token = "token-campbell" });
            }

            Assert.EndsWith("/api/Usuarios/obtener-ApiListaEmpresas", ruta, StringComparison.Ordinal);
            Assert.Equal("Bearer", solicitud.Headers.Authorization?.Scheme);
            Assert.Equal("token-campbell", solicitud.Headers.Authorization?.Parameter);
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
            if (ruta.EndsWith("/api/Usuarios/obtener-servidores", StringComparison.Ordinal))
            {
                return Json(HttpStatusCode.OK, new[]
                {
                    new
                    {
                        Ip_Conexion = "10.0.0.8",
                        Descripcion = "Campbell",
                        Puerto = 3306,
                        BaseDatos = "bd",
                        Usuario = "cuenta",
                        Clave = "secreto",
                    },
                });
            }

            if (ruta.EndsWith("/api/authtoken/tokenjwt", StringComparison.Ordinal))
                return Json(HttpStatusCode.OK, new { token = "token-campbell" });

            return new HttpResponseMessage(HttpStatusCode.Unauthorized);
        });
        var directorio = Directorio(controlador);

        var usuario = await directorio.Autenticar("ana", "clave", "Campbell", CancellationToken.None);

        Assert.Null(usuario);
    }

    private static DirectorioCampbell Directorio(Controlador controlador)
    {
        var cliente = new HttpClient(controlador) { BaseAddress = new Uri("http://campbell.local/") };
        return new DirectorioCampbell(cliente);
    }

    private static HttpResponseMessage Json(HttpStatusCode estado, object cuerpo) =>
        new(estado) { Content = JsonContent.Create(cuerpo, options: new JsonSerializerOptions { PropertyNamingPolicy = null }) };

    private sealed class Controlador : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _responder;

        public Controlador(Func<HttpRequestMessage, HttpResponseMessage> responder)
        {
            _responder = responder;
        }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) =>
            Task.FromResult(_responder(request));
    }
}
