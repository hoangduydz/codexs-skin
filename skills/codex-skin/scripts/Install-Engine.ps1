[CmdletBinding(SupportsShouldProcess)]
param([string]$EngineDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $EngineDirectory) { $EngineDirectory = Get-CodexSkinEngineDirectory }
$EngineDirectory = [IO.Path]::GetFullPath($EngineDirectory)
$version = 'v1.5.3'
$zipName = "BackdropForCodex-$version-win-x64.zip"
$expected = '47701a7b9a91f8b1450a81f9c1f34e380d72c122047c2c51216dd4c56d13b2ee'
$releaseUrl = "https://github.com/TogawaSakiko-desuwa/backdrop-for-codex/releases/download/$version"
$executable = Join-Path $EngineDirectory 'BackdropForCodex.exe'
$marker = Join-Path $EngineDirectory '.codex-skin-verified.json'
if (Test-Path -LiteralPath $EngineDirectory) {
    if ((Test-Path -LiteralPath $executable) -and (Test-Path -LiteralPath $marker)) {
        $metadata = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
        if ($metadata.archiveSha256 -eq $expected -and $metadata.executableSha256 -eq (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant()) {
            return [pscustomobject]@{ State='Already installed'; EnginePath=$executable; Version=$version }
        }
    }
    throw 'The target engine directory already exists without matching verification metadata. Preserve it and choose an empty EngineDirectory.'
}
if (-not $PSCmdlet.ShouldProcess($EngineDirectory, "Download, verify and extract Backdrop $version from its GitHub release")) { return }
$parent = Split-Path -Parent $EngineDirectory
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$stage = Join-Path $parent ('.download-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
$archive = Join-Path $stage $zipName
$checksumFile = Join-Path $stage 'SHA256SUMS.txt'
$extractDirectory = Join-Path $stage 'extracted'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/$zipName" -OutFile $archive -TimeoutSec 180
Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/BackdropForCodex-$version-SHA256SUMS.txt" -OutFile $checksumFile -TimeoutSec 30
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumLines = Get-Content -LiteralPath $checksumFile
$releaseMatch = @($checksumLines | Where-Object { $_ -match ('(?i)^' + [regex]::Escape($actual) + '\s+\*?' + [regex]::Escape($zipName) + '$') })
if ($actual -ne $expected -or $releaseMatch.Count -ne 1) { throw "Release checksum verification failed. Download retained at $stage; nothing was installed or run." }
Expand-Archive -LiteralPath $archive -DestinationPath $extractDirectory
$stagedExecutable = Join-Path $extractDirectory 'BackdropForCodex.exe'
if (-not (Test-Path -LiteralPath $stagedExecutable -PathType Leaf)) { throw 'Unexpected release layout. Nothing was run.' }
$metadata = [ordered]@{
    version=$version; archiveSha256=$actual
    executableSha256=(Get-FileHash -LiteralPath $stagedExecutable -Algorithm SHA256).Hash.ToLowerInvariant()
    release='https://github.com/TogawaSakiko-desuwa/backdrop-for-codex/releases/tag/v1.5.3'
}
[IO.File]::WriteAllText((Join-Path $extractDirectory '.codex-skin-verified.json'), ($metadata | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
if (Test-Path -LiteralPath $EngineDirectory) { throw 'Target directory appeared during download. Nothing was replaced.' }
# Same-parent directory rename: destination is explicit, absent and inside the chosen parent.
[IO.Directory]::Move($extractDirectory, $EngineDirectory)
[pscustomobject]@{ State='Installed, not launched'; EnginePath=$executable; Version=$version; DownloadCache=$stage }
