MD Viewer — Branding

Overview
- Logomark: `branding/MDViewer-Logomark.svg`
- Wordmark (color): `branding/MDViewer-Logo.svg`
- Wordmark (mono): `branding/MDViewer-Logo-Mono.svg`

Concept
- Document + markdown lines to reflect viewing/reading.
- Subtle brackets nod to markup/code.
- Small spark in teal/cyan to hint at future AI agents/RAG features.

Colors
- Primary Blue: `#0A84FF`
- Indigo Shade: `#2563EB`
- Ink (text): `#0F172A`
- Neutral Lines: `#E5E7EB` / `#F3F4F6`
- AI Spark Gradient: `#22D3EE → #14B8A6`

Usage
- Prefer the color wordmark on light backgrounds.
- Use the mono wordmark for single-color or high-contrast contexts.
- The logomark scales to square app icons and favicons.

App Icon (macOS)
1) Export `branding/MDViewer-Logomark.svg` to a 1024×1024 PNG (no background cropping).
2) Downscale to the required sizes and drop into `md_viewer_xcode/md_viewer_xcode/Assets.xcassets/AppIcon.appiconset/` with the following names:
   - 16x16@1x → `16.png`
   - 16x16@2x → `32.png`
   - 32x32@1x → `32.png`
   - 32x32@2x → `64.png`
   - 128x128@1x → `128.png`
   - 128x128@2x → `256.png`
   - 256x256@1x → `256.png`
   - 256x256@2x → `512.png`
   - 512x512@1x → `512.png`
   - 512x512@2x → `1024.png`

   Tip: names can be anything; just update `Contents.json` entries accordingly in the app icon set. Xcode will pick them up in the asset catalog.

3) Ensure the target’s App Icon is set to `AppIcon` (already configured).

Export Hints
- Keep 80–88% content inset within the square to avoid macOS icon corner clipping.
- Align the spark near the top-right; it should remain legible at 16px.

Web/Favicon
- For web contexts, export 512, 192, 180, 32 and 16 px PNGs from the logomark.

Attribution
- Fonts are system defaults in the SVG. For production, consider converting any text to outlines for pixel-perfect consistency.

