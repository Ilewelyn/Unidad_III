# Aplica los archivos de una ronda del manual (fase rojo o verde) al proyecto Flutter.
# Uso (desde la carpeta del proyecto):   .\_practica\ronda.ps1 2 rojo
#                                        .\_practica\ronda.ps1 2 verde
param(
  [Parameter(Mandatory = $true)][string]$Ronda,
  [string]$Fase = "verde"
)

$proyecto = Split-Path -Parent $PSScriptRoot      # carpeta del proyecto (la que contiene _practica)
$id = $Ronda.ToLower()
if ($id -match '^\d+$') { $id = '{0:D2}' -f [int]$id }

if ($id -eq '05') {
  Write-Host "La Ronda 5 (payload) ya quedo incluida en la fase verde de la Ronda 4. No hay nada que aplicar." -ForegroundColor Yellow
  return
}

$origen = Join-Path $PSScriptRoot "rondas\r$id\$Fase"
if (-not (Test-Path $origen)) {
  Write-Host "No existe la ronda '$Ronda' en fase '$Fase'." -ForegroundColor Red
  Write-Host "Opciones disponibles:"
  Get-ChildItem (Join-Path $PSScriptRoot "rondas") -Directory | ForEach-Object {
    $r = $_.Name.Substring(1)
    $fases = (Get-ChildItem $_.FullName -Directory | ForEach-Object { $_.Name }) -join ", "
    Write-Host ("  {0}  ->  {1}" -f $r, $fases)
  }
  return
}

Copy-Item -Path (Join-Path $origen '*') -Destination $proyecto -Recurse -Force

Write-Host ""
Write-Host "Ronda $Ronda ($Fase): archivos escritos/actualizados" -ForegroundColor Green
Get-ChildItem $origen -Recurse -File | ForEach-Object {
  Write-Host ("  " + $_.FullName.Substring($origen.Length + 1))
}

if ($id -eq '01') {
  # flutter create trae una prueba de ejemplo que no aplica a este proyecto
  $ej = Join-Path $proyecto "test\widget_test.dart"
  if (Test-Path $ej) { Remove-Item $ej; Write-Host "  (se borro test\widget_test.dart de ejemplo)" }
  Push-Location $proyecto
  flutter pub get
  Pop-Location
}
