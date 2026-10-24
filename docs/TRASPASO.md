# Traspaso de contexto — DesktopIdentifier

**Fecha:** 24/10/2026
**Origen:** conversación del workspace `default-workspace` (no se puede mover entre
workspaces en DSH: el workspace queda fijado al crear la sesión).
**Destino:** este workspace, `C:\Views\DesktopIdentifier`.

> **Actualización (24/10/2026):** la fase 1 está implementada y probada. Las
> decisiones de la sección 3 están cerradas (ver el plan, sección 12) y el
> estado real está en [FASE-1.md](FASE-1.md). Este documento se conserva como
> traspaso histórico; donde dice `DistintiveVM`, el nombre actual es
> `DesktopIdentifier`.

Este documento resume el estado del proyecto y las decisiones tomadas para que
una sesión nueva aquí pueda continuar sin releer toda la conversación anterior.

---

## 1. Qué es el proyecto

Aplicación Windows para **distinguir visualmente dos máquinas virtuales clonadas**
que comparten anfitrión:

- **Banda de color** en la parte superior del escritorio, integrada en el fondo de
  pantalla (azul para A, naranja para B).
- **Cartel flotante** con la letra A/B, semitransparente, siempre encima, sin
  capturar el ratón (los clics atraviesan el cartel).
- **Configuración** de letra, color, tamaño, transparencia y banda.
- **Arranque automático** con la sesión de Windows.

