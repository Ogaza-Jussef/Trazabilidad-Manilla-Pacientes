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
        politica.SetIsOriginAllowed(origen =>
        {
            if (!Uri.TryCreate(origen, UriKind.Absolute, out var uri))
                return false;
            return uri.Host is "localhost" or "127.0.0.1";
        });
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

public partial class Program
{
}
