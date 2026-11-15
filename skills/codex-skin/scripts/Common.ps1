Set-StrictMode -Version Latest

function Get-CodexSkinStateDirectory {
    Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexWallpaper'
}

function Get-CodexSkinEngineDirectory {
    Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexSkin\engine\v1.5.3'
}

function New-CodexSkinUuid7 {
    $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString('x12')
    $random = [Guid]::NewGuid().ToString('N')
    '{0}-{1}-7{2}-a{3}-{4}' -f $stamp.Substring(0,8), $stamp.Substring(8,4), $random.Substring(0,3), $random.Substring(3,3), $random.Substring(6,12)
}

function Assert-CodexSkinCompanionStopped {
    if (Get-Process -Name BackdropForCodex -ErrorAction SilentlyContinue) {
        throw 'Exit Backdrop for Codex from its system tray menu before changing its saved settings.'
    }
}

function Get-CodexSkinProcesses {
    $prefix = Join-Path $env:ProgramFiles 'WindowsApps\OpenAI.Codex_'
    @(Get-Process -Name ChatGPT -ErrorAction SilentlyContinue | Where-Object {
        try { -not $_.Path -or $_.Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) }
        catch { $true }
    })
}

function Get-CodexSkinMediaKind([string]$Path) {
    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $stream = [IO.File]::OpenRead($Path)
    try {
        $header = New-Object byte[] 16
        $count = $stream.Read($header, 0, $header.Length)
        if ($count -lt 12) { throw 'The media file is too short to identify.' }
        $hex = [BitConverter]::ToString($header)
        $ascii = [Text.Encoding]::ASCII.GetString($header)
        $isImage = ($extension -eq '.png' -and $hex.StartsWith('89-50-4E-47-0D-0A-1A-0A')) -or
            ($extension -in @('.jpg','.jpeg') -and $hex.StartsWith('FF-D8-FF')) -or
            ($extension -eq '.webp' -and $ascii.StartsWith('RIFF') -and $ascii.Substring(8,4) -eq 'WEBP')
        $isVideo = ($extension -eq '.mp4' -and $ascii.Substring(4,4) -eq 'ftyp') -or
            ($extension -eq '.webm' -and $hex.StartsWith('1A-45-DF-A3'))
        if ($isImage -and $stream.Length -le 512MB) { return 'Image' }
        if ($isVideo -and $stream.Length -le 8GB) { return 'Video' }
        throw 'Unsupported media, mismatched file header, or size limit exceeded. Use PNG/JPEG/WebP (up to 512 MiB), or MP4/WebM (up to 8 GiB).'
    } finally { $stream.Dispose() }
}
