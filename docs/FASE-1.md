# Phase 1 — Split into configurator + startup program

**Status:** implemented and tested
**Date:** 24/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

> **Note:** phase 2 (band color, height and text, text color and Reapply band)
> was implemented later; see [FASE-2.md](FASE-2.md).

---

## 1. Closed decisions

| Decision | Choice |
|---|---|
| Product name | **DesktopIdentifier** |
| Executables | `DesktopIdentifier.exe` (configurator) and `DesktopIdentifierHost.exe` (startup) |
| Location | `%LOCALAPPDATA%\DesktopIdentifier\` with everything together |
| Installation | Explicit **Install** button; **Apply** requires being installed |
| Uninstallation | Dialog with a **Keep the settings** checkbox, checked by default |
| Multiple monitors | It is accepted that the band is repeated on all of them; the badge goes to the chosen monitor |
| Validation | Real test on the machine, with uninstallation and wallpaper restoration at the end |

Assumed consequences:

- Renaming forced migrating executable names, folder, INI, `Run` value,
  window class, mutex and messages. It was all done at once in phase 1.
- The installation is per user, just like startup.
- The **Install** button also applies the band the first time so that the
  machine is usable right away. **Apply** is still the only flow that changes
  the settings, and it never copies the host or writes to `Run`.

---

## 2. What has been implemented

### Structure

```
DesktopIdentifier.groupproj
Compilar.cmd / Configurar.cmd
src\common\   uPaths.pas, uUtils.pas, uSettings.pas, uBadgeRender.pas
src\host\     DesktopIdentifierHost.dpr, uHostWindow.pas,
              DesktopIdentifierHost.manifest, HostResources.rc
src\config\   DesktopIdentifier.dpr, uConfigForm.pas, uBandRender.pas,
              uWallpaper.pas, uStartup.pas, uInstall.pas,
              DesktopIdentifier.manifest, ConfigResources.rc
```

### Startup program (without VCL)

- Hand-registered Win32 window, without `TForm`, `TApplication` or `Controls`.
- Styles `WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW |
  WS_EX_NOACTIVATE` and `HWND_TOPMOST`.
- GDI+ draws the badge; the result is copied to a premultiplied 32 bpp DIB
  and presented with `UpdateLayeredWindow`.
- 3 s `SetTimer` to reassert the topmost order and reposition on changes of
  work area, resolution or DPI.
- Per-monitor DPI (`GetDpiForMonitor`) and monitor selection by index.
- Mutex `Local\DesktopIdentifier_Host`; second instance = exits and requests `RELOAD`.
- Registered messages `DesktopIdentifier_RELOAD` and `DesktopIdentifier_QUIT`.
- INI read with the Win32 API (without `System.Classes`, `System.IniFiles` or VCL).
- Working-set trim after painting.

### Configurator (VCL)

- Settings window in code, with visible installation state.
- Install / Apply / Uninstall / Close the badge / Close.
- **Atomic** INI writing (temporary + `MoveFileEx`).
- Band composition at real resolution, copy of the original wallpaper and
  restoration (including the solid-color desktop case).
- Uninstall dialog with `TTaskDialog` and a keep-the-INI checkbox.
- `/install`, `/apply`, `/uninstall [/discard]`, `/quit` modes for the console.
- New INI with sections (`[general]`, `[cartel]`, `[banda]`) with import of the
  old flat format.

### Behavior that changes compared to the single-exe version

| Before | Now |
|---|---|
| A single `DistintiveVM.exe` acted as both badge and configurator | Two separate executables |
| The badge was launched from `bin\` | It is installed in `%LOCALAPPDATA%` |
| Apply copied the exe and wrote `Run` | Apply only writes INI and wallpaper |
| The startup checkbox was touched on every Apply | Startup is managed by Install/Uninstall |
| Flat `distintive.ini` | `desktopidentifier.ini` with sections |
| The badge kept VCL in memory (~14.5 MB) | Host without VCL (~3.2 MB private) |

What does **not** change: no administrator, click-through, always on top,
without taskbar or Alt+Tab, band inside the wallpaper, copy and restoration of
the original wallpaper.

---

## 3. Acceptance criteria

| Criterion | Result |
|---|---|
| Host < 1 MB | **439,808 bytes** |
| Host < 10 MB of RAM | working set **0.3–0.9 MB**; private **~3.2 MB** |
| Install once: copy + `Run` + start | Verified in `%LOCALAPPDATA%\DesktopIdentifier` |
| Apply does not change the host or the registry | Identical host hash and date; identical `Run` |
| Click-through, topmost, no Alt+Tab or taskbar | Styles verified; `WindowFromPoint` returns the window underneath; no `APPWINDOW` |
| Edit the INI + `RELOAD` updates the badge | 220→260 px without restarting the host |
| Uninstall leaves the system as it was | `Run` deleted; `TranscodedWallpaper` with the original hash; folder deleted |
| Startup after signing in | `Run` entry verified and host launched from it |

### Test evidence

- Host window: `170x170` at `(2360,1192)` with a `2560x1440` desktop and
  taskbar (bottom work area `1392`), that is, it respects the work area and
  the margins.
- `GetWindowLong(GWL_EXSTYLE)` = `0x080800A8`: it includes `LAYERED` (0x80000),
  `TRANSPARENT` (0x20), `TOOLWINDOW` (0x80), `NOACTIVATE` (0x08000000) and
  `TOPMOST` (0x8); it does not include `APPWINDOW`.
- `WindowFromPoint` at the badge center returned another window.
- Apply with changes (`260 px`, blue, band at 12%): the PNG changed, the badge
  became `260x260`, and the host hash/date and the `Run` value did not change.
- Uninstall keeping the settings: only `desktopidentifier.ini` remained.
- Uninstall with `/discard`: the folder disappeared.
- `TranscodedWallpaper` before and after: same SHA-256
  (`8D74321F…F97F7097`).

---

## 4. How to reproduce the verification

```bat
Compilar.cmd --no-pause
bin\DesktopIdentifier.exe /install
:: check folder, Run value and process
bin\DesktopIdentifier.exe /apply
:: compare installed host hash and Run value before/after
bin\DesktopIdentifier.exe /uninstall
:: check that Run disappears and that the wallpaper is restored
```

For hot reload, edit `tamanio` or `color` in
`%LOCALAPPDATA%\DesktopIdentifier\desktopidentifier.ini` and send
`DesktopIdentifier_RELOAD` to the `DesktopIdentifierHostWindow` window (the
configurator does this when applying).

---

## 5. Pending for phase 2

- Band color, height and text; badge and band text color.
- **Reapply band** button if the user changes the wallpaper by hand.
- Badge text of up to 4 characters with size adjustment.
- Consider a tray icon or host menu.
- Phase 3: visible version, repair of orphan installations and guided update.

---

## 6. Implementation notes

- The `.pas` and `.dpr` files with accents carry a **UTF-8 BOM**; without it
  Delphi reads them as ANSI and the texts come out wrong.
- `KEY_WRITE` does not include read permission: to read and delete values you
  must open the registry with `KEY_READ or KEY_WRITE`. This was the cause of the
  first version of `Desinstalar` not deleting the `Run` entry.
- `TStringList` forces linking `System.Classes` and pushes the host executable
  above 1 MB. That is why the INI is read/written with `CreateFile`, `ReadFile`
  and `WriteFile`.
- The host trims its working set after every paint; without that trim the
  working set is around 11 MB due to the shared DLLs, even though private
  memory is ~3.2 MB.
