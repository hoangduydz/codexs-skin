# Theme design workflow

Use this guide to turn a wallpaper or mood reference into a coordinated Codex appearance. It borrows the idea of designing a complete palette around the artwork from Antigravity Custom Theme Skill, while staying within Codex's documented Appearance controls and the separate Backdrop wallpaper companion.

## 1. Read the artwork

Inspect the supplied image or a representative frame from a video. Identify:

- Overall value: dark, midtone, or bright.
- Main surface color: the quietest large area that can sit behind the interface.
- Accent: one saturated color suitable for selection/highlights.
- Secondary accent: optional and less saturated.
- Focal subject and its approximate position in the frame.
- Busy or high-contrast areas that could make text hard to read.

Use image inspection or image-generation tools available in the current environment. If you cannot measure pixels, make clear that color values are visual estimates. Do not invent exact sampled RGB values.

## 2. Make a small palette card

Before changing settings, show a concise proposal with:

| Token | Purpose |
|---|---|
| Mode | Light or Dark base appearance |
| Accent | Main interactive highlight color |
| Background | App surface color, chosen to harmonize with the art |
| Foreground | Text color with strong contrast against the background |
| Wallpaper treatment | Fit, focal point, opacity, blur, and overlay values |

Keep the palette restrained: one primary accent is usually enough. For a dark cinematic image, start with Dark, a muted background sampled by eye, a brighter accent, and near-white foreground. For pastel or daytime art, start with Light, a pale background, a darker accent, and dark foreground. Maintain legible contrast; avoid using the wallpaper's brightest accent as body text.

## 3. Pair native appearance with wallpaper

Codex's desktop **Settings > Appearance** supports a base theme, accent, background, foreground, UI/code fonts, translucent sidebar, and contrast controls. Set these with the official UI when authorized and available. Otherwise provide the exact proposed values and a short manual path; do not modify undocumented configuration files or claim the settings were applied.

Backdrop handles the wallpaper separately. Use `Set-Wallpaper.ps1` options to tune the visible image:

- `-Fit Cover` fills the area and may crop edges; use `-FocusX` and `-FocusY` from 0 to 1 to keep a face or other focal subject in view.
- `-Fit Contain` preserves the whole image but may leave unused space.
- `-PanelOpacity` controls how solid foreground panels appear (0.60–0.95).
- `-BlurPx` controls background blur (0–24 px).
- `-DarkOverlay` / `-LightOverlay` add a tint appropriate to the art and current mode (0–0.60).

Choose the lowest blur/overlay that keeps text readable. Do not over-darken bright artwork or wash out dark artwork. Explain tradeoffs where the focal point conflicts with chat readability.

## 4. Review and refine

Present the chosen media and palette before saving. After launch, inspect the actual Codex window and adjust focal point, crop, panel opacity, blur, or overlay if needed. Change one or two values at a time so the reason for each adjustment is clear. Verify video motion separately from static visibility. A companion preview or generated palette card is not proof that the live app is themed.

## Supported scope

The palette card is a design recommendation, not a Codex theme-import file. Codex native appearance changes are made through its own Settings UI. This skill does not implement arbitrary CSS, SVG ornaments, chat avatars, custom DOM overlays, embedded-browser cutouts, hot reload, or a persistent injection daemon. Those features in Antigravity Custom Theme Skill depend on Antigravity's own UI and engine and must not be presented as Codex capabilities.

Reference: [Codex desktop Settings — Appearance](https://learn.chatgpt.com/docs/reference/settings#appearance).
