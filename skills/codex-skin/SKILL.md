---
name: codex-skin
description: Create and apply local image or looping video wallpaper themes to the official Codex desktop app on Windows 11 using Backdrop for Codex. Use for customizing the actual desktop chat background, translucency, or restoring its appearance; not for building a separate chat website or changing only the Windows desktop wallpaper.
---

# Codex Skin

Make a theme for the user's existing Codex desktop app using a local image or video and a reversible companion. This skill targets Windows 11 x64 and the official Store/MSIX Codex app. It does not patch the application package.

## Select the media and appearance

Use the user's supplied file or visual reference. Respect a request for animation: a PNG or JPG is not an animated wallpaper. If only a still image is available, explain whether the planned result is a moving composition or a genuinely animated character. Do not claim that a still image will blink or move by itself.

For screen recordings, extract only a clean wallpaper segment; exclude desktop icons, chat text, loading marks, and window controls where possible. When a clean original cannot be recovered, disclose the limitation. FFmpeg may trim, encode, or loop video; image generation/editing should use the image tools available in the current environment. Do not redistribute a user's artwork or recordings as part of this skill.

Choose panel opacity and overlays for readable text. The current companion accepts panel opacity 0.60–0.95 and blur 0–24 px. A dark artwork generally works best with Codex's Dark appearance. Do not replace the user's media with a generic preset without their agreement.

## Prepare and apply

Run the bundled scripts using their absolute paths; quote paths and pass user text as literal arguments, never as generated shell code. If already in PowerShell, invoke with `&`.

1. Run `scripts/Get-ThemeStatus.ps1` to inspect the OS, Codex package version, companion state, and presence of debug flags. This is read-only and does not inspect chats or credentials. Stop on an unsupported platform.
2. If the companion is missing, run `scripts/Install-Engine.ps1`. It downloads the pinned upstream release and verifies both a pinned SHA-256 and the release checksum before extracting it. Do not substitute an unverified binary.
3. Exit Backdrop before editing its settings. Run `scripts/Set-Wallpaper.ps1 -MediaPath <absolute-file> -Name <theme-name>` with any chosen appearance options. It copies media into local application data, preserves unrelated profiles and the existing risk acknowledgement, and backs up settings before replacing them. It never sets that acknowledgement to true.
4. Show the resulting media/preset for review. If Codex is already running normally, do not report the theme as applied. Start with `scripts/Start-Theme.ps1`; for an intentional restart handoff, `-WaitForExit` waits at most 30 minutes for the user to exit Codex, then starts the companion once. Do not kill Codex or create persistent startup jobs.
5. Let the user read and handle the companion's own debugger disclosure. The engine communicates through local CDP, which is a privileged debugging interface. Do not automate this acknowledgement or weaken CSP/endpoint checks to force a theme to load.
6. Verify the actual Codex window after launch when the environment permits. A companion preview, saved JSON, or successful process launch alone does not prove that the theme is active. For a video, verify motion as well as visibility. Report separately: media prepared, preset saved, companion launched, and actual wallpaper verified.

Do not automate a desktop app when the current environment's computer-use rules prohibit it. Use an authorized API/read-only diagnostic or ask the user to verify the visible result instead.

## Restore and diagnose

For a visual restore, use Backdrop's **Restore official background**. `scripts/Restore-Theme.ps1` opens the companion and prints the remaining manual steps; it does not claim to remove an injection itself. Completely exit Codex and Backdrop to close the debugging endpoint, then launch Codex from its original icon.

Read [references/runtime.md](references/runtime.md) for the exact commands, compatibility limits, settings contract, and common failure cases. In particular, **Codex already running** means the normal app session must exit before enhanced launch can work. Do not send the user through repeated identical retries.

## Completion

Deliver the chosen image/video, named preset, launch/restore instructions, and the observed validation result. If restarting the app would interrupt this chat, finish preparing everything before the handoff and explicitly leave runtime verification pending. Creating a theme does not authorize posting it, pushing a repository, or publishing private media.
