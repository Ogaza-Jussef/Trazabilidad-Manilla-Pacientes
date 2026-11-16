# Arma una sola carpeta para la aplicación IIS /TrazabilidadManillas.
# El proceso de la API arranca aparte: el sitio padre es ASP.NET y tumba el grupo si comparten proceso.
# Requiere el Hosting Bundle de .NET 9 y, en Windows Server 2012 R2, Visual C++ 2015-2022 x64.
# El grupo necesita escribir en logs.
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
Copy-Item (Join-Path $PSScriptRoot "reparar-iis.ps1") (Join-Path $salida "reparar-iis.ps1") -Force

@'
Trazabilidad de manillas

El navegador recibe 503 porque el grupo de esta aplicación se detuvo.
El sitio padre es ASP.NET. Esta API arranca en un proceso aparte.

Antes de copiar, en el servidor
1. Instala Visual C++ 2015-2022 x64:
   https://aka.ms/vs/17/release/vc_redist.x64.exe
   En IIS 8.5, sin esto el proceso se cae y el sitio responde 503.
2. Instala el Hosting Bundle de .NET 9 y reinicia IIS.
3. Ejecuta reparar-iis.ps1 como administrador.
   Crea el grupo TrazabilidadManillas, lo inicia y lo asigna a la aplicación.
   El grupo del sitio padre no se toca.

Pasos
1. Vacía la carpeta física de la aplicación /TrazabilidadManillas.
2. Copia ahí todo el contenido de la carpeta TrazabilidadManillas de este zip.
3. Dale al grupo TrazabilidadManillas permiso de escritura sobre la carpeta logs.
4. Vuelve a ejecutar reparar-iis.ps1 para arrancar el grupo.

Abrir
https://appsintranet.esculapiosis.com/TrazabilidadManillas/

La página llama a
https://appsintranet.esculapiosis.com/TrazabilidadManillas/api/v1/servidores

No crees otra aplicación ni abras el puerto 5080.
Si quedó una aplicación TrazabilidadApi, quítala.
'@ | Set-Content -Path (Join-Path $salida "LEEME.txt") -Encoding UTF8

Write-Host "Listo:"
Write-Host "  $sitio"
