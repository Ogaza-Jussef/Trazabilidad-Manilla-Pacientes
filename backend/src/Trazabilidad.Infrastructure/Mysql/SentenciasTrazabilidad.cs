namespace Trazabilidad.Infrastructure.Mysql;

public static class SentenciasTrazabilidad
{
    public const string Insertar = """
        INSERT INTO trazabilidad_manillas
            (numero_caso, nombre, apellido, numero_identificacion, servicio, fecha_hora_captura)
        VALUES
            (@numeroCaso, @nombre, @apellido, @numeroIdentificacion, @servicio, @fechaHoraCaptura)
        """;

    public const string ObtenerPorId = """
        SELECT id_trazabilidad, numero_caso, nombre, apellido, numero_identificacion, servicio, fecha_hora_captura
        FROM trazabilidad_manillas
        WHERE id_trazabilidad = @id
        """;

    public const string ObtenerPorCasoYServicio = """
        SELECT id_trazabilidad, numero_caso, nombre, apellido, numero_identificacion, servicio, fecha_hora_captura
        FROM trazabilidad_manillas
        WHERE numero_caso = @numeroCaso AND servicio = @servicio
        """;

    public const string ListarPorCaso = """
        SELECT id_trazabilidad, numero_caso, nombre, apellido, numero_identificacion, servicio, fecha_hora_captura
        FROM trazabilidad_manillas
        WHERE numero_caso = @numeroCaso AND (@despuesDeId IS NULL OR id_trazabilidad > @despuesDeId)
        ORDER BY id_trazabilidad
        LIMIT @limite
        """;
}
