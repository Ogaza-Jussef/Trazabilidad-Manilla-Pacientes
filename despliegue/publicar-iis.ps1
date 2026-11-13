# Arma una sola carpeta para la aplicación IIS /TrazabilidadManillas.
# En el mismo sitio HTTPS, grupo de aplicaciones propio y sin código administrado.
# Requiere el Hosting Bundle de .NET 9. El grupo necesita escribir en logs.
# El entorno Hospital no es Production: así sigue la lista local de pacientes de prueba.
# La página llama a /TrazabilidadManillas/api/v1/... en ese mismo sitio.

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$salida = Join-Path $PSScriptRoot "salida"
$sitio = Join-Path $salida "TrazabilidadManillas"

if (Test-Path $salida) {
    Remove-Item $salida -Recurse -Force
}

dotnet publish (Join-Path $raiz "backend\src\Trazabilidad.Api\Trazabilidad.Api.csproj") -c Release -o $sitio
$logs = Join-Path $sitio "logs"
New-Item -ItemType Directory -Force -Path $logs | Out-Null
Set-Content -Path (Join-Path $logs "leer.txt") -Value "El grupo de la aplicación necesita permiso de escritura en esta carpeta." -Encoding UTF8

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter -and (Test-Path "D:\flutter\bin\flutter.bat")) {
    $env:Path = "D:\flutter\bin;" + $env:Path
}

Push-Location (Join-Path $raiz "frontend_web")
try {
    flutter build web --release --base-href "/TrazabilidadManillas/" --pwa-strategy=none
}
finally {
    Pop-Location
}

$www = Join-Path $sitio "wwwroot"
Copy-Item (Join-Path $raiz "frontend_web\build\web") $www -Recurse
Remove-Item (Join-Path $www "web.config") -Force -ErrorAction SilentlyContinue

@'
Trazabilidad de manillas

Requisitos
- IIS
- Hosting Bundle de .NET 9
- La aplicación ya existe en /TrazabilidadManillas

Pasos
1. Vacía la carpeta física de la aplicación /TrazabilidadManillas.
2. Copia ahí todo el contenido de la carpeta TrazabilidadManillas de este zip.
3. Asígnale un grupo de aplicaciones propio, sin código administrado.
   No uses el grupo del sitio padre.
4. Dale a ese grupo permiso de escritura sobre la carpeta logs.

Abrir
https://appsintranet.esculapiosis.com/TrazabilidadManillas/

La página llama a
https://appsintranet.esculapiosis.com/TrazabilidadManillas/api/v1/servidores

No crees otra aplicación ni abras el puerto 5080.
Si quedó una aplicación TrazabilidadApi, quítala.
'@ | Set-Content -Path (Join-Path $salida "LEEME.txt") -Encoding UTF8

Write-Host "Listo:"
Write-Host "  $sitio"
