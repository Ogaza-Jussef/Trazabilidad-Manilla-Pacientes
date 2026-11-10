namespace Trazabilidad.Domain;

public sealed record ServicioLectura(int Orden, string Nombre, string Area);

public static class ServiciosLectura
{
    public const string Impresion = "Impresión de manilla";

    public static readonly IReadOnlyList<ServicioLectura> Orden = new ServicioLectura[]
    {
        new(2, "Colocación de manilla", "Cirugía"),
        new(3, "Orden de paso a cirugía", "Urgencias"),
        new(4, "Ingreso de preparación", "Cirugía"),
        new(5, "Paso a Qx", "Cirugía"),
        new(6, "Finalización de cirugía", "Cirugía"),
    };

    public static ServicioLectura? Buscar(string nombre)
    {
        foreach (var servicio in Orden)
        {
            if (servicio.Nombre == nombre)
                return servicio;
        }

        return null;
    }

    public static int Indice(string nombre)
    {
        for (var i = 0; i < Orden.Count; i++)
        {
            if (Orden[i].Nombre == nombre)
                return i;
        }

        return -1;
    }
}
