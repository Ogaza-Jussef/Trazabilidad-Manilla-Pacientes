using System.Diagnostics;
using Microsoft.AspNetCore.Routing;

namespace Trazabilidad.Api;

public sealed class RegistroSolicitudMiddleware
{
    private readonly RequestDelegate _siguiente;
    private readonly ILogger<RegistroSolicitudMiddleware> _log;

    public RegistroSolicitudMiddleware(RequestDelegate siguiente, ILogger<RegistroSolicitudMiddleware> log)
    {
        _siguiente = siguiente;
        _log = log;
    }

    public async Task InvokeAsync(HttpContext contexto)
    {
        var requestId = contexto.Request.Headers["X-Request-Id"].FirstOrDefault();
        if (requestId is null || !EsIdSeguro(requestId))
            requestId = Guid.NewGuid().ToString("n");

        contexto.Items["RequestId"] = requestId;
        contexto.Response.Headers["X-Request-Id"] = requestId;
        contexto.Response.Headers["Cache-Control"] = "no-store";

        var reloj = Stopwatch.StartNew();
        await _siguiente(contexto);
        reloj.Stop();

        var ruta = (contexto.GetEndpoint() as RouteEndpoint)?.RoutePattern.RawText ?? "unknown";
        _log.LogInformation(
            "http_request {Method} {Route} {Status} {DurationMs} {RequestId}",
            contexto.Request.Method,
            ruta,
            contexto.Response.StatusCode,
            reloj.ElapsedMilliseconds,
            requestId);
    }

    private static bool EsIdSeguro(string valor) =>
        valor.Length is > 0 and <= 64
        && valor.All(caracter => char.IsAsciiLetterOrDigit(caracter) || caracter is '-' or '_');
}