Nombre de trabajo original: *Distintive VM*. Este repositorio: **DesktopIdentifier**
(«Know which machine you're working on»).

---

## 2. Estado actual

- Implementación **Delphi 12 (RAD Studio 23.0), Win32**, funcionando, en
  `C:\Views\DistintiveVM` (un solo ejecutable VCL):
  - Ventana por capas con `WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW`.
  - Dibujo con GDI+ en un **DIB de 32 bpp premultiplicado** y `UpdateLayeredWindow`.
  - Configuración en `distintive.ini` junto al ejecutable.
  - Banda compuesta a la resolución real de pantalla, con copia del fondo original
    y restauración al desinstalar.
  - Arranque por `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\DistintiveVM`.
  - Modos: sin parámetros = cartel; `/config` = configuración; `/quit` = cerrar.
  - Instancia única (mutex `Local\DistintiveVM_Badge`); segunda ejecución sale y
    pide recarga.
- La versión **PowerShell** anterior está desinstalada y borrada por completo.
- Repositorio: commit inicial, remoto
  `https://github.com/juanccilleruelo/DesktopIdentifier.git`, `.gitignore` de Delphi.
- En `docs/` están este traspaso y el plan de evolución.

**Lo que no está hecho:** el plan de separación en dos programas todavía **no se ha
implementado**. El código actual sigue siendo un único ejecutable.

---

## 3. Plan de evolución (propuesta)

Documento completo: [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md).

Resumen:

1. **Dos programas:** configurador (`DistintiveVM.exe`, VCL) y programa de inicio
   (`DistintiveVMHost.exe`, sin VCL, < 1 MB, < 10 MB de RAM).
2. **Instalación una sola vez:** copiar el host a una carpeta estable de la máquina
   y registrar el arranque. A partir de ahí, **Aplicar solo escribe el `.ini` y el
   fondo**, sin volver a copiar ni tocar el registro.
3. **Configuración en `distintive.ini`** junto al host.
4. **La banda la genera el configurador**; el host solo pinta el cartel.
5. **Fases:** F1 separar sin cambiar comportamiento; F2 color/altura/textos de la
   banda y del cartel; F3 pulido (versión, reparación, documentación).

### Decisiones que faltan por confirmar

Las cuatro bloqueantes:

1. **Ubicación del host:** `%LOCALAPPDATA%\DistintiveVM\` con todo junto
   (recomendada) o separar el exe en `%LOCALAPPDATA%\Programs\DistintiveVM\`.
2. **Instalación:** botón *Instalar* explícito (recomendado) o automática en el
   primer *Aplicar*.
3. **Desinstalar:** ¿borrar el `.ini` o conservarlo?
4. **Varios monitores:** la banda es parte del fondo, así que Windows la replica en
   todos. ¿Se acepta o se quiere solo en el principal?

Menores (fase 2): longitud del texto del cartel, icono en bandeja o host invisible,
vigilante del fondo, nombre del host, color/alineación del texto de la banda.

---

## 4. Dónde está el código y primer paso

El código está **fuera de este workspace**, en `C:\Views\DistintiveVM`.

Como el sandbox de escritura solo permite escribir dentro del workspace, para
trabajar en la fase 1 hay que **traer el proyecto a este repositorio**. Propuesta:

```
DesktopIdentifier\
    README.md
    LICENSE
    docs\                     (ya está: plan + este traspaso)
    src\                      copia de C:\Views\DistintiveVM (*.dpr, *.pas, *.dproj, *.rc/.res, *.manifest, *.cmd)
    bin\                      salida de compilación (ignorada por .gitignore)
    dcu\                      unidades compiladas (ignorada)
```

Pasos:

1. Copiar los fuentes de `C:\Views\DistintiveVM` a `src\`.
2. Comprobar que `Compilar.cmd` y el `.dproj` siguen funcionando desde ahí.
3. Decidir el nombre definitivo: *Distintive VM* o *Desktop Identifier* (afecta a
   ejecutables, manifiesto, valor de `Run`, rutas de instalación).

Alternativa: dejar el código donde está y abrir el workspace en
`C:\Views\DistintiveVM`; pero entonces el repositorio no sería este.

---

## 5. Cómo continuar

1. Confirmar las decisiones de la sección 3 (o aceptar las recomendaciones).
2. Fase 1 del plan: separar en configurador + host, sin añadir funcionalidad.
3. Criterios de aceptación de la fase 1 (en el plan, sección 9).

---

## 6. Trampas técnicas ya resueltas (no repetirlas)

- **Alfa premultiplicado:** `UpdateLayeredWindow` con `AC_SRC_ALPHA` espera píxeles
  premultiplicados. Si se copia el ARGB tal cual, el panel se ve opaco.
- **Clic transparente:** `WS_EX_LAYERED` + `WS_EX_TRANSPARENT`; sin el segundo, el
  cartel se come los clics.
- **Sin robar foco:** `WS_EX_NOACTIVATE` + `ShowWindow(SW_SHOWNOACTIVATE)`.
- **Fuera de Alt+Tab/barra:** `WS_EX_TOOLWINDOW` y `ShowInTaskbar = False`.
- **Controles v6 y `TPanel.Color`:** con estilos activos, un `TPanel` ignora `Color`
  si `StyleElements` incluye `seClient`; usar `StyleElements := []` en los paneles
  de color (cabecera y muestra de color).
- **Acentos en fuentes:** los `.pas` con caracteres no ASCII necesitan **BOM UTF-8**,
  o Delphi los lee como ANSI y salen «MÃ¡quina».
- **Recursos:** Delphi regenera `DistintiveVM.res` en cada compilación (proyecto
  homónimo). El manifiesto y la versión van en `Recursos.res` (nombre distinto) para
  que no los pise; el `.dpr` referencia `{$R 'Recursos.res'}`.
- **Bloqueo del exe:** si hay una instancia en marcha, `dcc32` no puede sobrescribir
  el ejecutable. Parar antes: `Stop-Process -Name DistintiveVM`.
- **Una sola instancia:** la segunda ejecución no muestra nada; solo pide `RELOAD`
  al cartel que ya está. Es la causa de «ejecuto desde el IDE y no pasa nada».
- **Arranque:** `HKCU\...\Run` (por usuario, sin admin). La ruta guardada es la del
  exe que aplicó (`ParamStr(0)`); si se mueve, hay que volver a aplicar.
- **Fondo:** se guarda `fondo-original.dat` + `fondo-original.ini` antes de tocar
  nada y se restaura al desinstalar. Si el usuario cambia el fondo a mano, la banda
  desaparece; hay que reaplicarla.
- **La app abierta reescribe el log de la sesión**; por eso el workspace no se puede
  cambiar en caliente.

---

## 7. Comandos y archivos útiles

En `C:\Views\DistintiveVM`:

- `Compilar.cmd` — compila a `bin\DistintiveVM.exe`.
- `Configurar.cmd` — abre la configuración.
- `bin\DistintiveVM.exe /config` — ídem desde consola.
- `bin\DistintiveVM.exe /quit` — cierra el cartel.

Documentación:

- `C:\Views\DistintiveVM\README.md` — cómo compilar, ejecutar y configurar.
- `docs/PLAN-DOS-PROGRAMAS.md` — plan completo.

---

## 8. Primer mensaje sugerido para la sesión nueva

> Lee `docs/TRASPASO.md` y `docs/PLAN-DOS-PROGRAMAS.md`. Confirma las cuatro
> decisiones pendientes y empecemos la fase 1: traer el proyecto a este repo y
> separarlo en configurador + programa de inicio.
