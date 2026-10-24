# DesktopIdentifier

**Know which machine you're working on.**

Marca visual permanente para distinguir dos máquinas virtuales clonadas que
comparten anfitrión:

- **Banda de color** en la parte superior del escritorio, integrada en el fondo
  de pantalla, con color, altura, texto y alineación configurables.
- **Cartel flotante** con el texto que quieras (1–4 caracteres), color de panel
  y de texto, tamaño, opacidades y esquinas; semitransparente, siempre encima y
  que **no captura el ratón**: los clics atraviesan el cartel.
- **Configuración** en dos pestañas (Cartel y Banda), con vista previa fiel y
  botón **Reaplicar banda**.
- **Arranque automático** con la sesión de Windows.

No requiere administrador: todo es por usuario (`HKCU` y
`%LOCALAPPDATA%\DesktopIdentifier`).

---

## Cómo está organizado

Desde la fase 1 hay **dos programas** con responsabilidades separadas:

| Programa | Ejecutable | Papel |
|---|---|---|
| Configurador | `DesktopIdentifier.exe` | Ventana de configuración, generación de la banda, instalación y desinstalación |
| Programa de inicio | `DesktopIdentifierHost.exe` | Solo el cartel flotante; Win32 sin VCL, mínimo consumo |

```
src\
  common\      uPaths, uSettings, uUtils, uBadgeRender   (compartido, sin VCL)
  config\      DesktopIdentifier.dpr, uConfigForm, uBandRender, uWallpaper,
               uStartup, uInstall, manifiesto y recursos
  host\        DesktopIdentifierHost.dpr, uHostWindow, manifiesto y recursos
bin\           salida de compilación (ignorada)
dcu\           unidades compiladas (ignorada)
```

La configuración vive en **`%LOCALAPPDATA%\DesktopIdentifier\`**:

```
desktopidentifier.ini     configuración (la escribe el configurador)
DesktopIdentifierHost.exe programa de inicio instalado
fondo-distintivo.png      fondo con la banda (lo genera el configurador)
fondo-original.dat/.ini   copia y datos del fondo original del usuario
```

**Instalar** (una vez) copia el host, escribe el INI, registra el arranque y lo
pone en marcha. A partir de ahí, **Aplicar** solo escribe el INI y el fondo:
**no vuelve a copiar el host ni toca el registro**.

---

## Compilar

Requisitos: **RAD Studio / Delphi 12 (23.0), Win32**. Sin paquetes de terceros.

- **Consola:** doble clic en `Compilar.cmd` (o `Compilar.cmd --no-pause` desde
  un script). Usa `dcc32`/`brcc32` de `%BDS%`, de la ruta habitual de RAD Studio
  o del `PATH`.
- **IDE:** abre `DesktopIdentifier.groupproj` y compila el grupo.

Salida:

```
bin\DesktopIdentifierHost.exe   ~430 KB   (sin VCL)
bin\DesktopIdentifier.exe       ~2,5 MB   (VCL, configurador)
```

`HostResources.rc` y `ConfigResources.rc` contienen el manifiesto y la versión.
`Compilar.cmd` regenera `HostResources.res` y `ConfigResources.res` antes de
compilar.

---

## Instalar, aplicar y desinstalar

Abre `Configurar.cmd` (o `bin\DesktopIdentifier.exe`). La ventana muestra el
estado real: sin instalar, instalado, arranque activo, cartel en marcha.

| Botón | Qué hace |
|---|---|
| **Instalar** | Copia el host a `%LOCALAPPDATA%\DesktopIdentifier`, escribe el INI, registra el arranque y lo arranca. La primera vez aplica también la banda. |
| **Aplicar** | Guarda el INI, regenera y aplica la banda (o restaura el fondo si la banda está desactivada) y recarga el cartel. **No** copia el host ni escribe en el registro. |
| **Desinstalar** | Cierra el cartel, borra la entrada de arranque, restaura el fondo original y borra la carpeta. Una casilla permite **conservar el INI**. |
| **Reaplicar banda** | Recompone y aplica la banda con la configuración actual; útil si has cambiado el fondo de escritorio a mano. |
| **Cerrar el cartel** | Detiene el host; la instalación y el arranque siguen intactos. |

También hay modo consola (sin ventana), útil para automatizar:

```bat
bin\DesktopIdentifier.exe /install
bin\DesktopIdentifier.exe /apply
bin\DesktopIdentifier.exe /uninstall            :: conserva el INI
bin\DesktopIdentifier.exe /uninstall /discard   :: borra todo
bin\DesktopIdentifier.exe /quit
```

Códigos de salida: `0` correcto; distinto de `0` error (por ejemplo, `3` si
`/apply` no encuentra una instalación).

### Arranque con Windows

Instalar escribe una sola entrada por usuario:

```
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
    DesktopIdentifier = "C:\Users\<usuario>\AppData\Local\DesktopIdentifier\DesktopIdentifierHost.exe"
