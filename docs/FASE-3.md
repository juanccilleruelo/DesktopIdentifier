# Phase 3 — Version, update and repair

**Status:** implemented and tested
**Date:** 26/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

---

## 1. What has been added

### Visible version

- The version of each executable lives in its resources (`*Resources.rc`) and is
  read with `GetFileVersionInfo` (`uVersion.pas`).
- The configurator shows **its** version in the header
  (`… · v1.1.0.0`) and the **installed host's** in the status line
  (`Installed · host 1.1.0.0 · …`).
- The INI `[general] version` is still 2; the product version is independent.

### Guided update

- When the window opens, the versions of the installed host and of the host
  that comes with the configurator are compared.
- If the available one is higher, the status changes to
  `Installed · host 1.0.0.0 → 1.1.0.0 available`, the button changes to
  **Update** and it is explained in the message line.
- Pressing **Update** asks for confirmation; then the badge is closed, the new
  host is copied, it is relaunched and the band is regenerated with the current
  settings.
- **The INI and the startup entry are not touched.** The update is the only
  exception to "Apply does not copy".
- `ActualizarHost` lives in `uInstall.pas` and writes neither the INI nor the
  registry.

### Detection and repair of incomplete installations

`EstadoInstalacion` checks, in addition to the above:

| Situation | Message |
|---|---|
| Host installed without startup entry | "Automatic startup is missing." |
| `Run` points to another path | "The startup entry points to another path." |
| Host installed without INI | "The configuration file is missing." |
| `Run` exists but the host does not | "Startup points to a program that no longer exists." |
| Folder with leftovers but no host | "Leftovers of a previous installation remain." |
| Badge running but not installed | "There is a badge running that is not installed." |

The window shows **Incomplete installation · press Repair** and the button
changes to **Repair**, which leaves the installation complete again
(`Install` + `Apply`).

### Long band text

`DibujarBanda` measures the text with a large rect and reduces the font if it
does not fit in width, with a minimum of 6 px. A 20-character text in a narrow
band is no longer clipped.

---

## 2. Behavioral changes

- Install / Update / Repair / Reinstall share a button and change text according
  to the state; the user does not need to know which flow applies.
- The update asks for confirmation and preserves the settings and startup.
- Repair may rewrite the INI with whatever the window has loaded; if the INI
  was missing, it is created with the default values (there is nothing to
  preserve).
- The product version becomes **1.1.0.0** in both `.rc` files and in
  `VersionProducto`.

---

## 3. Evidence

### Update 1.0.0.0 → 1.1.0.0

The machine had a 1.0.0.0 host of **2,763,410 B** installed (built in Debug from
the IDE) with the `texto=text` setting.

- The window showed `Installed · host 1.0.0.0 → 1.1.0.0 available`, an
  **Update** button and the corresponding notice.
- After confirming: installed host **1.1.0.0**, **440,320 B**; process running;
  `Run` identical; INI with `texto=text`; band regenerated.
- The window header showed `v1.1.0.0`.

### Repair

- **No `Run`:** **Repair** button, message "Automatic startup is missing.";
  after repairing, `Run` restored, host running and `texto=text` preserved.
- **`Run` to `C:\no-existe\...`:** **Repair** button; after repairing, `Run`
  pointing to the installed host.
- **No INI:** **Repair** button, message "The configuration file is missing.";
  the user's INI was restored after checking the detection.

### Long text

Rendering test with `MÁQUINA DE PRODUCCIÓN` (20 characters) in a 700 × 120 px
band: the text is reduced and remains complete, with margins and centered.

---

## 4. Measurements

| | Size | RAM |
|---|---|---|
| Host 1.1.0.0 | **491,008 B** | working set ~0.9 MB; private ~3.2 MB |
| Configurator 1.1.0.0 | **3,148,800 B** | VCL, only when opened |

The update replaced the 2.76 MB Debug host with the 440 KB Release one. The
localization change later added the language tables; see section 7.

---

## 5. Screenshots

The screenshots of the final window are in
[docs/capturas/cartel.png](capturas/cartel.png),
[docs/capturas/banda.png](capturas/banda.png) and
[docs/capturas/desktop.png](capturas/desktop.png). The composed result with the
desktop labels is in
[docs/capturas/resultado-desktop.png](capturas/resultado-desktop.png).

---

## 6. Later changes — icon and taskbar (27/10/2026)

The configurator now behaves like a normal program in the taskbar; the host does
not change.

- `src/config/DesktopIdentifier.ico` was added (16, 20, 24, 32, 40, 48, 64,
  128 and 256 px; 381,038 B) and embedded as `MAINICON` **only** in
  `ConfigResources.rc`.
- The window changed from `bsDialog` to `bsSingle` with
  `BorderIcons := [biSystemMenu, biMinimize]`. The reason is that VCL's
  `TCustomForm.CreateWnd` explicitly clears the icon when `BorderStyle` is
  `bsDialog`.
- `WS_EX_APPWINDOW` is forced and `ShowInTaskbar` is enabled; in `CreateWnd`,
  `WM_SETICON` is set with the large icon and with a 16 px variant for the
  title.
