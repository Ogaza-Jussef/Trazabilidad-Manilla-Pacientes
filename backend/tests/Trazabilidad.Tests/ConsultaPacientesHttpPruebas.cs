using System.Net;
using System.Net.Http.Json;
using Trazabilidad.Infrastructure.SistemaActual;

namespace Trazabilidad.Tests;

public class ConsultaPacientesHttpPruebas
{
    [Fact]
    public async Task Debe_leer_nombre_apellido_e_identificacion()
    {
        var controlador = new ControladorFalso(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = JsonContent.Create(new
            {
                numeroIdentificacion = "10000001",
                nombre = "Ana",
                apellido = "Perez",
                edad = 40,
            }),
        });
        var consulta = new ConsultaPacientesHttp(new HttpClient(controlador)
        {
            BaseAddress = new Uri("http://sistema.local/"),
        });

        var paciente = await consulta.Obtener("C30", "100001", CancellationToken.None);

        Assert.NotNull(paciente);
        Assert.Equal("Ana", paciente!.Nombre);
        Assert.Equal("Perez", paciente.Apellido);
        Assert.Equal("10000001", paciente.NumeroIdentificacion);
        Assert.Contains("codigoEmpresa=C30", controlador.UltimaRuta, StringComparison.Ordinal);
        Assert.Contains("numeroCaso=100001", controlador.UltimaRuta, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Debe_devolver_null_cuando_el_sistema_responde_404()
    {
        var consulta = new ConsultaPacientesHttp(new HttpClient(new ControladorFalso(_ =>
            new HttpResponseMessage(HttpStatusCode.NotFound)))
        {
            BaseAddress = new Uri("http://sistema.local/"),
        });

        var paciente = await consulta.Obtener("C30", "999999", CancellationToken.None);

        Assert.Null(paciente);
    }

    private sealed class ControladorFalso : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _responder;

        public ControladorFalso(Func<HttpRequestMessage, HttpResponseMessage> responder)
        {
            _responder = responder;
        }

        public string UltimaRuta { get; private set; } = "";

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            UltimaRuta = request.RequestUri?.ToString() ?? "";
            return Task.FromResult(_responder(request));
        }
    }
}