```

Al iniciar sesión, Explorer lanza el host; este lee el INI y pinta el cartel.
La banda ya está puesta porque es un ajuste persistente del escritorio. La
entrada se puede desactivar desde *Administrador de tareas → Aplicaciones de
inicio*; reinstalar la vuelve a habilitar.

---

## Configuración

`desktopidentifier.ini` se puede editar a mano. El host la relee al recibir el
mensaje `DesktopIdentifier_RELOAD` (lo envía el configurador al aplicar).

```ini
[general]
version=2

[cartel]
texto=A
color=#1473E6
color_texto=#FFFFFF
tamano=170
opacidad_panel=0.32
opacidad_letra=0.95
margen_derecha=30
margen_inferior=30
pantalla=0
esquinas=0.24
fuente=Segoe UI

[banda]
activa=1
color=#1473E6
alto=0.08
texto=
color_texto=#FFFFFF
alineacion=derecha
```

| Clave | Valores | Notas |
|---|---|---|
| `cartel.texto` | 1–4 caracteres | Por defecto `A`; el host ajusta el tamaño de la letra si no cabe |
| `cartel.color` | `#RRGGBB` | Panel y borde |
| `cartel.color_texto` | `#RRGGBB` | Color del texto del cartel |
| `cartel.tamano` | 90–280 | Píxeles a 96 ppp; el host escala por DPI |
| `cartel.opacidad_panel` | 0,10–0,60 | |
| `cartel.opacidad_letra` | 0,30–1,00 | |
| `cartel.margen_derecha` / `_inferior` | 0–1000 | Píxeles |
| `cartel.pantalla` | 0–8 | 0 = principal |
| `cartel.esquinas` | 0,00–0,50 | Fracción del tamaño |
| `cartel.fuente` | texto | Por defecto `Segoe UI` |
| `banda.activa` | 0/1 | |
| `banda.color` | `#RRGGBB` | Independiente del color del cartel |
| `banda.alto` | 0,02–0,20 | Fracción de la altura de pantalla |
| `banda.texto` | 0–20 caracteres | Vacío = sin texto; distinto del texto del cartel |
| `banda.color_texto` | `#RRGGBB` | Color del texto de la banda |
| `banda.alineacion` | `derecha`, `centro`, `izquierda` | Posición del texto de la banda |

Los valores fuera de rango se recortan; un INI ausente o corrupto equivale a
los valores por defecto. El configurador guarda con **escritura atómica**
(archivo temporal + `MoveFileEx`), así que el host nunca lee un archivo a medias.

Si existe un `distintive.ini` antiguo (formato plano, sin secciones) junto al
configurador, se importa la primera vez (`letra` → `cartel.texto`, `color` →
cartel y banda, `banda_*` → `[banda]`).

---

## Cómo funciona

**Host (`DesktopIdentifierHost.exe`, sin VCL).**

- Ventana Win32 propia con `WS_EX_LAYERED | WS_EX_TRANSPARENT |
  WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE` y `HWND_TOPMOST`.
- Dibujo con GDI+ en un bitmap ARGB y copia a un **DIB de 32 bpp
  premultiplicado**, que es lo que espera `UpdateLayeredWindow`.
- El texto del cartel se ajusta automáticamente para que 1–4 caracteres quepan
  en el panel; el color del texto sale de `cartel.color_texto`.
- `SetTimer` de 3 s que reafirma el orden superior y recoloca si cambió el área
  de trabajo, el monitor o el DPI.
- DPI por monitor (`GetDpiForMonitor`, con `GetDpiForWindow` de reserva) y
  selección de monitor por índice.
- Mutex `Local\DesktopIdentifier_Host` para instancia única; los mensajes
  registrados `DesktopIdentifier_RELOAD` y `DesktopIdentifier_QUIT` permiten
  controlarlo desde el configurador.
- Tras pintar, recorta su working set (`SetProcessWorkingSetSize`): el cartel
  pasa la mayor parte del tiempo sin hacer nada.

**Configurador (`DesktopIdentifier.exe`, VCL).**

