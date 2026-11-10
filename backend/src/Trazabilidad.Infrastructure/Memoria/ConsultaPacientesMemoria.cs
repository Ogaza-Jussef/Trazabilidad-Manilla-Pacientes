using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.Memoria;

public sealed class ConsultaPacientesMemoria : IConsultaPacientes
{
    private readonly Dictionary<string, Paciente> _pacientes;

    public ConsultaPacientesMemoria(IEnumerable<Paciente> pacientes)
    {
        _pacientes = pacientes.ToDictionary(Clave);
    }

    public Task<Paciente?> Obtener(string codigoEmpresa, string numeroCaso, CancellationToken cancelacion)
    {
        _pacientes.TryGetValue(Clave(codigoEmpresa, numeroCaso), out var paciente);
        return Task.FromResult(paciente);
    }

    public static string Clave(Paciente paciente) => Clave(paciente.CodigoEmpresa, paciente.NumeroCaso);

    public static string Clave(string codigoEmpresa, string numeroCaso) =>
        codigoEmpresa.ToUpperInvariant() + "\u001f" + numeroCaso;
}
