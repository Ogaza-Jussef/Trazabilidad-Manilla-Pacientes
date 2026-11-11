# Trazabilidad de pacientes con manilla

App móvil y API para registrar el recorrido de un paciente desde que se coloca la manilla hasta que termina la cirugía. La manilla trae un QR con el código de empresa y el número de caso, por ejemplo `C30-100001`. El nombre, el apellido y el número de identificación salen del sistema actual del hospital. Esta solución solo guarda la lectura.

La impresión de la manilla ocurre cuando el sistema abre el caso. Esa impresión no crea una fila aquí. La primera lectura válida es **Colocación de manilla**.

## Flujo de la app

1. El operador escribe usuario y contraseña, y elige el servidor por su nombre. La app no muestra la IP.
2. La API devuelve las empresas asociadas a ese usuario.
3. El operador elige una empresa y el servicio del puesto.
4. Escanea el QR o lo escribe a mano.
5. Si la empresa del QR no es la empresa elegida, la app no llama a la API.
6. La API consulta el paciente, comprueba el orden del servicio y guarda la lectura.

Los servicios, en orden, son:

| Orden | Servicio | Área |
| --- | --- | --- |
| 2 | Colocación de manilla | Cirugía |
| 3 | Orden de paso a cirugía | Urgencias |
| 4 | Ingreso de preparación | Cirugía |
| 5 | Paso a Qx | Cirugía |
| 6 | Finalización de cirugía | Cirugía |

Cada paso del 3 al 6 exige que el paso anterior ya exista para ese caso. Repetir el mismo caso y el mismo servicio devuelve la fila original, con la misma fecha, y el encabezado `X-Idempotent-Replay: true`. La fecha la pone el servidor con la hora local (`DateTime.Now`), no el reloj del teléfono.

## Estructura

```
backend/
  src/Trazabilidad.Domain          reglas del QR, servicios y errores
  src/Trazabilidad.Application     casos de uso
  src/Trazabilidad.Infrastructure  memoria, MySQL preparado y consulta al HIS
  src/Trazabilidad.Api             HTTP, sesión y composición
  tests/Trazabilidad.Tests
  db/migraciones/001_crear_trazabilidad_manillas.sql
frontend/                          Flutter. El módulo Android está en frontend/android
global.json                        fija el SDK de .NET
```

La API apunta a `net9.0`. `global.json` usa el SDK `10.0.303` con `rollForward: latestFeature`.

## Configuración

Archivo: `backend/src/Trazabilidad.Api/appsettings.json`.

| Clave | Valor actual | Efecto |
| --- | --- | --- |
| `Almacen` | `memoria` | Guarda las lecturas en memoria. Se pierden al reiniciar el proceso. |
| `Almacen` | `mysql` | No abre MySQL. `/health/ready` y las lecturas responden 503: la conexión está pendiente. |
| `SistemaActual:BaseUrl` | vacío | En Development usa el paciente de prueba. En Production responde que la consulta no está configurada. |
| `SistemaActual:BaseUrl` | URL del HIS | `GET {BaseUrl}/api/pacientes?codigoEmpresa=&numeroCaso=`. |
| `SistemaActual:TimeoutSegundos` | `5` | Tiempo de espera de esa consulta. Se recorta entre 1 y 30 segundos. |
| `Trazabilidad:ApiKey` | no definida | Clave opcional para integraciones. También se lee de la variable `TRAZABILIDAD_API_KEY`. |

La API escucha en `http://localhost:5080` (`Properties/launchSettings.json`, entorno `Development`).

En Production el directorio de usuarios responde que la conexión al directorio está pendiente. El usuario de prueba solo existe fuera de Production.

La sesión es un token aleatorio de 32 bytes en memoria. También se pierde al reiniciar. La contraseña no se guarda en el teléfono. El teléfono guarda, en `shared_preferences`, servidor, token, usuario, empresa y servicio.

### Consulta al sistema actual

Si `SistemaActual:BaseUrl` tiene valor, la API espera:

```
GET {BaseUrl}/api/pacientes?codigoEmpresa=C30&numeroCaso=100001
```

Cuerpo JSON:

```json
{
  "numeroIdentificacion": "10000001",
  "nombre": "Ana",
  "apellido": "Perez"
}
```

`404` significa que no hay paciente. Otro estado de error se traduce a 503.

## Cómo ejecutarlo

Backend:

```powershell
dotnet restore backend/Trazabilidad.slnx
dotnet test backend/Trazabilidad.slnx --no-restore
dotnet run --project backend/src/Trazabilidad.Api --launch-profile http
```

Comprobar: `GET http://localhost:5080/health` responde `{ "status": "ok" }`.

Frontend. En Android Studio abre la carpeta `frontend` (ahí está el `pubspec.yaml` y el módulo Android). El SDK de Flutter de esta máquina está en `D:\flutter` y el Android SDK en `D:\Sdk-Android-Studio`. Esas rutas quedan en `frontend/android/local.properties`, que no se versiona.

La app pide internet, cámara y HTTP sin cifrado para hablar con `http://10.0.2.2:5080` desde el emulador. El nombre en el teléfono es Trazabilidad.

```powershell
cd frontend
flutter pub get
flutter run
```

Dirección del servidor según el dispositivo:

| Dónde corre la app | Servidor |
| --- | --- |
| Emulador Android | `http://10.0.2.2:5080` |
| Teléfono en la misma red | `http://IP-DEL-PC:5080` |
| Misma máquina | `http://localhost:5080` |

