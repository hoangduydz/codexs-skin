# Runtime notes

## Supported path and current evidence

This package is an agent skill plus PowerShell helpers. **Backdrop for Codex**, a separate community project, implements media playback and CDP injection. The skill is not a native Codex extension or an OpenAI product.

The pinned dependency is Backdrop **v1.5.3**, for Windows 11 x64 and the official Store/MSIX Codex app. Its README documents layout support for Codex 26.924 / 26.1007. Do not infer compatibility with every newer version. The author's local 26.1111.2228.0 setup demonstrated media/preset preparation and the companion's explicit rejection of an already-running normal Codex session; that alone does not prove successful background injection on that build.

Check the current upstream compatibility notes when diagnosing a newer app. The version/hash pin must be updated together after reviewing a new release. Do not silently switch to a different injector, patch the application archive, bypass CSP, or bypass the companion's identity checks.

Sources:

- [Codex appearance settings](https://learn.chatgpt.com/docs/reference/settings#appearance): native colors/fonts/translucency.
- [Backdrop for Codex](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex): actual playback and injection engine.
- [Pinned release v1.5.3](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex/releases/tag/v1.5.3).
- [Upstream threat model](https://github.com/TogawaSakiko-desuwa/backdrop-for-codex/blob/main/THREAT_MODEL.md): local debugging is privileged; loopback is not process isolation.
- [ClaudeSkin](https://github.com/khoyga007/ClaudeSkin): conceptual reference for reversible runtime styling. This package does not use its injector or themes.

## Commands

In PowerShell, first change to the skill's `scripts` directory, or use absolute script paths:

```powershell
& .\Get-ThemeStatus.ps1
& .\Install-Engine.ps1
& .\Set-Wallpaper.ps1 -MediaPath 'D:\Wallpapers\night.mp4' -Name 'Night Live' -PanelOpacity 0.60 -DarkOverlay 0.18
& .\Start-Theme.ps1
& .\Restore-Theme.ps1
```

If a restart needs a handoff:

```powershell
& .\Start-Theme.ps1 -WaitForExit -TimeoutSeconds 1800
```

This waits in the current process. It does not create a service, startup shortcut, scheduled task, or detached process. The user exits Codex themselves. If explicitly asked to launch a hidden one-time helper, run this script with an appropriate hidden PowerShell process and state the waiting deadline. Do not present a background waiter as a verified application result.

`Set-Wallpaper.ps1` supports PNG/JPEG/WebP and MP4/WebM. Its header/size check is a preflight, not a full codec or image validation. Backdrop performs its own validation. GIF is not accepted by this helper: convert it to a compatible MP4/WebM first if animation is intended. Videos are silent and looping. Settings paths are chosen at runtime, never committed with the skill.

Use `-WhatIf` with install, set, start, or restore to inspect planned mutations. `-StateDirectory` and `-EngineDirectory` permit isolated testing or an explicit alternate setup; do not point them at another application's data. An alternate state directory is for preparation/testing and is **not** automatically loaded by the upstream engine, which uses its normal application-data directory.

## Stored state and backups

- Engine: `%LOCALAPPDATA%\CodexSkin\engine\v1.5.3`.
- Upstream state: `%LOCALAPPDATA%\CodexWallpaper\settings.json`, schema 3.
- Media copies: `%LOCALAPPDATA%\CodexWallpaper\CodexSkinMedia`, named by content hash.
- Backup: `settings.before-codex-skin-<timestamp>-<id>.json` beside the settings file.

The helper updates a uniquely named profile and the Global binding; it preserves other profiles, region-specific overrides, and the existing `acceptedCdpRisk` Boolean. A first-time configuration sets that Boolean to false. It must be acknowledged through the companion, not pre-approved by the skill.

Close the companion before editing live state. Settings publication uses a temporary file and an atomic replacement with backup, with a check for concurrent edits. To restore the saved settings manually, close Backdrop, preserve the current file, and copy the chosen backup to `settings.json`. Restoring a file does not itself remove an active runtime injection; use the companion's restore action or fully exit Codex.

## Common failures

| Symptom | Next action |
|---|---|
| Codex already running / Cannot start Codex safely | Fully exit every normal Codex window and tray process. Launch through `Start-Theme.ps1` or the companion's enhanced-launch shortcut. Never terminate active work automatically. |
| Companion shows media, Codex remains unchanged | Check enhanced launch, target/page compatibility, and the companion's error details. Preview success is not injection success. |
| Unsupported Codex layout or missing verified endpoint | Preserve the checks and report the exact version/error. Research a reviewed upstream fix rather than repeatedly retrying or disabling checks. |
| PNG/JPG selected for an animation request | Prepare a real video and set a Video profile. A still-file rename to `.mp4` does not work. |
| Media not decodable | Use a supported codec/container, commonly H.264 MP4 with yuv420p, and verify actual playback. |
| Wallpaper disappears after ordinary app launch | Use enhanced launch again. Runtime themes are not permanent application-package modifications. |
| App update breaks the theme | Restore the official background, inspect upstream compatibility, and review a newer release before changing the version/hash pin. |

Do not claim chats/credentials are protected merely because the theme is decorative. CDP can control the running app. The scripts do not inspect chats or provider configuration, but this package is not a security audit or guarantee of the upstream application.
