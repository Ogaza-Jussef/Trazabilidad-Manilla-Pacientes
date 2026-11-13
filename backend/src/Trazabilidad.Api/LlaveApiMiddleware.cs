using System.Security.Cryptography;
using System.Text;
using Trazabilidad.Application;

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
    private readonly IAlmacenSesiones _sesiones;

    public LlaveApiMiddleware(RequestDelegate siguiente, OpcionesSeguridad opciones, IAlmacenSesiones sesiones)
    {
        _siguiente = siguiente;
        _opciones = opciones;
        _sesiones = sesiones;
    }

    public async Task InvokeAsync(HttpContext contexto)
    {
        if (EsPublica(contexto))
        {
            await _siguiente(contexto);
            return;
        }

        var encabezado = contexto.Request.Headers.Authorization.ToString();
        const string prefijo = "Bearer ";
        if (!encabezado.StartsWith(prefijo, StringComparison.Ordinal))
        {
            await NoAutenticado(contexto);
            return;
        }

        var token = encabezado[prefijo.Length..];
        var sesion = _sesiones.Obtener(token);
        if (sesion is not null)
        {
            contexto.Items["Sesion"] = sesion;
            if (RequiereEmpresa(contexto) && !EmpresaPermitida(contexto, sesion))
            {
                await ResultadosError.Crear(
                        contexto,
                        StatusCodes.Status403Forbidden,
                        "forbidden",
                        "Este usuario no tiene esa empresa asociada.")
                    .ExecuteAsync(contexto);
                return;
            }

            await _siguiente(contexto);
            return;
        }

        if (!ClavesIguales(token, _opciones.ClaveApi))
        {
            await NoAutenticado(contexto);
            return;
        }

        await _siguiente(contexto);
    }

    private static bool EsPublica(HttpContext contexto)
    {
        if (RutasPublicas.Contains(contexto.Request.Path.Value, StringComparer.OrdinalIgnoreCase))
            return true;

        if (!HttpMethods.IsPost(contexto.Request.Method))
            return false;

        return string.Equals(contexto.Request.Path.Value, "/api/v1/sesiones", StringComparison.OrdinalIgnoreCase)
            || string.Equals(contexto.Request.Path.Value, "/api/v1/servidores", StringComparison.OrdinalIgnoreCase);
    }

    private static bool RequiereEmpresa(HttpContext contexto)
    {
        var ruta = contexto.Request.Path.Value ?? "";
        return ruta.StartsWith("/api/v1/pacientes", StringComparison.OrdinalIgnoreCase)
            || ruta.StartsWith("/api/v1/trazabilidad", StringComparison.OrdinalIgnoreCase);
    }

    private static bool EmpresaPermitida(HttpContext contexto, SesionActiva sesion)
    {
        var codigo = contexto.Request.Headers["X-Codigo-Empresa"].ToString().Trim();
        return codigo.Length > 0 && sesion.Empresas.Any(empresa => empresa.Codigo == codigo);
    }

    private static Task NoAutenticado(HttpContext contexto) =>
        ResultadosError.Crear(
                contexto,
                StatusCodes.Status401Unauthorized,
                "unauthenticated",
                "Falta la clave de acceso.")
            .ExecuteAsync(contexto);

    private static bool ClavesIguales(string recibida, string esperada)
    {
        if (recibida.Length == 0 || esperada.Length == 0)
            return false;

        var izquierda = Encoding.UTF8.GetBytes(recibida);
        var derecha = Encoding.UTF8.GetBytes(esperada);
        return izquierda.Length == derecha.Length
            && CryptographicOperations.FixedTimeEquals(izquierda, derecha);
    }
}
