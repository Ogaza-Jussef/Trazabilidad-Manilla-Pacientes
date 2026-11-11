using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Hosting;
using Trazabilidad.Domain;

namespace Trazabilidad.Tests;

public sealed class FabricaApi : WebApplicationFactory<Program>
{
    public string Almacen { get; init; } = "memoria";

    protected override IHost CreateHost(IHostBuilder builder)
    {
        Environment.SetEnvironmentVariable("TRAZABILIDAD_API_KEY", "test-key");
        Environment.SetEnvironmentVariable("Almacen", Almacen);
        Environment.SetEnvironmentVariable("SistemaActual__BaseUrl", "");
        Environment.SetEnvironmentVariable("Campbell__BaseUrl", "");
        Environment.SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Development");
        return base.CreateHost(builder);
    }
}

public class ApiTrazabilidadPruebas
{
    [Fact]
    public async Task Debe_responder_salud_sin_clave()
    {
        await using var fabrica = new FabricaApi();
        using var cliente = fabrica.CreateClient();

        var viva = await cliente.GetAsync("/health");
        var lista = await cliente.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, viva.StatusCode);
        Assert.Equal(HttpStatusCode.OK, lista.StatusCode);
        Assert.Equal("memoria", (await Json(lista)).GetProperty("database").GetString());
    }

    [Fact]
    public async Task Debe_rechazar_la_lectura_sin_clave()
    {
        await using var fabrica = new FabricaApi();
        using var cliente = fabrica.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync("/api/v1/trazabilidad", new
        {
            codigoQr = "C30-100001",
            servicio = ServiciosLectura.Orden[0].Nombre,
        });

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
        Assert.Equal("unauthenticated", await Codigo(respuesta));
    }

    [Fact]
    public async Task Debe_consultar_el_paciente_de_desarrollo()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        var respuesta = await Get(cliente, "/api/v1/pacientes?codigoQr=c30-100001");

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var json = await Json(respuesta);
        Assert.Equal("C30", json.GetProperty("codigoEmpresa").GetString());
        Assert.Equal("100001", json.GetProperty("numeroCaso").GetString());
        Assert.Equal("10000001", json.GetProperty("numeroIdentificacion").GetString());
        Assert.Equal("Ana", json.GetProperty("nombre").GetString());
        Assert.Equal("Perez", json.GetProperty("apellido").GetString());
    }

    [Fact]
    public async Task Debe_responder_404_si_el_caso_no_existe()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        var respuesta = await Get(cliente, "/api/v1/pacientes?codigoQr=C30-999999");

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        Assert.Equal("not_found", await Codigo(respuesta));
    }

    [Fact]
    public async Task Debe_registrar_la_colocacion_y_conservar_la_hora_si_se_repite()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;
        var servicio = ServiciosLectura.Orden[0].Nombre;

        var primera = await Post(cliente, "C30-100001", servicio);
        var segunda = await Post(cliente, "C30-100001", servicio);

        Assert.Equal(HttpStatusCode.Created, primera.StatusCode);
        Assert.Equal(HttpStatusCode.OK, segunda.StatusCode);
        Assert.Equal("true", segunda.Headers.GetValues("X-Idempotent-Replay").Single());

        var creada = await Json(primera);
        var repetida = await Json(segunda);
        Assert.Equal(creada.GetProperty("id").GetInt64(), repetida.GetProperty("id").GetInt64());
        Assert.Equal(creada.GetProperty("fechaHoraCaptura").GetString(), repetida.GetProperty("fechaHoraCaptura").GetString());
        Assert.Equal("100001", creada.GetProperty("numeroCaso").GetString());
        Assert.Equal(servicio, creada.GetProperty("servicio").GetString());
        Assert.Matches(@"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$", creada.GetProperty("fechaHoraCaptura").GetString());
    }

    [Fact]
    public async Task Debe_rechazar_un_paso_si_falta_el_anterior()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        var respuesta = await Post(cliente, "C30-100001", ServiciosLectura.Orden[1].Nombre);

        var cuerpo = await Json(respuesta);
        Assert.Equal(HttpStatusCode.Conflict, respuesta.StatusCode);
        Assert.Equal("conflict", cuerpo.GetProperty("error").GetProperty("code").GetString());
        Assert.Contains("Colocación de manilla", cuerpo.GetProperty("error").GetProperty("message").GetString());
    }

    [Fact]
    public async Task Debe_rechazar_la_impresion_y_un_qr_invalido()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        var impresion = await Post(cliente, "C30-100001", ServiciosLectura.Impresion, ServiciosLectura.Impresion);
        var qr = await Post(cliente, "926067", ServiciosLectura.Orden[0].Nombre);

        Assert.Equal(HttpStatusCode.BadRequest, impresion.StatusCode);
        Assert.Equal("validation_error", await Codigo(impresion));
        Assert.Equal(HttpStatusCode.BadRequest, qr.StatusCode);
    }

    [Fact]
    public async Task Debe_prohibir_un_puesto_que_registra_otro_servicio()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        var respuesta = await Post(
            cliente,
            "C30-100001",
            ServiciosLectura.Orden[0].Nombre,
            ServiciosLectura.Orden[1].Nombre);

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
        Assert.Equal("forbidden", await Codigo(respuesta));
    }

    [Fact]
    public async Task Debe_recorrer_el_flujo_y_paginar_las_lecturas()
    {
        using var sesion = Abrir();
        var cliente = sesion.Cliente;

        foreach (var servicio in ServiciosLectura.Orden)
        {
            var creada = await Post(cliente, "C30-100001", servicio.Nombre);
            Assert.Equal(HttpStatusCode.Created, creada.StatusCode);
        }

        var primera = await Get(cliente, "/api/v1/trazabilidad?numeroCaso=100001&limit=2");
        var pagina = await Json(primera);
        Assert.Equal(2, pagina.GetProperty("items").GetArrayLength());
        Assert.Equal(2, pagina.GetProperty("limit").GetInt32());
        var cursor = pagina.GetProperty("nextCursor").GetString();
        Assert.False(string.IsNullOrWhiteSpace(cursor));

        var segunda = await Get(cliente, "/api/v1/trazabilidad?numeroCaso=100001&limit=2&cursor=" + Uri.EscapeDataString(cursor!));
        Assert.Equal(HttpStatusCode.OK, segunda.StatusCode);
        Assert.Equal(2, (await Json(segunda)).GetProperty("items").GetArrayLength());
    }

    [Fact]
    public async Task Debe_marcar_la_base_como_pendiente_cuando_el_almacen_es_mysql()
    {
        await using var fabrica = new FabricaApi { Almacen = "mysql" };
        using var cliente = fabrica.CreateClient();

        var lista = await cliente.GetAsync("/health/ready");
        var lectura = await Post(cliente, "C30-100001", ServiciosLectura.Orden[0].Nombre);

        var textoLista = await lista.Content.ReadAsStringAsync();
        var textoLectura = await lectura.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.ServiceUnavailable, lista.StatusCode);
        Assert.Equal("pending", JsonDocument.Parse(textoLista).RootElement.GetProperty("database").GetString());
        Assert.Equal(HttpStatusCode.ServiceUnavailable, lectura.StatusCode);
        Assert.Equal(
            "dependency_unavailable",
            JsonDocument.Parse(textoLectura).RootElement.GetProperty("error").GetProperty("code").GetString());
        Assert.DoesNotContain("exception", textoLectura, StringComparison.OrdinalIgnoreCase);
    }

    private static Sesion Abrir()
    {
        var fabrica = new FabricaApi();
        var cliente = fabrica.CreateClient();
        return new Sesion(fabrica, cliente);
    }

    private static Task<HttpResponseMessage> Get(HttpClient cliente, string ruta)
    {
        var solicitud = new HttpRequestMessage(HttpMethod.Get, ruta);
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", "test-key");
        return cliente.SendAsync(solicitud);
    }

    private static Task<HttpResponseMessage> Post(
        HttpClient cliente,
        string codigoQr,
        string servicio,
        string? puesto = null)
    {
        var solicitud = new HttpRequestMessage(HttpMethod.Post, "/api/v1/trazabilidad");
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", "test-key");
        solicitud.Headers.TryAddWithoutValidation("X-Servicio-Puesto", puesto ?? servicio);
        solicitud.Content = new StringContent(
            JsonSerializer.Serialize(new { codigoQr, servicio }),
            Encoding.UTF8,
            "application/json");
        return cliente.SendAsync(solicitud);
    }

    private sealed class Sesion : IDisposable
    {
        public Sesion(FabricaApi fabrica, HttpClient cliente)
        {
            Fabrica = fabrica;
            Cliente = cliente;
        }

        public FabricaApi Fabrica { get; }

        public HttpClient Cliente { get; }

        public void Dispose()
        {
            Cliente.Dispose();
            Fabrica.Dispose();
        }
    }

    private static async Task<JsonElement> Json(HttpResponseMessage respuesta)
    {
        using var documento = await JsonDocument.ParseAsync(await respuesta.Content.ReadAsStreamAsync());
        return documento.RootElement.Clone();
    }

    private static async Task<string?> Codigo(HttpResponseMessage respuesta) =>
        (await Json(respuesta)).GetProperty("error").GetProperty("code").GetString();
}
