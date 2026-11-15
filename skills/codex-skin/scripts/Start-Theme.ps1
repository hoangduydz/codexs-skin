[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WaitForExit,
    [ValidateRange(1,1800)][int]$TimeoutSeconds = 1800,
    [string]$EngineDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $EngineDirectory) { $EngineDirectory = Get-CodexSkinEngineDirectory }
$executable = Join-Path ([IO.Path]::GetFullPath($EngineDirectory)) 'BackdropForCodex.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Engine missing. Run Install-Engine.ps1 first.' }
if (-not $PSCmdlet.ShouldProcess($executable, 'Launch Backdrop for Codex with --launch to apply the saved profile')) { return }
if ($WaitForExit) {
    Write-Host "Waiting up to $TimeoutSeconds seconds for you to exit Codex. No processes will be terminated."
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while (@(Get-CodexSkinProcesses).Count -gt 0) {
        if ([DateTime]::UtcNow -ge $deadline) { throw 'Timed out. Exit Codex, then run Start-Theme.ps1 again.' }
        Start-Sleep -Seconds 2
    }
} elseif (@(Get-CodexSkinProcesses).Count -gt 0) {
    Write-Warning 'Codex is running. Backdrop may reuse a verified debug session; otherwise it will ask you to exit Codex completely and retry.'
}
Start-Process -FilePath $executable -ArgumentList '--launch' -WorkingDirectory (Split-Path -Parent $executable)
[pscustomobject]@{ State='Companion launched; verify actual Codex wallpaper'; EnginePath=$executable }
