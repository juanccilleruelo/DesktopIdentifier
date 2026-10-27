# Plan: separar Distintive VM en dos programas

**Estado:** fases 1, 2 y 3 implementadas (ver [FASE-1.md](FASE-1.md), [FASE-2.md](FASE-2.md) y [FASE-3.md](FASE-3.md))
**Fecha:** 24/10/2026
**Proyecto:** DesktopIdentifier (Delphi 12, Win32)

> **Nombres definitivos:** el producto se llama **DesktopIdentifier**;
> los ejecutables son `DesktopIdentifier.exe` (configurador) y
> `DesktopIdentifierHost.exe` (inicio). Donde este documento dice
> `DistintiveVM` o `DistintiveVMHost`, léase DesktopIdentifier.

---

## 1. Objetivo

Separar el programa actual en dos ejecutables con responsabilidades claras:

| Programa | Ejecutable | Papel |
|---|---|---|
| Configurador | `DistintiveVM.exe` | Ventana de configuración, generación de la banda, instalación/desinstalación |
| Inicio | `DistintiveVMHost.exe` | Solo el cartel flotante; el mínimo código y consumo posible |

Premisas acordadas:

- El programa de inicio se instala **una sola vez** en una ubicación estable de la máquina.
- El configurador puede vivir en el repositorio. Si se borra, el cartel sigue funcionando.
- **Aplicar cambios no vuelve a copiar el host ni a tocar el registro**: solo escribe el `.ini` (y el fondo de pantalla).
- La banda superior la genera y aplica el configurador.
- Se mantiene lo que ya funciona: sin administrador, por usuario, clic transparente, siempre encima, sin barra de tareas ni Alt+Tab.

---

## 2. Punto de partida

Hoy hay un único `DistintiveVM.exe` (VCL) que lo hace todo:

| Unidad | Responsabilidad actual |
|---|---|
| `uBadge.pas` | Ventana por capas (`TForm`), dibujo del cartel, temporizador, DPI |
| `uConfigForm.pas` | Ventana de configuración (VCL, sin DFM) |
| `uWallpaper.pas` | Composición, aplicación y restauración de la banda |
| `uGdiPlus.pas` | Dibujo con GDI+ del cartel y de la banda |
| `uConfig.pas` / `uStartup.pas` / `uUtils.pas` | INI, arranque con Windows, utilidades |

Tamaño actual: ~2,6 MB (Release) y ~14,5 MB de RAM. Todo el peso de VCL queda en un proceso que está siempre en memoria, aunque solo tiene que pintar una ventana.

---

## 3. Decisión 1 — Dónde instalar el programa de inicio

### 3.1 Requisitos

- **R1.** Debe seguir ahí aunque se borre el configurador o el repositorio.
- **R2.** Sin administrador.
- **R3.** Coherente con el arranque por usuario (`HKCU\...\Run`).
- **R4.** Fácil de localizar, actualizar y desinstalar.
- **R5.** El `.ini` debe ser accesible y escribible por el configurador.

### 3.2 Opciones

| Opción | R1 | R2 | Ámbito | Observaciones |
|---|---|---|---|---|
| `%LOCALAPPDATA%\DistintiveVM\` | Sí | Sí | Por usuario | Todo junto: exe, ini y fondos. **Recomendada** |
| `%LOCALAPPDATA%\Programs\DistintiveVM\` + datos en `%LOCALAPPDATA%\DistintiveVM\` | Sí | Sí | Por usuario | Separa programa y datos; dos rutas que mantener |
| `%PROGRAMDATA%\DistintiveVM\` | Sí | No (admin) | Todos los usuarios | Habría que separar el ini por usuario o ajustar ACLs |
| `C:\Program Files\DistintiveVM\` | Sí | No (admin) | Todos los usuarios | Instalación "formal", pero actualizar exige elevación |
| Junto al configurador / repo | No | Sí | — | Se borra con el repo: incumple R1 |

### 3.3 Recomendación

**Una sola carpeta en `%LOCALAPPDATA%\DistintiveVM\`:**

```
%LOCALAPPDATA%\DistintiveVM\
    DistintiveVMHost.exe        <- programa de inicio (se ejecuta al entrar)
    distintive.ini              <- configuración (la escribe el configurador)
    fondo-distintivo.png        <- fondo con banda (lo genera el configurador)
    fondo-original.dat          <- copia del fondo original del usuario
    fondo-original.ini          <- ruta/estilo del fondo original
