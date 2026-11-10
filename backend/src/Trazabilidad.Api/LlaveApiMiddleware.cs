using System.Security.Cryptography;
using System.Text;

namespace Trazabilidad.Api;

public sealed class OpcionesSeguridad
{
    public OpcionesSeguridad(string claveApi)
    {
        ClaveApi = claveApi;
    }

    public string ClaveApi { get; }
}

public sealed class LlaveApiMiddleware
{
    private static readonly string[] RutasPublicas = ["/health", "/health/ready"];
    private readonly RequestDelegate _siguiente;
    private readonly OpcionesSeguridad _opciones;

    public LlaveApiMiddleware(RequestDelegate siguiente, OpcionesSeguridad opciones)
    {
        _siguiente = siguiente;
        _opciones = opciones;
    }

    public async Task InvokeAsync(HttpContext contexto)
    {
        if (RutasPublicas.Contains(contexto.Request.Path.Value, StringComparer.OrdinalIgnoreCase))
        {
            await _siguiente(contexto);
            return;
        }

        var encabezado = contexto.Request.Headers.Authorization.ToString();
        const string prefijo = "Bearer ";
        if (!encabezado.StartsWith(prefijo, StringComparison.Ordinal)
            || !ClavesIguales(encabezado[prefijo.Length..], _opciones.ClaveApi))
        {
            await ResultadosError.Crear(
                    contexto,
                    StatusCodes.Status401Unauthorized,
                    "unauthenticated",
                    "Falta la clave de acceso.")
                .ExecuteAsync(contexto);
            return;
        }

        await _siguiente(contexto);
    }

    private static bool ClavesIguales(string recibida, string esperada)
    {
        var izquierda = Encoding.UTF8.GetBytes(recibida);
        var derecha = Encoding.UTF8.GetBytes(esperada);
        return izquierda.Length == derecha.Length
            && CryptographicOperations.FixedTimeEquals(izquierda, derecha);
    }
}