La app del emulador llama a la API local en `http://10.0.2.2:5080`. En el navegador usa `http://localhost:5080`. El servidor que elige el operador sale de Campbell y se muestra solo por nombre, por ejemplo Campbell o Bahia. Las empresas se ven como `C30 - Fundacion Campbell`.

Web. El proyecto está en `frontend_web` y usa las mismas pantallas. Primero arranca la API; el navegador solo puede hablar con `localhost`.

```powershell
dotnet run --project backend/src/Trazabilidad.Api --launch-profile http
cd frontend_web
flutter pub get
flutter run -d chrome
```

### Datos de desarrollo

| Campo | Valor |
| --- | --- |
| Usuario | `operador` |
| Contraseña | `operador` |
| Empresas | `C30` Clínica Central, `C31` Sede Norte |
| Paciente de prueba | `C30-100001`, Ana Perez, identificación `10000001` |

Ese usuario y esa contraseña solo sirven para probar en local. No existen en Production.

## API

Prefijo `/api/v1`. JSON en camelCase. Las propiedades desconocidas se rechazan. `Cache-Control: no-store`.

Rutas públicas: `GET /health`, `GET /health/ready`, `GET /api/v1/servidores` y `POST /api/v1/sesiones`.

`GET /api/v1/servidores` devuelve `{ "items": [{ "nombre": "Campbell" }] }`. No incluye IP ni datos de conexión.

`Campbell:BaseUrl` en `appsettings.json` apunta a ApiCampbell. Con esa dirección, el ingreso pide el token y después las empresas del usuario. Si la dirección está vacía, en desarrollo sigue el usuario local.

El resto pide `Authorization: Bearer {token}`. En pacientes y trazabilidad, si el token es de sesión, también pide `X-Codigo-Empresa` y ese código tiene que estar entre las empresas del usuario. Una clave de API, si está configurada, entra sin esa comprobación de empresa.

Al registrar, `X-Servicio-Puesto` tiene que ser igual al `servicio` del cuerpo.

### Iniciar sesión

`POST /api/v1/sesiones`

```json
{ "usuario": "operador", "contrasena": "operador", "servidor": "Desarrollo" }
```

Respuesta 200:

```json
{
  "token": "...",
  "usuario": "operador",
  "empresas": [
    { "codigo": "C30", "nombre": "Clínica Central" },
    { "codigo": "C31", "nombre": "Sede Norte" }
  ]
}
```

Usuario de 1 a 40 caracteres. Contraseña de 1 a 80. Usuario o contraseña incorrectos: 401.

### Servicios

`GET /api/v1/servicios` devuelve el orden, el nombre y el área de los cinco pasos registrables.

### Paciente

`GET /api/v1/pacientes?codigoQr=C30-100001`

El QR es `empresa-caso`: empresa alfanumérica de hasta 10 caracteres, caso numérico de hasta 20, texto completo de hasta 40. La empresa se normaliza a mayúsculas. El código de empresa no se guarda en `trazabilidad_manillas`; solo se usa para consultar al HIS y para validar el puesto.

### Registrar lectura

`POST /api/v1/trazabilidad`

```json
{ "codigoQr": "C30-100001", "servicio": "Colocación de manilla" }
```

Encabezados: `Authorization`, `X-Codigo-Empresa: C30`, `X-Servicio-Puesto: Colocación de manilla`.

La primera vez responde 201. Si ya existía ese caso y ese servicio, responde 200 con `X-Idempotent-Replay: true` y la fecha original. `Impresión de manilla` responde 400.

### Consultar lecturas

`GET /api/v1/trazabilidad?numeroCaso=100001&limit=20&cursor=`

`limit` va de 1 a 50; si no se envía, es 20. `cursor` es el id de la última fila, en base64. `nextCursor` viene vacío cuando no hay más páginas.

`GET /api/v1/trazabilidad/{id}` devuelve una fila.

### Errores

```json
{
  "error": {
    "code": "validation_error",
    "message": "...",
    "details": [{ "field": "codigoQr", "reason": "formato" }],
    "requestId": "..."
  }
}
```

| HTTP | code |
| --- | --- |
| 400 | `validation_error` |
| 401 | `unauthenticated` |
| 403 | `forbidden` |
| 404 | `not_found` |
| 409 | `conflict` |
| 500 | `internal_error` |
| 503 | `dependency_unavailable` |

## Base de datos

MySQL 5.6.19. Una sola tabla nueva: `trazabilidad_manillas`. Empresas, servicios y casos siguen en el sistema actual.

Script: `backend/db/migraciones/001_crear_trazabilidad_manillas.sql`.

| Columna | Tipo |
| --- | --- |
| `id_trazabilidad` | `BIGINT UNSIGNED` autonumérico, clave primaria |
| `numero_caso` | `VARCHAR(20)` |
| `nombre` | `VARCHAR(80)` |
| `apellido` | `VARCHAR(80)` |
| `numero_identificacion` | `VARCHAR(20)` |
| `servicio` | `VARCHAR(120)`, con el nombre exacto del flujo |
| `fecha_hora_captura` | `DATETIME`, hora local del servidor |

Índice único `(numero_caso, servicio)`. InnoDB, `utf8mb4_unicode_ci`. Las sentencias parametrizadas están en `SentenciasTrazabilidad`, pero el repositorio MySQL todavía no abre una conexión.

## Pendiente

- Cadena de conexión a MySQL y ejecución real del repositorio.
- Directorio de usuarios del hospital, en lugar del usuario de desarrollo.
- Carpeta `ios`, si más adelante se ejecuta en iPhone.
