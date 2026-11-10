using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class ConsultaPacientesNoConfigurada : IConsultaPacientes
{
    public Task<Paciente?> Obtener(string codigoEmpresa, string numeroCaso, CancellationToken cancelacion)
    {
        throw new ErrorDependencia("Falta la dirección del sistema de pacientes.");
    }
}
