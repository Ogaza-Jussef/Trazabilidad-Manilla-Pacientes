using System.Text.RegularExpressions;

namespace Trazabilidad.Domain;

public sealed record CodigoManilla(string CodigoEmpresa, string NumeroCaso)
{
    private static readonly Regex Patron = new(
        "^([A-Za-z0-9]+)-([0-9]+)$",
        RegexOptions.CultureInvariant | RegexOptions.Compiled);

    public static CodigoManilla? Leer(string? bruto)
    {
        if (string.IsNullOrWhiteSpace(bruto))
            return null;

        var texto = bruto.Trim();
        if (texto.Length > 40)
            return null;

        var coincidencia = Patron.Match(texto);
        if (!coincidencia.Success)
            return null;

        var empresa = coincidencia.Groups[1].Value.ToUpperInvariant();
        var caso = coincidencia.Groups[2].Value;
        if (empresa.Length is < 1 or > 10 || !EsConsecutivo(caso))
            return null;

        return new CodigoManilla(empresa, caso);
    }

    // El caso arranca en 1 y crece con cada ingreso. No lleva ceros a la izquierda.
    public static bool EsConsecutivo(string caso) =>
        caso.Length is >= 1 and <= 18
        && caso[0] != '0'
        && caso.All(char.IsAsciiDigit);
}
