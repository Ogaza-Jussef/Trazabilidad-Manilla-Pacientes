# Ejecutar en el servidor, como administrador, despues de instalar
# Visual C++ 2015-2022 x64 y el Hosting Bundle de .NET 9.
# No cambia el grupo del sitio padre.

$ErrorActionPreference = "Stop"
Import-Module WebAdministration

$dotnet = "C:\Program Files\dotnet\dotnet.exe"
if (-not (Test-Path $dotnet)) {
    throw "Falta el Hosting Bundle de .NET 9. Instálalo y vuelve a ejecutar este script."
}

$runtimes = & $dotnet --list-runtimes
if ($runtimes -notmatch "Microsoft.AspNetCore.App 9\.") {
    throw "El servidor no tiene el runtime ASP.NET Core 9. Instala el Hosting Bundle de .NET 9."
}

$vc = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" -ErrorAction SilentlyContinue
if (-not $vc -or $vc.Installed -ne 1) {
    throw "Falta Visual C++ 2015-2022 x64 (https://aka.ms/vs/17/release/vc_redist.x64.exe). En IIS 8.5 sin eso el sitio responde 503."
}

$grupo = "TrazabilidadManillas"
if (-not (Test-Path "IIS:\AppPools\$grupo")) {
    New-WebAppPool $grupo | Out-Null
}

Set-ItemProperty "IIS:\AppPools\$grupo" -Name managedRuntimeVersion -Value ""
Set-ItemProperty "IIS:\AppPools\$grupo" -Name managedPipelineMode -Value "Integrated"
Set-ItemProperty "IIS:\AppPools\$grupo" -Name enable32BitAppOnWin64 -Value $false

$asignada = $false
foreach ($sitio in Get-Website) {
    $aplicacion = Get-WebApplication -Site $sitio.Name | Where-Object { $_.path -eq "/TrazabilidadManillas" }
    if (-not $aplicacion) { continue }
    Set-ItemProperty "IIS:\Sites\$($sitio.Name)\TrazabilidadManillas" -Name applicationPool -Value $grupo
    $asignada = $true
    Write-Host "Aplicación $($sitio.Name)/TrazabilidadManillas usa el grupo $grupo"
}

if (-not $asignada) {
    throw "No existe la aplicación IIS /TrazabilidadManillas. Créala en el sitio y vuelve a ejecutar este script."
}

Start-WebAppPool $grupo
Write-Host "Grupo $grupo iniciado."
