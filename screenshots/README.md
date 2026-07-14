# Screenshots

These images are embedded in the project [README](../README.md).

- `02-home.png` is a **real capture**.
- The rest are **placeholders** — replace them with real captures using the same file names.

## How to capture (recommended)

The app exposes a screenshot deep-link so you can jump straight to any screen:

```
?shot=splash | home | library | game | result | profile | settings
```

1. Run the web build:
   ```bash
   flutter run -d chrome --web-port 5556
   ```
2. Open a screen directly, e.g. `http://localhost:5556/?shot=game`
   (`game` auto-plays so the notes/HUD are lively; `library` = Song Selection).
3. Capture a clean phone frame with Chrome DevTools:
   - `F12` → toggle **Device Toolbar** (`Ctrl+Shift+M`) → pick a phone (e.g. Pixel 7)
   - `⋮` menu in the device bar → **Capture screenshot**
4. Save over the matching file here (keep the names): `01-splash.png`, `02-home.png`, `03-song-selection.png`, `04-gameplay.png`, `05-result.png`, `06-profile.png`, `07-settings.png`.

> A DevTools device-toolbar capture renders CanvasKit reliably and gives you a crisp, correctly-sized mobile frame. (Fully headless `--screenshot` runs can come out blank for CanvasKit apps depending on the machine's GPU.)
