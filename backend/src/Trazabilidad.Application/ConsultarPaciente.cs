using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed class ConsultarPaciente
{
    private readonly IConsultaPacientes _pacientes;

    public ConsultarPaciente(IConsultaPacientes pacientes)
    {
        _pacientes = pacientes;
    }

    public async Task<Paciente> Ejecutar(string? codigoQr, CancellationToken cancelacion)
    {
        var codigo = CodigoManilla.Leer(codigoQr);
        if (codigo is null)
        {
            throw new ErrorValidacion(
                "El código es la empresa, un guion y el consecutivo del caso. Por ejemplo C30-1.",
                new DetalleValidacion("codigoQr", "formato"));
        }

        var paciente = await _pacientes.Obtener(codigo.CodigoEmpresa, codigo.NumeroCaso, cancelacion);
        if (paciente is null)
            throw new ErrorNoEncontrado("No hay un paciente para ese caso en el sistema.");

        return paciente;
    }
}
