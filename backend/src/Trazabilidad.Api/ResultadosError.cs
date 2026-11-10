using Trazabilidad.Domain;

namespace Trazabilidad.Api;

public static class ResultadosError
{
    public static IResult Crear(
        HttpContext contexto,
        int estado,
        string codigo,
        string mensaje,
        IReadOnlyList<DetalleValidacion>? detalles = null)
    {
        var cuerpo = new
        {
            error = new
            {
                code = codigo,
                message = mensaje,
                details = (detalles ?? Array.Empty<DetalleValidacion>())
                    .Select(detalle => new { field = detalle.Campo, reason = detalle.Motivo })
                    .ToArray(),
                requestId = contexto.Items["RequestId"] as string ?? "",
            },
        };

        return Results.Json(cuerpo, statusCode: estado);
    }
}
