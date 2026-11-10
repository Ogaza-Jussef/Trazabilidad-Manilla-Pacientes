using Trazabilidad.Domain;

namespace Trazabilidad.Application;

public sealed record ResultadoRegistro(TrazabilidadManilla Fila, bool Creada);

public sealed class RegistrarLectura
{
    private readonly IRepositorioTrazabilidad _repositorio;
    private readonly IConsultaPacientes _pacientes;
    private readonly IReloj _reloj;

    public RegistrarLectura(
        IRepositorioTrazabilidad repositorio,
        IConsultaPacientes pacientes,
        IReloj reloj)
    {
        _repositorio = repositorio;
        _pacientes = pacientes;
        _reloj = reloj;
    }

    public async Task<ResultadoRegistro> Ejecutar(
        string? codigoQr,
        string? servicio,
        CancellationToken cancelacion)
    {
        var codigo = CodigoManilla.Leer(codigoQr);
        if (codigo is null)
        {
            throw new ErrorValidacion(
                "El código QR debe tener la forma empresa-caso, por ejemplo C30-100001.",
                new DetalleValidacion("codigoQr", "formato"));
        }

        if (string.IsNullOrWhiteSpace(servicio))
        {
            throw new ErrorValidacion(
                "El servicio es obligatorio.",
                new DetalleValidacion("servicio", "requerido"));
        }

        var nombreServicio = servicio.Trim();
        if (nombreServicio == ServiciosLectura.Impresion)
        {
            throw new ErrorValidacion(
                "La manilla se imprime al abrir el caso. Ese paso no se registra con una lectura de QR.",
                new DetalleValidacion("servicio", "impresion"));
        }

        var paso = ServiciosLectura.Buscar(nombreServicio);
        if (paso is null)
        {
            throw new ErrorValidacion(
                "El servicio no pertenece al flujo de lectura.",
                new DetalleValidacion("servicio", "desconocido"));
        }

        var paciente = await _pacientes.Obtener(codigo.CodigoEmpresa, codigo.NumeroCaso, cancelacion);
        if (paciente is null)
        {
            throw new ErrorNoEncontrado("No hay un paciente para ese caso en el sistema.");
        }

        if (paciente.Nombre.Length is < 1 or > 80
            || paciente.Apellido.Length is < 1 or > 80
            || paciente.NumeroIdentificacion.Length is < 1 or > 20)
        {
            throw new ErrorDependencia("El sistema de pacientes devolvió datos que no se pueden registrar.");
        }

        var existente = await _repositorio.ObtenerPorCasoYServicio(
            codigo.NumeroCaso,
            paso.Nombre,
            cancelacion);
        if (existente is not null)
            return new ResultadoRegistro(existente, false);

        var indice = ServiciosLectura.Indice(paso.Nombre);
        if (indice > 0)
        {
            var anterior = ServiciosLectura.Orden[indice - 1];
            var previa = await _repositorio.ObtenerPorCasoYServicio(
                codigo.NumeroCaso,
                anterior.Nombre,
                cancelacion);
            if (previa is null)
            {
                throw new ErrorConflicto(
                    $"Falta la captura del servicio anterior: {anterior.Nombre}.");
            }
        }

        var guardada = await _repositorio.Agregar(
            new NuevaTrazabilidad(
                codigo.NumeroCaso,
                paciente.Nombre,
                paciente.Apellido,
                paciente.NumeroIdentificacion,
                paso.Nombre,
                _reloj.Ahora()),
            cancelacion);

        return new ResultadoRegistro(guardada.Fila, guardada.Creada);
    }
}
