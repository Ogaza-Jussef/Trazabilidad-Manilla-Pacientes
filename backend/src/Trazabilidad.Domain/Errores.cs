namespace Trazabilidad.Domain;

public sealed record DetalleValidacion(string Campo, string Motivo);

public abstract class ErrorDominio : Exception
{
    protected ErrorDominio(string codigo, string mensaje)
        : base(mensaje)
    {
        Codigo = codigo;
    }

    public string Codigo { get; }
}

public sealed class ErrorValidacion : ErrorDominio
{
    public ErrorValidacion(string mensaje, params DetalleValidacion[] detalles)
        : base("validation_error", mensaje)
    {
        Detalles = detalles;
    }

    public IReadOnlyList<DetalleValidacion> Detalles { get; }
}

public sealed class ErrorNoEncontrado : ErrorDominio
{
    public ErrorNoEncontrado(string mensaje)
        : base("not_found", mensaje)
    {
    }
}

public sealed class ErrorConflicto : ErrorDominio
{
    public ErrorConflicto(string mensaje)
        : base("conflict", mensaje)
    {
    }
}

public sealed class ErrorProhibido : ErrorDominio
{
    public ErrorProhibido(string mensaje)
        : base("forbidden", mensaje)
    {
    }
}

public sealed class ErrorDependencia : ErrorDominio
{
    public ErrorDependencia(string mensaje)
        : base("dependency_unavailable", mensaje)
    {
    }
}
