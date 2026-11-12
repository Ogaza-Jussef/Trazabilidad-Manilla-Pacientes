using System.Text.Json;
using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Api;

public static class RutasTrazabilidad
{
    public static void Map(WebApplication app)
    {
        var grupo = app.MapGroup("/api/v1");

        grupo.MapGet("/servidores", ListarServidoresAsync);
        grupo.MapGet("/servidores-api", ListarServidoresApiAsync);
        grupo.MapPost("/sesiones", IniciarSesionAsync);

        grupo.MapGet("/servicios", () =>
        {
            var items = ServiciosLectura.Orden
                .Select(servicio => new ServicioResponse(servicio.Orden, servicio.Nombre, servicio.Area))
                .ToArray();
            return Results.Ok(new { items });
        });

        grupo.MapGet("/pacientes", ConsultarPacienteAsync);
        grupo.MapGet("/trazabilidad", ListarAsync);
        grupo.MapGet("/trazabilidad/{id:long}", ObtenerAsync);
        grupo.MapPost("/trazabilidad", RegistrarAsync);
    }

    private static async Task<IResult> IniciarSesionAsync(
        HttpContext contexto,
        JsonSerializerOptions json,
        IniciarSesion casoUso,
        CancellationToken cancelacion)
    {
        InicioSesionRequest? solicitud;
        try
        {
            solicitud = await contexto.Request.ReadFromJsonAsync<InicioSesionRequest>(json, cancelacion);
        }
        catch (JsonException)
        {
            throw new ErrorValidacion(
                "El cuerpo JSON no es válido.",
                new DetalleValidacion("body", "json"));
        }

        if (solicitud is null)
        {
            throw new ErrorValidacion(
                "El cuerpo JSON no es válido.",
                new DetalleValidacion("body", "json"));
        }

        var sesion = await casoUso.Ejecutar(solicitud.Usuario, solicitud.Contrasena, solicitud.Servidor, cancelacion);
        return Results.Ok(new SesionResponse(
            sesion.Token,
            sesion.Usuario,
            sesion.Empresas.Select(empresa => new EmpresaResponse(empresa.Codigo, empresa.Nombre)).ToArray()));
    }

    private static async Task<IResult> ListarServidoresAsync(
        ICatalogoServidores catalogo,
        CancellationToken cancelacion)
    {
        var servidores = await catalogo.Listar(cancelacion);
        return Results.Ok(new
        {
            items = servidores.Select(servidor => new ServidorPublicoResponse(servidor.Nombre)).ToArray(),
        });
    }

    private static async Task<IResult> ListarServidoresApiAsync(
        HttpContext contexto,
        IConsultaServidoresApi consulta,
        CancellationToken cancelacion)
    {
        var sesion = contexto.Items["Sesion"] as SesionActiva;
        if (sesion is null)
            return Results.Unauthorized();

        var servidores = await consulta.Listar(sesion.Token, sesion.Servidor, cancelacion);
        return Results.Ok(new
        {
            items = servidores.Select(servidor => new ServidorApiResponse(servidor.Ip, servidor.Nombre)).ToArray(),
        });
    }

    private static async Task<IResult> ConsultarPacienteAsync(
        string? codigoQr,
        ConsultarPaciente casoUso,
        CancellationToken cancelacion)
    {
        var paciente = await casoUso.Ejecutar(codigoQr, cancelacion);
        return Results.Ok(Mapeo.Desde(paciente));
    }

    private static async Task<IResult> ListarAsync(
        string? numeroCaso,
        int? limit,
        string? cursor,
        ListarTrazabilidad casoUso,
        CancellationToken cancelacion)
    {
        var pagina = await casoUso.Ejecutar(numeroCaso, limit ?? 20, cursor, cancelacion);
        return Results.Ok(new PaginaResponse(
            pagina.Items.Select(Mapeo.Desde).ToArray(),
            pagina.NextCursor,
            pagina.Limit));
    }

    private static async Task<IResult> ObtenerAsync(
        long id,
        ObtenerTrazabilidad casoUso,
        CancellationToken cancelacion)
    {
        var fila = await casoUso.Ejecutar(id, cancelacion);
        return Results.Ok(Mapeo.Desde(fila));
    }

    private static async Task<IResult> RegistrarAsync(
        HttpContext contexto,
        JsonSerializerOptions json,
        RegistrarLectura casoUso,
        CancellationToken cancelacion)
    {
        CrearTrazabilidadRequest? solicitud;
        try
        {
            solicitud = await contexto.Request.ReadFromJsonAsync<CrearTrazabilidadRequest>(json, cancelacion);
        }
        catch (JsonException)
        {
            throw new ErrorValidacion(
                "El cuerpo JSON no es válido.",
                new DetalleValidacion("body", "json"));
        }

        if (solicitud is null)
        {
            throw new ErrorValidacion(
                "El cuerpo JSON no es válido.",
                new DetalleValidacion("body", "json"));
        }

        var puesto = contexto.Request.Headers["X-Servicio-Puesto"].ToString().Trim();
        var servicio = solicitud.Servicio?.Trim() ?? "";
        if (puesto.Length == 0 || !string.Equals(puesto, servicio, StringComparison.Ordinal))
        {
            throw new ErrorProhibido("Este puesto no puede registrar ese servicio.");
        }

        var resultado = await casoUso.Ejecutar(solicitud.CodigoQr, servicio, cancelacion);
        var cuerpo = Mapeo.Desde(resultado.Fila);
        if (!resultado.Creada)
        {
            contexto.Response.Headers["X-Idempotent-Replay"] = "true";
            return Results.Ok(cuerpo);
        }

        return Results.Created($"/api/v1/trazabilidad/{resultado.Fila.Id}", cuerpo);
    }
}