```

Motivos:

- Cumple R1–R5 sin admin y sin repartir archivos por media máquina.
- El desinstalador borra una sola carpeta y el usuario lo puede inspeccionar todo.
- El `.ini` queda junto al host: fácil de editar a mano y de depurar.
- Las rutas quedan centralizadas en una unidad (`uPaths.pas`), así que pasar a `Program Files` o `ProgramData` más adelante es cambiar una constante y separar datos.

Consecuencia asumida: la instalación es **por usuario**, igual que la entrada de arranque. En otra cuenta de Windows habría que instalarlo de nuevo (o cambiar a `%PROGRAMDATA%`, que exigiría admin).

> **Decisión pendiente 1:** confirmar esta ubicación o elegir la variante con el exe en `%LOCALAPPDATA%\Programs`.

---

## 4. Decisión 2 — Cómo se configura el programa de inicio

### 4.1 Un único `.ini`

Sí: `distintive.ini` en la carpeta de instalación.

- Lo lee el host al arrancar y cada vez que recibe la orden de recargar.
- Lo escribe el configurador con **escritura atómica** (archivo temporal + `MoveFileEx`), para que el host nunca lea un archivo a medias.
- Es editable a mano.
- En el registro **solo** vive la entrada de arranque. No hay configuración duplicada.

### 4.2 Esquema propuesto

```ini
[general]
version=1

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

| Clave | Tipo | Rango / valores | Notas |
|---|---|---|---|
| `cartel.texto` | texto | 1–4 caracteres | Si está vacío, `A`. Sustituye a `letra` |
| `cartel.color` | color | `#RRGGBB` | Color del panel y del borde |
| `cartel.color_texto` | color | `#RRGGBB` | Color del texto del cartel |
| `cartel.tamano` | entero | 90–280 | Píxeles a 96 ppp; el host escala por DPI |
| `cartel.opacidad_panel` | real | 0,10–0,60 | Transparencia del panel |
| `cartel.opacidad_letra` | real | 0,30–1,00 | Opacidad del texto |
| `cartel.margen_derecha` | entero | 0–1000 | Píxeles |
| `cartel.margen_inferior` | entero | 0–1000 | Píxeles |
| `cartel.pantalla` | entero | 0–8 | 0 = principal |
| `cartel.esquinas` | real | 0,00–0,50 | Radio de esquina, fracción del tamaño |
| `cartel.fuente` | texto | — | Por defecto `Segoe UI` |
| `banda.activa` | 0/1 | — | Si la banda está puesta |
| `banda.color` | color | `#RRGGBB` | Independiente del color del cartel |
| `banda.alto` | real | 0,02–0,20 | Fracción de la altura de pantalla |
| `banda.texto` | texto | 0–20 caracteres | Vacío = sin texto |
| `banda.color_texto` | color | `#RRGGBB` | Por defecto blanco |
| `banda.alineacion` | texto | `derecha`, `centro`, `izquierda` | Posición del texto |

### 4.3 Validación y compatibilidad

- El host **nunca falla** por un INI inválido: cada valor fuera de rango se recorta y, si el archivo no existe, usa los valores por defecto.
- El configurador valida lo mismo en la UI (controles con mínimos/máximos).
- Al instalar por primera vez, si existe el `distintive.ini` antiguo (junto al exe actual), se importan sus valores (`letra` → `cartel.texto`, etc.). El resto toma los valores por defecto.
- Se guarda `[general] version` para futuras migraciones.

### 4.4 Recarga en caliente

- El configurador, tras guardar, busca la ventana del host y le envía el mensaje registrado `DistintiveVM_RELOAD`.
- El host relee el INI, recalcula tamaño/posición y repinta sin reiniciarse.
- Si el host no está en marcha, el configurador lo arranca.

