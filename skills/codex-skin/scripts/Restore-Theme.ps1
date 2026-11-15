[CmdletBinding(SupportsShouldProcess)]
param([string]$EngineDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $EngineDirectory) { $EngineDirectory = Get-CodexSkinEngineDirectory }
$executable = Join-Path ([IO.Path]::GetFullPath($EngineDirectory)) 'BackdropForCodex.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Engine not found. Exit Codex completely and reopen it using its original app icon.' }
if ($PSCmdlet.ShouldProcess($executable, 'Open the companion so you can choose Restore official background')) {
    Start-Process -FilePath $executable -WorkingDirectory (Split-Path -Parent $executable)
    Write-Host 'Choose Restore official background in Backdrop. Then exit Codex and Backdrop completely and reopen Codex from its original icon to close the debug session.'
}
