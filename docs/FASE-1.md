# Fase 1 — Separación en configurador + programa de inicio

**Estado:** implementada y probada
**Fecha:** 24/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

---

## 1. Decisiones cerradas

| Decisión | Elección |
|---|---|
| Nombre del producto | **DesktopIdentifier** |
| Ejecutables | `DesktopIdentifier.exe` (configurador) y `DesktopIdentifierHost.exe` (inicio) |
| Ubicación | `%LOCALAPPDATA%\DesktopIdentifier\` con todo junto |
| Instalación | Botón **Instalar** explícito; **Aplicar** exige estar instalado |
| Desinstalación | Diálogo con casilla **Conservar la configuración**, marcada por defecto |
| Varios monitores | Se acepta que la banda se repita en todos; el cartel va al monitor elegido |
| Validación | Prueba real en la máquina, con desinstalación y restauración del fondo al terminar |

Consecuencias asumidas:

- Renombrar obligó a migrar nombres de ejecutables, carpeta, INI, valor `Run`,
  clase de ventana, mutex y mensajes. Se hizo de una vez en la fase 1.
- La instalación es por usuario, igual que el arranque.
- El botón **Instalar** aplica también la banda la primera vez para que la
  máquina quede utilizable de una vez. **Aplicar** sigue siendo el único flujo
  que cambia la configuración y nunca copia el host ni escribe en `Run`.

---

## 2. Qué se ha implementado

### Estructura

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

### Programa de inicio (sin VCL)

- Ventana Win32 registrada a mano, sin `TForm`, `TApplication` ni `Controls`.
- Estilos `WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW |
  WS_EX_NOACTIVATE` y `HWND_TOPMOST`.
- GDI+ dibuja el cartel; el resultado se copia a un DIB de 32 bpp
  premultiplicado y se presenta con `UpdateLayeredWindow`.
- `SetTimer` de 3 s para reafirmar el orden superior y recolocar ante cambios de
  área de trabajo, resolución o DPI.
- DPI por monitor (`GetDpiForMonitor`) y selección de monitor por índice.
- Mutex `Local\DesktopIdentifier_Host`; segunda instancia = sale y pide `RELOAD`.
- Mensajes registrados `DesktopIdentifier_RELOAD` y `DesktopIdentifier_QUIT`.
- INI leído con la API de Win32 (sin `System.Classes`, `System.IniFiles` ni VCL).
- Recorte de working set después de pintar.

### Configurador (VCL)

- Ventana de configuración en código, con estado de instalación visible.
- Instalar / Aplicar / Desinstalar / Cerrar el cartel / Cerrar.
- Escritura **atómica** del INI (temporal + `MoveFileEx`).
- Composición de la banda a resolución real, copia del fondo original y
  restauración (incluido el caso de escritorio de color liso).
- Diálogo de desinstalación con `TTaskDialog` y casilla de conservar el INI.
- Modos `/install`, `/apply`, `/uninstall [/discard]`, `/quit` para consola.
- INI nuevo por secciones (`[general]`, `[cartel]`, `[banda]`) con importación
  del formato plano antiguo.

### Comportamiento que cambia respecto a la versión de un solo exe

| Antes | Ahora |
|---|---|
| Un `DistintiveVM.exe` hacía de cartel y de configuración | Dos ejecutables separados |
| El cartel se lanzaba desde `bin\` | Se instala en `%LOCALAPPDATA%` |
| Aplicar copiaba el exe y escribía `Run` | Aplicar solo escribe INI y fondo |
| La casilla de arranque se tocaba en cada Aplicar | El arranque lo gestiona Instalar/Desinstalar |
| `distintive.ini` plano | `desktopidentifier.ini` con secciones |
| El cartel mantenía VCL en memoria (~14,5 MB) | Host sin VCL (~3,2 MB privados) |

Lo que **no** cambia: sin administrador, clic transparente, siempre encima, sin
barra de tareas ni Alt+Tab, banda dentro del fondo, copia y restauración del
fondo original.

---

## 3. Criterios de aceptación

| Criterio | Resultado |
|---|---|
| Host < 1 MB | **439.808 bytes** |
| Host < 10 MB de RAM | working set **0,3–0,9 MB**; privada **~3,2 MB** |
| Instalar una vez: copia + `Run` + arranque | Verificado en `%LOCALAPPDATA%\DesktopIdentifier` |
| Aplicar no cambia el host ni el registro | Hash y fecha del host idénticos; `Run` idéntico |
| Clic transparente, topmost, sin Alt+Tab ni barra | Estilos verificados; `WindowFromPoint` devuelve la ventana de debajo; sin `APPWINDOW` |
| Editar el INI + `RELOAD` actualiza el cartel | 220→260 px sin reiniciar el host |
| Desinstalar deja el sistema como estaba | `Run` borrado; `TranscodedWallpaper` con el hash original; carpeta borrada |
| Arranque tras iniciar sesión | Entrada `Run` verificada y host lanzado desde ella |

### Evidencia de las pruebas

- Ventana del host: `170x170` en `(2360,1192)` con escritorio `2560x1440` y
  barra de tareas (área de trabajo inferior `1392`), es decir, respeta el área
  de trabajo y los márgenes.
- `GetWindowLong(GWL_EXSTYLE)` = `0x080800A8`: incluye `LAYERED` (0x80000),
  `TRANSPARENT` (0x20), `TOOLWINDOW` (0x80), `NOACTIVATE` (0x08000000) y
  `TOPMOST` (0x8); no incluye `APPWINDOW`.
- `WindowFromPoint` en el centro del cartel devolvió otra ventana.
- Aplicar con cambios (`260 px`, azul, banda al 12 %): el PNG cambió, el cartel
  pasó a `260x260`, y el hash/fecha del host y el valor `Run` no cambiaron.
- Desinstalar con conservar: solo quedó `desktopidentifier.ini`.
- Desinstalar con `/discard`: la carpeta desapareció.
- `TranscodedWallpaper` antes y después: mismo SHA-256
  (`8D74321F…F97F7097`).

---

## 4. Cómo reproducir la verificación

```bat
Compilar.cmd --no-pause
bin\DesktopIdentifier.exe /install
:: comprobar carpeta, valor Run y proceso
bin\DesktopIdentifier.exe /apply
:: comparar hash del host instalado y valor Run antes/después
bin\DesktopIdentifier.exe /uninstall
:: comprobar que Run desaparece y que se restaura el fondo
```

Para la recarga en caliente, editar `tamanio` o `color` en
`%LOCALAPPDATA%\DesktopIdentifier\desktopidentifier.ini` y enviar
`DesktopIdentifier_RELOAD` a la ventana `DesktopIdentifierHostWindow` (lo hace
el configurador al aplicar).

---

## 5. Pendiente para la fase 2

- Color, altura y texto de la banda; color del texto del cartel y de la banda.
- Botón **Reaplicar banda** si el usuario cambia el fondo a mano.
- Texto del cartel de hasta 4 caracteres con ajuste de tamaño.
- Valorar icono en la bandeja o menú del host.
- Fase 3: versión visible, reparación de instalaciones huérfanas y actualización
  guiada.

---

## 6. Notas de implementación

- Los `.pas` y `.dpr` con acentos llevan **BOM UTF-8**; sin él Delphi los lee
  como ANSI y los textos salen mal.
- `KEY_WRITE` no incluye permiso de lectura: para leer y borrar valores hay que
  abrir el registro con `KEY_READ or KEY_WRITE`. Fue la causa de que la primera
  versión de `Desinstalar` no borrase la entrada de `Run`.
- `TStringList` obliga a enlazar `System.Classes` y dispara el ejecutable del
  host por encima de 1 MB. Por eso el INI se lee/escribe con `CreateFile`,
  `ReadFile` y `WriteFile`.
- El host recorta su working set después de cada pintura; sin ese recorte el
  working set ronda los 11 MB por las DLL compartidas, aunque la memoria privada
  sea de ~3,2 MB.