> **Decisión pendiente 2:** ¿el `.ini` se queda junto al host (recomendado) o prefieres separar programa y datos?

---

## 5. Decisión 3 — Reparto de responsabilidades

| Tarea | Host (inicio) | Configurador |
|---|---|---|
| Leer el INI | Sí | Sí (para editar) |
| Escribir el INI | No | Sí |
| Dibujar el cartel | Sí | Solo para la vista previa |
| Ventana por capas, topmost, clic transparente | Sí | No |
| Generar y aplicar la banda | No | Sí |
| Guardar/restaurar el fondo original | No | Sí |
| Copiar el host a su sitio | No | Sí (instalar/actualizar) |
| Alta/baja en `HKCU\...\Run` | No | Sí (instalar/desinstalar) |
| Cerrar el host | Acepta `QUIT` | Envía `QUIT` |

### 5.1 Por qué el host sin VCL

El host solo necesita una ventana Win32 propia, un `TTimer` de Win32 (`SetTimer`), GDI+ y leer un INI. Con `Winapi.Windows` + `Winapi.GDIPAPI` + una ventana registrada a mano se evita arrastrar VCL (`TForm`, `TApplication`, `Controls`, `Graphics`…), que es la mayor parte de los ~2,6 MB actuales.

Objetivo medible al terminar la fase 1:

- Tamaño del host **< 1 MB** (Release, sin información de depuración).
- RAM en reposo **< 10 MB**.
- Arranque inmediato (sin inicialización de VCL).

Si no se cumple, se revisa (por ejemplo, usando solo la API plana de GDI+ y un parser de INI propio sin `System.IniFiles`/`Classes`).

### 5.2 Por qué la banda la genera el configurador

- Componer la imagen exige cargar el fondo original, escalarlo, dibujar la banda y guardar un PNG de resolución completa: es la parte más "gorda" y solo se hace cuando el usuario aplica.
- Así el host no necesita `uWallpaper`, ni codecs, ni el fondo original: solo pinta su cartel.
- La banda queda como un ajuste persistente del escritorio: sobrevive a cerrar el host o el configurador.

Consecuencia: si el usuario cambia el fondo de escritorio a mano, la banda desaparece. Se resuelve con un botón **Reaplicar banda** en el configurador (y se documenta). Un "vigilante" que la reaplique solo se valorará más adelante (decisión pendiente).

### 5.3 Por qué no una ventana de banda

Una segunda ventana siempre encima taparía la parte superior de las ventanas maximizadas (barra de título, menús). La banda como parte del fondo no intercepta nada y se ve exactamente como parte del escritorio, que es lo que se busca.

---

## 6. Estructura del proyecto propuesta

```
DistintiveVM.groupproj
src\
  common\
    uPaths.pas          rutas fijas (LocalAppData, nombres de archivo, valor Run)
    uSettings.pas       modelo de ajustes + parser/escritor INI + validación
    uBadgeRender.pas    dibujo del cartel con GDI+ (compartido host/config)
    uUtils.pas          colores, DPI, helpers, mensajes registrados
  host\
    DistintiveVMHost.dpr
    uHostWindow.pas     ventana Win32, DIB 32bpp, UpdateLayeredWindow, timer
    DistintiveVMHost.manifest
    HostResources.rc    manifiesto + versión
  config\
    DistintiveVM.dpr
    uConfigForm.pas     UI (VCL)
    uBandRender.pas     dibujo de la banda con GDI+
    uWallpaper.pas      composición/aplicación/restauración del fondo
    ConfigResources.rc  manifiesto + versión + icono
```