- Compone la banda a la resolución real de la pantalla, recortando la imagen
  original como hace Windows (*fill*), y la aplica con
  `SystemParametersInfo(SPI_SETDESKWALLPAPER)`.
- Antes de tocar el escritorio guarda `fondo-original.dat` y
  `fondo-original.ini`; al desinstalar restaura ruta, estilo y mosaico. Si el
  escritorio original era un color liso, quita el fondo en vez de dejar la banda.
- Vista previa con el mismo renderizador GDI+ que el host, en dos pestañas
  (Cartel y Banda).
- Botón **Reaplicar banda** para recuperar la banda si se cambió el fondo.
- Detección de estado (instalado, arranque, cartel en marcha) y diálogo de
  desinstalación con opción de conservar la configuración.

**Por qué el host no usa VCL.** El host solo necesita una ventana, un timer,
GDI+ y leer un INI. Enlazar `System.Classes` (aunque solo fuera por
`TStringList`) hace crecer el ejecutable por encima de 1 MB; por eso el INI se
lee y escribe con la API de Win32 y los ajustes usan un registro propio.

---

## Medidas en esta máquina

| | Tamaño | RAM |
|---|---|---|
| Host (Release) | **440.320 B** (~430 KB) | working set ~0,3 MB; privada ~3,2 MB |
| Configurador (Release) | **2.684.928 B** (~2,6 MB) | VCL, solo al abrirse |
| Versión anterior (un solo VCL) | ~2,6 MB | ~14,5 MB siempre en memoria |

Sin el recorte de working set, el host muestra ~11 MB de working set por las
páginas compartidas de GDI+ y las DLL del sistema; su memoria privada es de
~3,2 MB.

---

## Pruebas realizadas (24/10/2026)

- Host con los cinco estilos esperados (`LAYERED`, `TRANSPARENT`, `TOOLWINDOW`,
  `NOACTIVATE`, `TOPMOST`), visible, sin `APPWINDOW`; `WindowFromPoint` en el
  centro devuelve la ventana de debajo (clic transparente).
- Instalar: copia, INI, valor `Run`, arranque y host en marcha.
- Aplicar: el hash y la fecha del host instalado y el valor `Run` **no cambian**;
  el fondo se regenera y el cartel se recoloca.
- Editar el INI a mano y enviar `RELOAD`: el cartel cambia sin reiniciarse.
- Segunda instancia del host: sale y deja una sola.
- **Fase 2:** cartel `B2` amarillo sobre panel morado y banda verde azulada al
  14 % con `PRODUCCIÓN` centrado en blanco; la banda del PNG mide 202 px
  (14 % de 1440). Los controles de la UI (texto y altura) se probaron escribiendo
  y moviendo el deslizador, y el resultado quedó en el INI y en la pantalla.
- **Reaplicar banda:** tras cambiar el fondo a mano, el botón reconstruyó la
  banda y volvió a poner `fondo-distintivo.png`.
- **Persistencia:** al cerrar y relanzar el host siguió mostrando `B2` y leyendo
  los mismos valores del INI.
- **Validación del INI:** 0 fallos en las pruebas de rangos, alineación inválida,
  migración del formato antiguo y round-trip.
- Desinstalar: cierra el host, borra `Run`, restaura el `TranscodedWallpaper`
  original (hash idéntico al de antes de instalar), conserva solo el INI o borra
  la carpeta con `/discard`.

---

## Limitaciones y pendientes (fase 3)

- La banda es parte del fondo: Windows la repite en **todos** los monitores.
- Si se cambia el fondo a mano, la banda desaparece; pulsa **Reaplicar banda**.
- El host no tiene icono en la bandeja ni ventana propia: se gestiona desde el
  configurador.
- En aplicaciones a pantalla completa exclusiva el cartel puede quedar oculto.
- Un texto de banda muy largo en una pantalla pequeña puede recortarse; el
  cartel sí ajusta el tamaño de la letra.
- Sin icono propio en los ejecutables ni firma digital (igual que antes).
- Fase 3: versión visible, reparación de instalaciones huérfanas,
  actualización guiada y, opcionalmente, degradado/sombra de la banda y copia
  de color entre cartel y banda.

---

## Documentación

- [Plan de separación en dos programas](docs/PLAN-DOS-PROGRAMAS.md)
- [Fase 1: qué se hizo y cómo se verificó](docs/FASE-1.md)
- [Fase 2: nuevas opciones de cartel y banda](docs/FASE-2.md)
- [Traspaso de contexto original](docs/TRASPASO.md)

## Licencia

Ver [LICENSE](LICENSE).
