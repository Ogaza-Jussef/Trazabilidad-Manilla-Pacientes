using Microsoft.AspNetCore.StaticFiles;
using Trazabilidad.Api;

var builder = WebApplication.CreateBuilder(args);

var clave = builder.Configuration["Trazabilidad:ApiKey"];
if (string.IsNullOrWhiteSpace(clave))
    clave = Environment.GetEnvironmentVariable("TRAZABILIDAD_API_KEY") ?? "";

builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole(opciones =>
{
    opciones.IncludeScopes = false;
    opciones.TimestampFormat = "yyyy-MM-ddTHH:mm:ss ";
});

builder.Services.AddSingleton(new OpcionesSeguridad(clave));
Composicion.Registrar(builder);

var app = builder.Build();

var tipos = new FileExtensionContentTypeProvider();
tipos.Mappings[".wasm"] = "application/wasm";
tipos.Mappings[".data"] = "application/octet-stream";
app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions { ContentTypeProvider = tipos });

app.UseWhen(EsLlamadaDeLaApi, rama =>
{
    rama.Use((contexto, siguiente) =>
    {
        if (HttpMethods.IsOptions(contexto.Request.Method))
        {
            AgregarCors(contexto);
            contexto.Response.StatusCode = StatusCodes.Status204NoContent;
            return Task.CompletedTask;
        }

        contexto.Response.OnStarting(() =>
        {
            AgregarCors(contexto);
            return Task.CompletedTask;
        });
        return siguiente();
    });
    rama.UseMiddleware<RegistroSolicitudMiddleware>();
    rama.UseMiddleware<ManejadorErroresMiddleware>();
    rama.UseMiddleware<LlaveApiMiddleware>();
});

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapGet("/health/ready", (IConfiguration configuracion) =>
{
    var mysql = string.Equals(configuracion["Almacen"], "mysql", StringComparison.OrdinalIgnoreCase);
    if (mysql)
        return Results.Json(new { status = "pending", database = "pending" }, statusCode: StatusCodes.Status503ServiceUnavailable);

    return Results.Ok(new { status = "ok", database = "memoria" });
});

RutasTrazabilidad.Map(app);
app.MapFallback(async contexto =>
{
    if (EsLlamadaDeLaApi(contexto))
    {
        contexto.Response.StatusCode = StatusCodes.Status404NotFound;
        return;
    }

    var raizWeb = app.Environment.WebRootPath;
    var pagina = raizWeb is null ? null : Path.Combine(raizWeb, "index.html");
    if (pagina is null || !File.Exists(pagina))
    {
        contexto.Response.StatusCode = StatusCodes.Status404NotFound;
        return;
    }

    contexto.Response.ContentType = "text/html; charset=utf-8";
    await contexto.Response.SendFileAsync(pagina);
});

app.Run();

static bool EsLlamadaDeLaApi(HttpContext contexto) =>
    contexto.Request.Path.StartsWithSegments("/api")
    || contexto.Request.Path.StartsWithSegments("/health");

static void AgregarCors(HttpContext contexto)
{
    var origen = contexto.Request.Headers.Origin.ToString();
    var pedidos = contexto.Request.Headers.AccessControlRequestHeaders.ToString();
    contexto.Response.Headers.AccessControlAllowOrigin = origen.Length > 0 ? origen : "*";
    contexto.Response.Headers.AccessControlAllowHeaders = pedidos.Length > 0
        ? pedidos
        : "Authorization, Content-Type, Accept, X-Codigo-Empresa, X-Servicio-Puesto";
    contexto.Response.Headers.AccessControlAllowMethods = "GET, POST, OPTIONS";
    contexto.Response.Headers.Vary = "Origin";
}

public partial class Program
{
}
