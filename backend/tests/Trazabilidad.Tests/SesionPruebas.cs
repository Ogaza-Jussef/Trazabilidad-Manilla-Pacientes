using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace Trazabilidad.Tests;

public class SesionPruebas
{
    [Fact]
    public async Task Debe_devolver_las_empresas_del_usuario()
    {
        await using var fabrica = new FabricaApi();
        using var cliente = fabrica.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync("/api/v1/sesiones", new
        {
            usuario = "operador",
            contrasena = "operador",
        });

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var json = await Leer(respuesta);
        Assert.Equal("operador", json.GetProperty("usuario").GetString());
        Assert.False(string.IsNullOrWhiteSpace(json.GetProperty("token").GetString()));
        Assert.Equal(2, json.GetProperty("empresas").GetArrayLength());
        Assert.Equal("C30", json.GetProperty("empresas")[0].GetProperty("codigo").GetString());
    }

    [Fact]
    public async Task Debe_rechazar_una_contrasena_incorrecta()
    {
        await using var fabrica = new FabricaApi();
        using var cliente = fabrica.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync("/api/v1/sesiones", new
        {
            usuario = "operador",
            contrasena = "otra",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
        Assert.Equal("unauthenticated", (await Leer(respuesta)).GetProperty("error").GetProperty("code").GetString());
    }

    [Fact]
    public async Task Debe_impedir_consultar_una_empresa_no_asociada()
    {
        await using var fabrica = new FabricaApi();
        using var cliente = fabrica.CreateClient();
        var ingreso = await cliente.PostAsJsonAsync("/api/v1/sesiones", new
        {
            usuario = "operador",
            contrasena = "operador",
        });
        var token = (await Leer(ingreso)).GetProperty("token").GetString();

        var solicitud = new HttpRequestMessage(HttpMethod.Get, "/api/v1/pacientes?codigoQr=C30-100001");
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        solicitud.Headers.TryAddWithoutValidation("X-Codigo-Empresa", "C99");
        var respuesta = await cliente.SendAsync(solicitud);

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    private static async Task<JsonElement> Leer(HttpResponseMessage respuesta)
    {
        using var documento = await JsonDocument.ParseAsync(await respuesta.Content.ReadAsStreamAsync());
        return documento.RootElement.Clone();
    }
}
