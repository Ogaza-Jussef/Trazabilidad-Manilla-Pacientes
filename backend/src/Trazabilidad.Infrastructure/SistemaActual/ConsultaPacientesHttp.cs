using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Trazabilidad.Application;
using Trazabilidad.Domain;

namespace Trazabilidad.Infrastructure.SistemaActual;

public sealed class ConsultaPacientesHttp : IConsultaPacientes
{
    private readonly HttpClient _http;

    public ConsultaPacientesHttp(HttpClient http)
    {
        _http = http;
    }

    public async Task<Paciente?> Obtener(string codigoEmpresa, string numeroCaso, CancellationToken cancelacion)
    {
        var ruta =
            "api/pacientes?codigoEmpresa=" + Uri.EscapeDataString(codigoEmpresa) +
            "&numeroCaso=" + Uri.EscapeDataString(numeroCaso);

        using var respuesta = await _http.GetAsync(ruta, cancelacion);
        if (respuesta.StatusCode == HttpStatusCode.NotFound)
            return null;

        if (!respuesta.IsSuccessStatusCode)
            throw new ErrorDependencia("El sistema de pacientes no respondió.");

        PacienteSistemaDto? dto;
        try
        {
            dto = await respuesta.Content.ReadFromJsonAsync<PacienteSistemaDto>(cancelacion);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new ErrorDependencia("El sistema de pacientes devolvió una respuesta que no se pudo leer.");
        }

        if (dto is null
            || string.IsNullOrWhiteSpace(dto.NumeroIdentificacion)
            || string.IsNullOrWhiteSpace(dto.Nombre)
            || string.IsNullOrWhiteSpace(dto.Apellido))
        {
            throw new ErrorDependencia("El sistema de pacientes devolvió una respuesta incompleta.");
        }

        return new Paciente(
            codigoEmpresa,
            numeroCaso,
            dto.NumeroIdentificacion.Trim(),
            dto.Nombre.Trim(),
            dto.Apellido.Trim());
    }

    private sealed class PacienteSistemaDto
    {
        [JsonPropertyName("numeroIdentificacion")]
        public string? NumeroIdentificacion { get; set; }

        [JsonPropertyName("nombre")]
        public string? Nombre { get; set; }

        [JsonPropertyName("apellido")]
        public string? Apellido { get; set; }
    }
}
