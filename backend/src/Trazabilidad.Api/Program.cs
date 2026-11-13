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

app.Use((contexto, siguiente) =>
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
app.UseMiddleware<RegistroSolicitudMiddleware>();
app.UseMiddleware<ManejadorErroresMiddleware>();
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

app.Run();

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
