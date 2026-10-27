# Phase 2 — Configurable badge and band

**Status:** implemented and tested
**Date:** 24/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

> **Note:** this phase describes the original two tabs (Badge and Band). The
> **Desktop** tab, with original/solid/gradient backgrounds and two labels, was
> added later; see [FASE-3.md](FASE-3.md), section 9. The visible product name is
> now **Desktop Identifier**; technical filenames and paths keep
> `DesktopIdentifier`.

---

## 1. What has been added

The settings window now has **two tabs**:

- **Badge:** any text (the window widens horizontally to fit it), panel color,
  text color, size, panel opacity, text opacity, corner radius and margins.
- **Band:** active yes/no, color, text color, height, text and alignment
  (right, center, left).

Also:

- **Reapply band**: recomposes the wallpaper with the current settings. It is
  useful when the user changes the desktop wallpaper by hand.
- **Faithful preview**: uses the same `DibujarDistintivo` and `DibujarBanda` as
  the host and the wallpaper generator, with the real text and colors.
- The **badge text color** and the **band text color** are now really used
  (before they were saved but the badge painted white).
- The badge window **widens horizontally** to fit any text; a single character
  keeps the square shape. The band text is reduced if it does not fit in width.

### New keys

| Key | Values | Notes |
|---|---|---|
| `banda.alineacion` | `derecha` / `centro` / `izquierda` | `derecha` by default |

`[general] version` becomes **2**. INIs with version 1 are read without
problems: the alignment takes the default value and the rest is preserved.

---

## 2. Included fixes

### Last character clipped

With texts of more than one character, GDI+ drew only the first ones: `VM1` came
out as `VM` and `ABCD` as `ABC`.

Cause: `MeasureString` was called with the badge rect (200 px) and GDI+
returned the **clipped width** (131.08 px for `ABCD` instead of 386.81 px). The
fit factor came out 1.0, the text was drawn at full size and GDI+ cut off what
did not fit in the rect.

Solution: measure with a large rect (`Px * 10`) to get the real width and
calculate the factor correctly before drawing.

### UTF-8 BOM

When editing the `.pas` files with accents, the editor removed the BOM and the
first build of phase 2 showed "ConfiguraciÃ³n" in the title. The UTF-8 BOM must
be checked/restored after editing sources with accents.

---

## 3. Acceptance criteria

| Criterion | Result |
|---|---|
| Change band color and height and see it when applying | Band `#2A9D8F` at **14%**: 202 px in the PNG (14% of 1440) |
| Different text in band and badge | Badge `B2`, band `PRODUCCIÓN` |
| Changes are saved and survive a restart | INI with `texto=B2`, `alto=0.14`, `alineacion=centro`; after closing and relaunching the host it is still `B2` |
| The preview matches the real result | Same renderer; screenshots of the UI and of the real badge |
| Out-of-range values are clamped without breaking | Unit test: `alto=0.5` → 0.20; text of 25 → 20; invalid alignment → `derecha`; 0 failures |

### Evidence

- Real badge: `B2` yellow (`#FFD166`) over a purple panel (`#7B2CBF`), 200 px,
  corners at 30%, panel at 45% and text at 80%.
- Real band: blue-green (`#2A9D8F`), 14%, `PRODUCCIÓN` centered in white.
- **Apply** button of the UI: I typed `B2` in the field, moved the height slider
  to 14% and pressed Apply; the INI, the PNG and the badge changed.
- **Reapply band:** I set the original wallpaper by hand, pressed the button and
  `fondo-distintivo.png` came back with the band.
- **Persistence:** `/quit` and relaunch the host; it kept showing `B2` with the
  same colors.

---

## 4. Measurements

| | Size | RAM |
|---|---|---|
| Host | **440,320 B** | working set ~0.31 MB; private ~3.27 MB |
| Configurator | **2,684,928 B** | VCL, only when opened |

The host grows ~512 B compared to phase 1 because of the `ColorTexto` field in
the style.

---

## 5. Tests performed

- Clean build of the group and of both executables.
- Two UI screenshots (Badge and Band tabs) and accent check.
- Cropping of the generated PNG: band color, height and text.
- Desktop corner screenshot: badge `VM1` first and `B2` later.
- Text and height change from the UI and Apply.
- Reapply after changing the wallpaper.
- Close/relaunch the host.
- Unit test of `uSettings`: defaults, round-trip, ranges, invalid alignment,
  old INI migration and `version=2`.
- Final uninstall with `/discard`: `Run` deleted, folder deleted and
  `TranscodedWallpaper` restored with the original hash.

---

## 6. Pending for phase 3

- Visible version and guided host update.
- Detection/repair of orphan installations.
- Tray icon or host menu (decision postponed).
- Optional: band gradient/shadow, color copy between badge and band.
- Automatic adjustment of the band text if it is too long on small screens.
