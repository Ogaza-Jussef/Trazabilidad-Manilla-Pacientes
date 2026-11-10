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
        if (empresa.Length > 10 || caso.Length > 20)
            return null;

        return new CodigoManilla(empresa, caso);
    }
}
