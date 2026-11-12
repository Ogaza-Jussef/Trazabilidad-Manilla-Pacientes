using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure;

public sealed class RelojSistema : IReloj
{
    public DateTime Ahora() => DateTime.Now;
}

public static class SemillaDesarrollo
{
    public const string Usuario = "operador";

    public const string Contrasena = "operador";

    public static readonly ServidorApi[] Servidores =
    {
        new("", "Desarrollo"),
    };

    public static readonly Paciente[] Pacientes =
    {
        new("C30", "100001", "10000001", "Ana", "Perez"),
    };

    public static readonly Empresa[] Empresas =
    {
        new("C30", "Clínica Central"),
        new("C31", "Sede Norte"),
    };
}
