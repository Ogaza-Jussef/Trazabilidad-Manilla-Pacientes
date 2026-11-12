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
builder.Services.AddCors(opciones =>
{
    opciones.AddDefaultPolicy(politica =>
    {
        politica.SetIsOriginAllowed(EsOrigenDePrueba);
        politica.AllowAnyHeader();
        politica.AllowAnyMethod();
    });
});
Composicion.Registrar(builder);

var app = builder.Build();

app.UseCors();
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

static bool EsOrigenDePrueba(string origen)
{
    if (!Uri.TryCreate(origen, UriKind.Absolute, out var uri))
        return false;
    if (uri.Host is "localhost" or "127.0.0.1")
        return true;
    if (!System.Net.IPAddress.TryParse(uri.Host, out var ip))
        return false;
    var octetos = ip.GetAddressBytes();
    if (octetos.Length != 4)
        return false;
    if (octetos[0] == 10)
        return true;
    if (octetos[0] == 192 && octetos[1] == 168)
        return true;
    return octetos[0] == 172 && octetos[1] is >= 16 and <= 31;
}

public partial class Program
{
}
