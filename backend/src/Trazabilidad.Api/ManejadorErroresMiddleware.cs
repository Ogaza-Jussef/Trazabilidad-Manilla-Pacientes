using System.Text.Json;
using Trazabilidad.Domain;

namespace Trazabilidad.Api;

public sealed class ManejadorErroresMiddleware
{
    private readonly RequestDelegate _siguiente;
    private readonly ILogger<ManejadorErroresMiddleware> _log;

    public ManejadorErroresMiddleware(RequestDelegate siguiente, ILogger<ManejadorErroresMiddleware> log)
    {
        _siguiente = siguiente;
        _log = log;
    }

    public async Task InvokeAsync(HttpContext contexto)
    {
        try
        {
            await _siguiente(contexto);
        }
        catch (ErrorValidacion ex)
        {
            await ResultadosError.Crear(contexto, StatusCodes.Status400BadRequest, ex.Codigo, ex.Message, ex.Detalles)
                .ExecuteAsync(contexto);
        }
        catch (ErrorNoEncontrado ex)
        {
            await ResultadosError.Crear(contexto, StatusCodes.Status404NotFound, ex.Codigo, ex.Message)
                .ExecuteAsync(contexto);
        }
        catch (ErrorConflicto ex)
        {
            await ResultadosError.Crear(contexto, StatusCodes.Status409Conflict, ex.Codigo, ex.Message)
                .ExecuteAsync(contexto);
        }
        catch (ErrorProhibido ex)
        {
            await ResultadosError.Crear(contexto, StatusCodes.Status403Forbidden, ex.Codigo, ex.Message)
                .ExecuteAsync(contexto);
        }
        catch (ErrorDependencia ex)
        {
            _log.LogWarning("dependencia_no_disponible {RequestId}", contexto.Items["RequestId"]);
            await ResultadosError.Crear(contexto, StatusCodes.Status503ServiceUnavailable, ex.Codigo, ex.Message)
                .ExecuteAsync(contexto);
        }
        catch (JsonException)
        {
            await ResultadosError.Crear(
                    contexto,
                    StatusCodes.Status400BadRequest,
                    "validation_error",
                    "El cuerpo JSON no es válido.",
                    new[] { new DetalleValidacion("body", "json") })
                .ExecuteAsync(contexto);
        }
        catch (Exception ex)
        {
            _log.LogError(ex, "error_no_controlado {RequestId}", contexto.Items["RequestId"]);
            await ResultadosError.Crear(
                    contexto,
                    StatusCodes.Status500InternalServerError,
                    "internal_error",
                    "No se pudo completar la operación.")
                .ExecuteAsync(contexto);
        }
    }
}
