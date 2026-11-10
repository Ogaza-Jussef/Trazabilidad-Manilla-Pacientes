using System.Text;
using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed record PaginaTrazabilidad(
    IReadOnlyList<TrazabilidadManilla> Items,
    string? NextCursor,
    int Limit);

public sealed class ListarTrazabilidad
{
    private readonly IRepositorioTrazabilidad _repositorio;

    public ListarTrazabilidad(IRepositorioTrazabilidad repositorio)
    {
        _repositorio = repositorio;
    }

    public async Task<PaginaTrazabilidad> Ejecutar(
        string? numeroCaso,
        int limite,
        string? cursor,
        CancellationToken cancelacion)
    {
        if (string.IsNullOrWhiteSpace(numeroCaso)
            || numeroCaso.Length > 20
            || !numeroCaso.All(char.IsDigit))
        {
            throw new ErrorValidacion(
                "El número de caso es obligatorio y numérico.",
                new DetalleValidacion("numeroCaso", "formato"));
        }

        if (limite < 1)
        {
            throw new ErrorValidacion(
                "El límite debe ser al menos 1.",
                new DetalleValidacion("limit", "rango"));
        }

        var tope = Math.Min(limite, 50);
        long? despuesDeId = null;
        if (!string.IsNullOrWhiteSpace(cursor))
        {
            despuesDeId = DecodificarCursor(cursor);
        }

        var filas = (await _repositorio.ListarPorCaso(numeroCaso, tope + 1, despuesDeId, cancelacion))
            .ToList();

        string? siguiente = null;
        if (filas.Count > tope)
        {
            filas.RemoveAt(filas.Count - 1);
            siguiente = Convert.ToBase64String(Encoding.UTF8.GetBytes(filas[^1].Id.ToString()));
        }

        return new PaginaTrazabilidad(filas, siguiente, tope);
    }

    private static long DecodificarCursor(string cursor)
    {
        try
        {
            var texto = Encoding.UTF8.GetString(Convert.FromBase64String(cursor));
            if (!long.TryParse(texto, out var id) || id < 1)
                throw new FormatException();

            return id;
        }
        catch (FormatException)
        {
            throw new ErrorValidacion(
                "El cursor no es válido.",
                new DetalleValidacion("cursor", "formato"));
        }
    }
}
