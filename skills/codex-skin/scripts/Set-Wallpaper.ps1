[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$MediaPath,
    [ValidateNotNullOrEmpty()][ValidateLength(1,128)][string]$Name = 'Custom theme',
    [ValidateSet('Cover','Contain','Stretch')][string]$Fit = 'Cover',
    [ValidateRange(0,1)][double]$FocusX = 0.5,
    [ValidateRange(0,1)][double]$FocusY = 0.5,
    [ValidateRange(0.60,0.95)][double]$PanelOpacity = 0.65,
    [ValidateRange(0,24)][double]$BlurPx = 6,
    [ValidateRange(0,0.60)][double]$DarkOverlay = 0.20,
    [ValidateRange(0,0.60)][double]$LightOverlay = 0.25,
    [string]$StateDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $StateDirectory) { $StateDirectory = Get-CodexSkinStateDirectory }
$StateDirectory = [IO.Path]::GetFullPath($StateDirectory)
if ($StateDirectory.TrimEnd('\') -ieq ([IO.Path]::GetFullPath((Get-CodexSkinStateDirectory))).TrimEnd('\')) {
    Assert-CodexSkinCompanionStopped
}
$source = (Resolve-Path -LiteralPath $MediaPath).Path
if ($source.StartsWith('\\') -or -not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw 'Choose a regular file on a local disk, not a network share.'
}
$kind = Get-CodexSkinMediaKind $source
$settingsPath = Join-Path $StateDirectory 'settings.json'
$original = $null
$settings = $null
if (Test-Path -LiteralPath $settingsPath) {
    $original = [IO.File]::ReadAllText($settingsPath)
    $settings = $original | ConvertFrom-Json
    if ($settings.schemaVersion -ne 3) { throw 'Existing settings are not schema 3. Open the supported companion to migrate them before retrying.' }
    foreach ($property in @('profiles','mediaCatalog','recentMediaIds','regionBindings','acceptedCdpRisk')) {
        if ($null -eq $settings.PSObject.Properties[$property]) { throw "Existing settings are missing $property. Preserve and repair them before proceeding." }
    }
    if ($settings.acceptedCdpRisk -isnot [bool]) { throw 'Existing debugger acknowledgement is not a Boolean. Preserve and repair the settings first.' }
} else {
    $settings = [pscustomobject]@{
        schemaVersion=3; profiles=@(); mediaCatalog=@(); recentMediaIds=@()
        regionBindings=[pscustomobject]@{}; acceptedCdpRisk=$false
    }
}
$nameTrimmed = $Name.Trim()
if (-not $nameTrimmed) { throw 'The theme name must contain a visible character.' }
$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
$assetDirectory = Join-Path $StateDirectory 'CodexSkinMedia'
$destination = Join-Path $assetDirectory ($hash + [IO.Path]::GetExtension($source).ToLowerInvariant())
$existingMedia = @($settings.mediaCatalog | Where-Object { $_.sourceKind -eq 'LocalFile' -and $_.sourceIdentifier -eq $destination })
$mediaId = if ($existingMedia.Count) { [string]$existingMedia[0].mediaId } else { New-CodexSkinUuid7 }
$matchingProfiles = @($settings.profiles | Where-Object { $_.name -eq $nameTrimmed })
if ($matchingProfiles.Count -gt 1) { throw 'Several profiles have this name. Choose a unique name to avoid replacing the wrong profile.' }
$profileId = if ($matchingProfiles.Count) { [string]$matchingProfiles[0].profileId } else { New-CodexSkinUuid7 }
$profile = [pscustomobject]@{
    profileId=$profileId; name=$nameTrimmed; mediaId=$mediaId; fit=$Fit
    focusX=$FocusX; focusY=$FocusY; panelOpacity=$PanelOpacity; blurPx=$BlurPx
    darkOverlay=$DarkOverlay; lightOverlay=$LightOverlay
    soundEnabled=$false; volume=0.5; performancePolicy='Automatic'
}
$media = [pscustomobject]@{
    mediaId=$mediaId; sourceKind='LocalFile'; sourceIdentifier=$destination
    lastKnownKind=$kind; lastKnownContentKind=$kind; lastKnownDisplayName=$nameTrimmed
}
$settings.profiles = @($settings.profiles | Where-Object { $_.profileId -ne $profileId }) + @($profile)
if (-not $existingMedia.Count) { $settings.mediaCatalog = @($settings.mediaCatalog) + @($media) }
$settings.recentMediaIds = @(@($mediaId) + @($settings.recentMediaIds | Where-Object { $_ -ne $mediaId }) | Select-Object -First 8)
$settings.regionBindings | Add-Member -NotePropertyName Global -NotePropertyValue $profileId -Force

if (-not $PSCmdlet.ShouldProcess($settingsPath, "Save $kind wallpaper preset '$nameTrimmed' and bind it to Global")) { return }
New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $destination)) { Copy-Item -LiteralPath $source -Destination $destination }
$suffix = [Guid]::NewGuid().ToString('N')
$temporary = Join-Path $StateDirectory ('.codex-skin-' + $suffix + '.tmp')
$backup = $null
try {
    [IO.File]::WriteAllText($temporary, ($settings | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    if ($null -ne $original) {
        if ([IO.File]::ReadAllText($settingsPath) -cne $original) { throw 'Settings changed during preparation. Retry after closing the companion.' }
        $backup = Join-Path $StateDirectory ('settings.before-codex-skin-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $suffix + '.json')
        [IO.File]::Replace($temporary, $settingsPath, $backup)
    } else {
        [IO.File]::Move($temporary, $settingsPath)
    }
} finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
}
[pscustomobject]@{ State='Prepared, not applied'; Name=$nameTrimmed; MediaKind=$kind; SettingsPath=$settingsPath; MediaPath=$destination; BackupPath=$backup }
