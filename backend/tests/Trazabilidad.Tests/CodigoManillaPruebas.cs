using Trazabilidad.Domain;

namespace Trazabilidad.Tests;

public class CodigoManillaPruebas
{
    [Theory]
    [InlineData("C30-100001", "C30", "100001")]
    [InlineData(" c30-100001 ", "C30", "100001")]
    public void Debe_separar_empresa_y_caso(string bruto, string empresa, string caso)
    {
        var codigo = CodigoManilla.Leer(bruto);

        Assert.NotNull(codigo);
        Assert.Equal(empresa, codigo!.CodigoEmpresa);
        Assert.Equal(caso, codigo.NumeroCaso);
    }

    [Theory]
    [InlineData("")]
    [InlineData("100001")]
    [InlineData("C30-")]
    [InlineData("C30-12A")]
    [InlineData("C30-100001-1")]
    public void Debe_rechazar_un_texto_que_no_es_manilla(string bruto)
    {
        Assert.Null(CodigoManilla.Leer(bruto));
    }
}