- Un **grupo de proyectos** con los dos `.dproj` y una salida común en `bin\`.
- El configurador busca `DistintiveVMHost.exe` **junto a sí mismo** para instalarlo. Si no está, muestra un error claro ("falta el host; compila el grupo completo").
- Nombres fijos para que ambos se encuentren:
  - Clase de ventana del host: `DistintiveVMHostWindow`.
  - Mutex: `Local\DistintiveVM_Host`.
  - Mensajes registrados: `DistintiveVM_RELOAD`, `DistintiveVM_QUIT`.
  - Valor de arranque: `DistintiveVM`.
- El host lleva manifiesto `permonitorv2` (sin controles comunes, no los necesita).
- El configurador conserva su manifiesto con controles v6.

---

## 7. Flujos

### 7.1 Instalar (una sola vez)

1. Comprobar que existe `DistintiveVMHost.exe` junto al configurador.
2. Crear `%LOCALAPPDATA%\DistintiveVM`.
3. Si el host está en marcha, pedirle que se cierre.
4. Copiar el host a la carpeta de instalación.
5. Si no existe `distintive.ini`, crearlo con los valores actuales de la UI (o importar el antiguo).
6. Escribir la entrada `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\DistintiveVM` con la ruta del host instalado.
7. Arrancar el host.
8. Mostrar estado: "Instalado · Arranque activo".

Solo este flujo copia y toca el registro.

### 7.2 Aplicar (cada cambio de configuración)

1. Validar y guardar el `.ini` (atómico).
2. Si la banda está activa: guardar el fondo original (solo la primera vez), componer el PNG y aplicarlo.
   Si no: restaurar el fondo original.
3. Enviar `RELOAD` al host (o arrancarlo si no está).
4. **No** se copia el host. **No** se escribe en el registro.

### 7.3 Actualizar el host

Cuando el configurador detecta que la versión del host instalado no coincide con la suya:

1. Avisar ("Hay una versión nueva del programa de inicio").
2. Cerrar el host, copiar el nuevo, arrancarlo.
3. El `.ini` y el arranque no se tocan.

Es la única excepción a "no volver a copiar", y solo ocurre al actualizar.

### 7.4 Arranque de la sesión

1. Explorer procesa `HKCU\...\Run` y lanza `DistintiveVMHost.exe`.
2. El host lee el `.ini`, dibuja el cartel y se queda esperando mensajes.
3. La banda ya está puesta (es un ajuste del escritorio), no se regenera.

### 7.5 Desinstalar

1. Pedir confirmación.
2. Enviar `QUIT` al host; si no responde, terminarlo.
3. Borrar la entrada de `Run` (y la de `StartupApproved` si existe).
4. Restaurar el fondo original si hay copia guardada.
5. Borrar la carpeta de instalación (con opción a conservar el `.ini`).
6. Dejar el escritorio como estaba.

### 7.6 Casos límite

| Caso | Comportamiento previsto |
|---|---|
| Entrada de `Run` apunta a un exe que ya no existe | El configurador lo detecta y ofrece "Reparar instalación" o "Limpiar" |
| Host instalado pero sin `.ini` | Arranca con valores por defecto; el configurador ofrece guardar |
| Host en marcha pero no instalado (arrancado a mano) | El configurador avisa y ofrece instalarlo |
| El usuario borra la carpeta de instalación a mano | El cartel desaparece y la banda puede quedar rota; el configurador detecta el estado y ofrece reinstalar/restaurar |
| El usuario cambia el fondo de escritorio | La banda desaparece; botón **Reaplicar banda** |
| Varios monitores | La banda se replica en cada monitor (Windows aplica la misma imagen); el cartel va al monitor elegido |
| Dos instancias del host | La segunda sale sola (mutex) |
| El `.ini` está corrupto | El host usa valores por defecto y sigue funcionando |

---

## 8. Mejoras funcionales (fase 2)

| Mejora | Clave del INI | UI | Notas |
|---|---|---|---|
| Texto del cartel configurable | `cartel.texto` | Campo de texto (1–4) | Por defecto la letra A/B |
| Color del cartel | `cartel.color` | Selector de color | Ya existía |
| Color del texto del cartel | `cartel.color_texto` | Selector de color | Nuevo, barato |
| Tamaño | `cartel.tamano` | Numérico / deslizador | Ya existía |
| Transparencia del panel | `cartel.opacidad_panel` | Deslizador | Ya existía |
| Transparencia del texto | `cartel.opacidad_letra` | Deslizador | Ya existía |
| Márgenes | `cartel.margen_*` | Numéricos | Ya existía |
| Monitor | `cartel.pantalla` | Desplegable | Ya existía |
| Esquinas | `cartel.esquinas` | Deslizador | Ya existía |
| Color de la banda | `banda.color` | Selector de color | **Nuevo** |
| Altura de la banda | `banda.alto` | Deslizador % con px calculados | **Nuevo** |
| Texto de la banda | `banda.texto` | Campo de texto | **Nuevo** |
| Color del texto de la banda | `banda.color_texto` | Selector de color | **Nuevo** |
| Banda sí/no | `banda.activa` | Casilla | Ya existía |
| Reaplicar banda | — | Botón | Recupera la banda si se cambió el fondo |

Opcionales que se pueden añadir sin mucho coste (a decidir):

- Alineación del texto de la banda (derecha/centro/izquierda) con `banda.alineacion`.
- Degradado de la banda sí/no.
- Sombra de la banda sí/no.
- Botón "copiar el color del cartel a la banda" (y viceversa).

---

## 9. Fases

### Fase 0 — Revisión de este plan

- Aprobar ubicación, esquema del INI y reparto.
- Resolver las decisiones pendientes de la sección 12.

**Criterio de aceptación:** plan cerrado y sin preguntas bloqueantes.

### Fase 1 — Separación en dos programas (sin features nuevas)

Tareas:

1. Crear `uPaths.pas` y `uSettings.pas` compartidos.
2. Mover el dibujo del cartel a `uBadgeRender.pas` (compartido).
3. Reescribir el host como ventana Win32 sin VCL (`uHostWindow.pas`, `DistintiveVMHost.dpr`).
4. Adaptar el configurador: estado de instalación, botones Instalar/Aplicar/Desinstalar, escritura del INI, envío de `RELOAD`.
5. Mover la banda al configurador (ya lo está) y dejar el host sin código de fondo.
6. Grupo de proyectos, `Compilar.cmd`, README.
7. Pruebas (sección 10).

**Criterios de aceptación:**

- [x] `DesktopIdentifierHost.exe` < 1 MB y < 10 MB de RAM.
- [x] Instalar una vez: copia + alta en `Run` + arranque.
- [x] Aplicar después: **no** cambia el exe del host ni el registro (comprobado por fechas/hash y `reg query`).
- [x] El cartel mantiene clic transparente, topmost, sin Alt+Tab ni barra de tareas.
- [x] Cambiar el `.ini` a mano y enviar `RELOAD` actualiza el cartel.
- [x] Desinstalar deja el sistema como estaba (fondo restaurado, sin `Run`, sin carpeta).
- [x] Arranque tras cerrar y volver a iniciar sesión.

### Fase 2 — Mejoras funcionales

Tareas:

1. Nuevas claves y controles: color de banda, altura, texto de banda, color de texto, texto del cartel.
2. Previsualización fiel usando el mismo renderizador que el host.
3. Botón **Reaplicar banda**.
4. Validaciones y valores por defecto.

**Criterios de aceptación:**

- [x] Se puede cambiar el color y la altura de la banda y se ve al aplicar.
- [x] Se puede poner texto distinto en la banda y en el cartel.
- [x] Los cambios se guardan en el `.ini` y sobreviven al reinicio.
- [x] La vista previa coincide con el resultado real.
- [x] Valores fuera de rango se recortan sin romper.

Implementada; el detalle y las evidencias están en [FASE-2.md](FASE-2.md).

### Fase 3 — Pulido

- [x] Versión del host visible en la UI y actualización guiada.
- [x] Detección de instalaciones huérfanas y botón de reparación.
- [x] Documentación final (README) y capturas.
- [x] Revisión de tamaño/memoria y limpieza de código muerto.
- [x] Icono propio del configurador y presencia en la barra de tareas (el host
  sigue oculto).

Implementada; el detalle está en [FASE-3.md](FASE-3.md). Quedan como opcionales
el icono en la bandeja, el degradado/sombra y la copia de color entre cartel y
banda.

---

## 10. Pruebas

**Host**

- Ventana visible, sin borde, sin barra de tareas, sin Alt+Tab.
- `WindowFromPoint` sobre el centro devuelve la ventana de debajo (clic transparente).
- `GetWindowLong` con `WS_EX_LAYERED | TRANSPARENT | NOACTIVATE | TOOLWINDOW | TOPMOST`.
- Cambio de resolución/DPI/monitor: se recoloca y repinta.
- `RELOAD` con el INI cambiado; `QUIT`; segunda instancia.
- INI inexistente o corrupto: valores por defecto, sin excepciones.
- Medición de tamaño del exe y memoria.

**Configurador**

- Instalar / aplicar / actualizar / desinstalar.
- Aplicar sin copiar ni escribir en `Run`.
- Banda con distintos colores, alturas y textos; restauración exacta del fondo original.
- Errores: host ausente, sin permisos, carpeta bloqueada.
- Previsualización coherente.

**Regresión**

- El escritorio queda igual tras desinstalar.
- No quedan procesos, claves ni carpetas.
- El arranque aparece en "Aplicaciones de inicio" del Administrador de tareas y se puede desactivar.

---

## 11. Riesgos

| Riesgo | Mitigación |
|---|---|
| Reescribir el host en Win32 puro introduce fallos de DPI/posición | Reutilizar la lógica de geometría y probar en 96/120/144 ppp y varios monitores |
| Dos binarios que pueden desincronizarse | Versión en el exe + comprobación al abrir el configurador |
| El usuario borra el configurador y no puede desinstalar desde la UI | Documentar el borrado manual (carpeta + valor `Run`); opcional: menú contextual del host más adelante |
| Cambiar el fondo a mano elimina la banda | Botón **Reaplicar banda** y nota en la UI |
| Restauración del fondo incorrecta | Copia del original + pruebas de restauración por píxeles |
| Antivirus/SmartScreen con exe sin firmar | Es el mismo caso que ahora; no cambia |
| La banda se replica en todos los monitores | Se documenta; si molesta, valorar imagen del escritorio virtual completo |

---

## 12. Decisiones (cerradas el 24/10/2026)

| # | Decisión | Elección |
|---|---|---|
| 1 | Ubicación | `%LOCALAPPDATA%\DesktopIdentifier\` con todo junto |
| 2 | Instalación | Botón **Instalar** explícito; **Aplicar** exige estar instalado |
| 3 | Desinstalar | Diálogo con casilla **Conservar la configuración**, marcada por defecto |
| 4 | Varios monitores | Se acepta la réplica de la banda en todos; el cartel va al monitor elegido |
| 5 | Texto del cartel | 1–4 caracteres (fase 2) |
| 6 | Bandeja del sistema | Host sin icono; se gestiona desde el configurador (fase 1) |
| 7 | Vigilante del fondo | Manual: botón **Reaplicar banda** en fase 2 |
| 8 | Nombre del host | `DesktopIdentifierHost.exe` |
| 9 | Color/alineación del texto de la banda | Fase 2 |

Con estas decisiones, la fase 1 está implementada y probada; el detalle y las
evidencias están en [FASE-1.md](FASE-1.md).

---

## 13. Lo que no cambia

- Sin administrador, todo por usuario.
- Cartel semitransparente, redondeado, siempre encima, clic transparente.
- Sin icono en la barra de tareas ni en Alt+Tab.
- La banda es parte del fondo de pantalla, no una ventana.
- El arranque se hace por `HKCU\...\Run`.
- El fondo original se guarda y se restaura.

---

## 14. Resumen de la propuesta

La propuesta era:

1. Host minúsculo (`DesktopIdentifierHost.exe`, Win32 sin VCL) instalado en `%LOCALAPPDATA%\DesktopIdentifier\`.
2. Configuración en `desktopidentifier.ini` junto al host.
3. Instalación una vez (copiar + `Run`); a partir de ahí, **Aplicar** solo escribe el INI y el fondo.
4. La banda la genera el configurador; el host solo pinta el cartel.
5. Fase 1 = separar sin cambiar comportamiento; fase 2 = color/altura/textos; fase 3 = pulido.

Las tres fases están implementadas; el resultado está en [FASE-1.md](FASE-1.md),
[FASE-2.md](FASE-2.md) y [FASE-3.md](FASE-3.md). Quedan solo los opcionales
(bandeja, degradado/sombra y copia de color).
