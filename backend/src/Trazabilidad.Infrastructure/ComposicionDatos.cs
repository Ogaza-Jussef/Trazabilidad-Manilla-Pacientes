using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure;

public sealed class RelojSistema : IReloj
{
    public DateTime Ahora() => DateTime.Now;
}

public static class SemillaDesarrollo
{
    public static readonly Paciente[] Pacientes =
    {
        new("C30", "100001", "10000001", "Ana", "Perez"),
    };
}
