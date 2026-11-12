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

app.UseMiddleware<RegistroSolicitudMiddleware>();
app.UseMiddleware<ManejadorErroresMiddleware>();
app.Use((contexto, siguiente) =>
{
    if (HttpMethods.IsOptions(contexto.Request.Method))
    {
        AgregarCors(contexto);
        return Task.CompletedTask;
    }

    return siguiente();
});

app.UseMiddleware<LlaveApiMiddleware>();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapGet("/health/ready", (IConfiguration configuracion) =>
{
    var mysql = string.Equals(configuracion["Almacen"], "mysql", StringComparison.OrdinalIgnoreCase);
    if (mysql)
        return Results.Json(new { status = "pending", database = "pending" }, statusCode: StatusCodes.Status503ServiceUnavailable);

    return Results.Ok(new { status = "ok", database = "memoria" });
});

RutasTrazabilidad.Map(app);

app.Use((contexto, siguiente) =>
{
    AgregarCors(contexto);
    return siguiente();
});

app.Run();

static void AgregarCors(HttpContext contexto)
{
    contexto.Response.Headers.AccessControlAllowOrigin = contexto.Request.Headers.Origin.Count > 0
        ? contexto.Request.Headers.Origin[0]!
        : "*";
    contexto.Response.Headers.AccessControlAllowHeaders = "*";
    contexto.Response.Headers.AccessControlAllowMethods = "*";
}

public partial class Program
{
}
