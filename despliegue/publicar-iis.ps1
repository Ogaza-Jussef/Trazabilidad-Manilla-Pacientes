# Arma las dos carpetas que se copian al servidor.
# En IIS, con el Hosting Bundle de .NET 9 y el módulo URL Rewrite:
#   Aplicación IIS /TrazabilidadManillas   carpeta salida\web   grupo sin código administrado
#   Aplicación IIS /TrazabilidadApi         carpeta salida\api   grupo sin código administrado
# Las dos aplicaciones van en el mismo sitio HTTPS (puerto 443).
# El celular no llega al puerto 5080; la página llama a /TrazabilidadApi en ese sitio.
# El grupo de la API necesita permiso de escritura en la carpeta logs.
# El entorno Hospital no es Production: así sigue la lista local de pacientes de prueba.

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$salida = Join-Path $PSScriptRoot "salida"
$api = Join-Path $salida "api"
$web = Join-Path $salida "web"

if (Test-Path $salida) {
    Remove-Item $salida -Recurse -Force
}

dotnet publish (Join-Path $raiz "backend\src\Trazabilidad.Api\Trazabilidad.Api.csproj") -c Release -o $api
New-Item -ItemType Directory -Force -Path (Join-Path $api "logs") | Out-Null

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter -and (Test-Path "D:\flutter\bin\flutter.bat")) {
    $env:Path = "D:\flutter\bin;" + $env:Path
}

Push-Location (Join-Path $raiz "frontend_web")
try {
    flutter build web --release --base-href "/TrazabilidadManillas/"
}
finally {
    Pop-Location
}

Copy-Item (Join-Path $raiz "frontend_web\build\web") $web -Recurse
Write-Host "Listo. Copia estas carpetas al servidor:"
Write-Host "  $web"
Write-Host "  $api"