- The host is still `WS_EX_TOOLWINDOW`, without `APPWINDOW`, without its own
  icon and without a taskbar button.

Checks: `WM_GETICON` large and small different from zero, `WS_EX_APPWINDOW`
active, without `WS_MAXIMIZEBOX` or `WS_THICKFRAME`, and the button with the
icon visible in the taskbar. The configurator measured **3,075,072 B**; the host
was still **440,320 B**. The version did not change (1.1.0.0), because that
change did not touch the host.

---

## 7. Later changes — localization (27/10/2026)

The UI now follows the Windows locale; the host is also localized.

- `src/common/Languages.pas` contains the tables for Spanish, English, French,
  Italian and German. `GetUserDefaultLocaleName` decides: `es-*`, `fr-*`,
  `it-*` and `de-*` select their language; any other locale selects English.
  If the API fails, `GetUserDefaultUILanguage` is used as a fallback.
- The configurator uses the unit for every caption, label, button, status
  message, task dialog and installer/update/repair message.
- The host uses it for its window title and for the error message shown if it
  cannot start. It is still a tool window: no icon and no taskbar button.
- The INI comments and the Markdown documentation are always in English. The
  INI keys keep their names (`cartel`, `banda`, `texto`, etc.).
- Adding a language means adding a column to the table and a case in the
  detector; there is no environment variable or manual selector.

Checks: with the Windows locale set to `es-ES`, `en-US`, `fr-FR`, `it-IT` and
`de-DE`, the window title changed to `Configuración`, `Settings`, `Paramètres`,
`Impostazioni` and `Einstellungen`; the Spanish, English, French, German and
Italian layouts were inspected. The host window title follows the same table.
The configurator measures **3,148,800 B**; the host **491,008 B**. The version
remains 1.1.0.0; the installed host was replaced with the new binary.

---

## 8. Later changes — text, tabs and colors (27/10/2026)

- Badge and band text no longer have a length limit: the edit fields use
  `MaxLength = 0` and `AjustesValidos` does not truncate them. The host measures
  the badge text and widens the window horizontally; a single character keeps
  the square shape. The preview also grows and is scaled down only when it
  would not fit in the preview area.
- The tab captions use a bold, 10 pt font (`TPageControl.Font`); the controls
  inside the tabs keep their normal 9 pt font, except the colour hex labels and
  the percentage labels.
- The **Band** tab has a *Synchronize badge and band colors* checkbox, checked
  by default. While it is checked, the band colour follows the badge colour and
  the band colour controls are disabled. The state is stored as
  `banda.color_sincronizado` (default `1`); the INI keeps the band colour for
  when synchronization is off.

Checks: a badge text of `A` produced a 170 × 170 window; `DESKTOP-A` produced
706 × 170 with the full text; the Band tab showed the sync checkbox checked and
the band colour controls disabled. The configurator measures **3,148,800 B**;
the host **491,008 B**.

---

## 9. Later changes — Desktop tab (27/10/2026)

A third tab, **Desktop**, controls the base wallpaper and two labels:

- Background type: **original wallpaper**, **solid color** or **gradient**. The
  original is the copy saved by `PrepararOriginal`; a solid color uses one
  colour and a gradient blends two colours from top to bottom.
- Two optional labels. The large one is centered on the desktop; the small one
  is placed below it, at 42 % of the large size. Both use the selected font
  family and the base size, scaled from the 1080p reference to the real screen.
  The labels are white with a shadow and are drawn before the band, so the band
  stays on top.
- `PrepararOriginal` is now called for any generated desktop, not only when the
  band is active. The original wallpaper and its style are still restored on
  uninstall.
- The settings live in `[desktop]`: `fondo` (`original`, `solido`,
  `degradado`), `color`, `color2`, `texto_grande`, `texto_pequeno`, `fuente`
  and `tamano`.

Checks: the three backgrounds were applied and inspected at 2560 × 1440; the
large label stayed centered and the small label below it. The configurator
measures **3,148,800 B**; the host **491,008 B**. The screenshot is
[docs/capturas/resultado-desktop.png](capturas/resultado-desktop.png).

---

## 10. Later changes — visible name and hint labels (27/10/2026)

- The user-facing name is **Desktop Identifier** in the window title, the header,
  the host window title, the uninstall dialog and the executable version
  metadata. Executable filenames, the data folder, the installation path, the
  `Run` value, the mutex and the registered messages keep the historical
  `DesktopIdentifier` spelling so existing installations and messages continue
  to work.
- The **No limit** hint next to the badge text and the **Empty = no text** hint
  next to the band text were removed; the text fields are still unbounded and an
  empty field still means no text.
- Both executables and the installer were rebuilt. The configurator measures
  **3,148,800 B**, the host **491,008 B**, and the installer
  `dist\DesktopIdentifier-Setup.exe` measures **3,258,381 B**
  (SHA-256 `9D11AD53F7502C945722751B3EC591E165EE55497FD8064177E50D10DAD2895D`).
  The version remains 1.1.0.0.

---

## 11. Pending (optional)

- Tray icon or host menu.
- Band gradient/shadow and color copy between badge and band.
- Digital signature and the host's own icon, if desired.

The mandatory list of phase 3 is closed.
