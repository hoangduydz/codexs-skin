[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $repository 'skills\codex-skin\scripts'
$testRoot = Join-Path $repository '.test-work'
$testDirectory = Join-Path $testRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null
$checks = 0

function Assert-Result([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
    Write-Host "PASS: $Message"
}

function Assert-Rejected([scriptblock]$Action, [string]$Message) {
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    Assert-Result $rejected $Message
}

try {
    foreach ($scriptFile in Get-ChildItem -LiteralPath $scripts -Filter '*.ps1') {
        $tokens = $null; $errors = $null
        [Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        Assert-Result ($errors.Count -eq 0) ("PowerShell syntax: " + $scriptFile.Name)
    }

    $image = Join-Path $testDirectory 'sample'' $name.png'
    [IO.File]::WriteAllBytes($image, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aMZkAAAAASUVORK5CYII='))
    $stateDirectory = Join-Path $testDirectory 'state'
    $whatIfDirectory = Join-Path $testDirectory 'what-if-state'
    $set = Join-Path $scripts 'Set-Wallpaper.ps1'
    $name = "Night 'quoted' & saved"
    & $set -MediaPath $image -Name $name -StateDirectory $whatIfDirectory -WhatIf
    Assert-Result (-not (Test-Path -LiteralPath $whatIfDirectory)) '-WhatIf creates no media or settings'

    $firstResult = & $set -MediaPath $image -Name $name -StateDirectory $stateDirectory
    $settingsPath = Join-Path $stateDirectory 'settings.json'
    $first = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Result ($first.profiles.Count -eq 1 -and $first.mediaCatalog.Count -eq 1) 'First save creates one profile and one media entry'
    Assert-Result ($first.profiles[0].name -eq $name) 'Theme names and media paths with shell punctuation are literal data'
    Assert-Result ($first.acceptedCdpRisk -eq $false) 'First save does not accept debugger risk'
    Assert-Result ($first.mediaCatalog[0].lastKnownKind -eq 'Image') 'PNG is routed as Image'
    Assert-Result ((Get-FileHash -LiteralPath $firstResult.MediaPath).Hash -eq (Get-FileHash -LiteralPath $image).Hash) 'Copied media matches the chosen file'

    . (Join-Path $scripts 'Common.ps1')
    $otherProfile = $first.profiles[0] | ConvertTo-Json | ConvertFrom-Json
    $otherProfile.profileId = New-CodexSkinUuid7
    $otherProfile.name = 'Keep this profile'
    $first.profiles = @($first.profiles) + @($otherProfile)
    $first.regionBindings | Add-Member -NotePropertyName Conversation -NotePropertyValue $otherProfile.profileId
    $first.acceptedCdpRisk = $true
    $beforeUpdate = $first | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($settingsPath, $beforeUpdate, [Text.UTF8Encoding]::new($false))
    $updateResult = & $set -MediaPath $image -Name $name -StateDirectory $stateDirectory -PanelOpacity 0.8
    $updated = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Result ($updated.profiles.Count -eq 2 -and $updated.mediaCatalog.Count -eq 1) 'Repeated save updates without duplicating profile or media'
    Assert-Result ($updated.profiles[-1].profileId -eq $first.profiles[0].profileId) 'Updating a profile preserves its identity'
    Assert-Result ($updated.regionBindings.Conversation -eq $otherProfile.profileId) 'Unrelated region binding survives'
    Assert-Result ($updated.acceptedCdpRisk -eq $true) 'Existing user acknowledgement is preserved'
    Assert-Result ([IO.File]::ReadAllText($updateResult.BackupPath) -ceq $beforeUpdate) 'Backup preserves the exact previous settings bytes as UTF-8 text'

    # A minimal container signature exercises metadata routing, not video decoding.
    $video = Join-Path $testDirectory 'header-only.mp4'
    [IO.File]::WriteAllBytes($video, [byte[]](0,0,0,24,102,116,121,112,105,115,111,109,0,0,0,0,105,115,111,109,109,112,52,50))
    & $set -MediaPath $video -Name $name -StateDirectory $stateDirectory | Out-Null
    $videoSettings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $videoMedia = @($videoSettings.mediaCatalog | Where-Object { $_.mediaId -eq $videoSettings.profiles[-1].mediaId })
    Assert-Result ($videoMedia[0].lastKnownKind -eq 'Video' -and $videoMedia[0].lastKnownContentKind -eq 'Video') 'MP4 is routed as Video, not as a still image'

    $fakeVideo = Join-Path $testDirectory 'renamed-image.mp4'
    Copy-Item -LiteralPath $image -Destination $fakeVideo
    $unchangedHash = (Get-FileHash -LiteralPath $settingsPath).Hash
    Assert-Rejected { & $set -MediaPath $fakeVideo -Name $name -StateDirectory $stateDirectory } 'Renaming PNG to MP4 is rejected'
    Assert-Result ((Get-FileHash -LiteralPath $settingsPath).Hash -eq $unchangedHash) 'Rejected media leaves settings untouched'

    $future = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $future.schemaVersion = 999
    $futureJson = $future | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($settingsPath, $futureJson, [Text.UTF8Encoding]::new($false))
    Assert-Rejected { & $set -MediaPath $image -StateDirectory $stateDirectory } 'Unknown settings schema is rejected'
    Assert-Result ([IO.File]::ReadAllText($settingsPath) -ceq $futureJson) 'Unknown schema is preserved without silent migration'

    $installTarget = Join-Path $testDirectory 'engine'
    & (Join-Path $scripts 'Install-Engine.ps1') -EngineDirectory $installTarget -WhatIf
    Assert-Result (-not (Test-Path -LiteralPath $installTarget)) 'Installer -WhatIf downloads and installs nothing'
    Write-Host "All $checks checks passed. No real Codex/Backdrop settings were modified."
} finally {
    # Delete only this test's verified descendant directory, never a computed external path.
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot).TrimEnd('\') + '\'
    $resolvedTestDirectory = [IO.Path]::GetFullPath($testDirectory)
    if (-not $resolvedTestDirectory.StartsWith($resolvedTestRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing cleanup outside the test workspace.'
    }
    if (Test-Path -LiteralPath $resolvedTestDirectory) {
        Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force
    }
}
