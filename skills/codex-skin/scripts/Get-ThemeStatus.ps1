[CmdletBinding()]
param([string]$EngineDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $EngineDirectory) { $EngineDirectory = Get-CodexSkinEngineDirectory }
$operatingSystem = Get-CimInstance Win32_OperatingSystem
$packages = @(Get-AppxPackage -Name OpenAI.Codex -ErrorAction SilentlyContinue)
$runningCodex = @(Get-CodexSkinProcesses)
$debugProcessCount = @(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" | Where-Object {
    $_.ExecutablePath -and $_.ExecutablePath.StartsWith((Join-Path $env:ProgramFiles 'WindowsApps\OpenAI.Codex_'), [StringComparison]::OrdinalIgnoreCase) -and
    $_.CommandLine -match '--remote-debugging-(port|pipe)'
}).Count
[pscustomobject]@{
    OperatingSystem=$operatingSystem.Caption
    Architecture=$operatingSystem.OSArchitecture
    SupportedOS=([Environment]::Is64BitOperatingSystem -and $operatingSystem.Caption -match 'Windows 11' -and $env:PROCESSOR_ARCHITECTURE -ne 'ARM64')
    CodexPackageVersions=@($packages | ForEach-Object { $_.Version.ToString() })
    CodexProcessCount=$runningCodex.Count
    DebugFlagProcessCount=$debugProcessCount
    CompanionRunning=([bool](Get-Process -Name BackdropForCodex -ErrorAction SilentlyContinue))
    EnginePresent=(Test-Path -LiteralPath (Join-Path $EngineDirectory 'BackdropForCodex.exe'))
    WallpaperVerified=$false
    Note='Debug flags and previews do not prove a live wallpaper is active. Verify the Codex window and animation separately.'
}
