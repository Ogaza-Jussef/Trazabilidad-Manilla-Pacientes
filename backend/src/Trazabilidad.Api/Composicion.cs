using System.Text.Json;
using System.Text.Json.Serialization;
using Trazabilidad.Application;
using Trazabilidad.Domain;
using Trazabilidad.Infrastructure;
using Trazabilidad.Infrastructure.Memoria;
using Trazabilidad.Infrastructure.Mysql;
using Trazabilidad.Infrastructure.SistemaActual;

namespace Trazabilidad.Api;

public static class Composicion
{
    public static void Registrar(WebApplicationBuilder builder)
    {
        builder.Services.AddSingleton<IReloj, RelojSistema>();

        var almacen = builder.Configuration["Almacen"] ?? "memoria";
        if (string.Equals(almacen, "mysql", StringComparison.OrdinalIgnoreCase))
            builder.Services.AddSingleton<IRepositorioTrazabilidad, RepositorioTrazabilidadMySql>();
        else
            builder.Services.AddSingleton<IRepositorioTrazabilidad, RepositorioTrazabilidadMemoria>();

        var baseUrl = builder.Configuration["SistemaActual:BaseUrl"];
        var timeout = 5;
        if (int.TryParse(builder.Configuration["SistemaActual:TimeoutSegundos"], out var segundos))
            timeout = Math.Clamp(segundos, 1, 30);

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            if (builder.Environment.IsProduction())
                builder.Services.AddSingleton<IConsultaPacientes, ConsultaPacientesNoConfigurada>();
            else
                builder.Services.AddSingleton<IConsultaPacientes>(new ConsultaPacientesMemoria(SemillaDesarrollo.Pacientes));
        }
        else
        {
            builder.Services.AddHttpClient<IConsultaPacientes, ConsultaPacientesHttp>(cliente =>
            {
                cliente.BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/");
                cliente.Timeout = TimeSpan.FromSeconds(timeout);
            });
        }

        if (builder.Environment.IsProduction())
            builder.Services.AddSingleton<IDirectorioUsuarios, DirectorioUsuariosPendiente>();
        else
            builder.Services.AddSingleton<IDirectorioUsuarios, DirectorioUsuariosMemoria>();

        builder.Services.AddSingleton<IAlmacenSesiones, AlmacenSesionesMemoria>();
        builder.Services.AddSingleton<IniciarSesion>();
        builder.Services.AddSingleton<RegistrarLectura>();
        builder.Services.AddSingleton<ConsultarPaciente>();
        builder.Services.AddSingleton<ListarTrazabilidad>();
        builder.Services.AddSingleton<ObtenerTrazabilidad>();
        builder.Services.AddSingleton(CrearJson());
    }

    public static JsonSerializerOptions CrearJson()
    {
        var json = new JsonSerializerOptions(JsonSerializerDefaults.Web)
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = false,
            UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        };
        return json;
    }
}
