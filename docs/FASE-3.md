# Fase 3 — Versión, actualización y reparación

**Estado:** implementada y probada
**Fecha:** 26/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

---

## 1. Qué se ha añadido

### Versión visible

- La versión de cada ejecutable vive en sus recursos (`*Resources.rc`) y se
  lee con `GetFileVersionInfo` (`uVersion.pas`).
- El configurador muestra **su** versión en la cabecera
  (`… · v1.1.0.0`) y la **del host instalado** en la línea de estado
  (`Instalado · host 1.1.0.0 · …`).
- `[general] version` del INI sigue siendo 2; la versión del producto es
  independiente.

### Actualización guiada

- Al abrir la ventana se comparan las versiones del host instalado y del host
  que acompaña al configurador.
- Si la disponible es mayor, el estado pasa a
  `Instalado · host 1.0.0.0 → 1.1.0.0 disponible`, el botón cambia a
  **Actualizar** y se explica en la línea de mensajes.
- Al pulsar **Actualizar** se pide confirmación; después se cierra el cartel, se
  copia el host nuevo, se relanza y se regenera la banda con la configuración
  actual.
- **El INI y la entrada de arranque no se tocan.** La actualización es la única
  excepción a «Aplicar no copia».
- `ActualizarHost` vive en `uInstall.pas` y no escribe ni el INI ni el registro.

### Detección y reparación de instalaciones incompletas

`EstadoInstalacion` comprueba, además de lo anterior:

| Situación | Mensaje |
|---|---|
| Host instalado sin entrada de arranque | «Falta el arranque automático.» |
| `Run` apunta a otra ruta | «La entrada de arranque apunta a otra ruta.» |
| Host instalado sin INI | «Falta el archivo de configuración.» |
| `Run` existe pero el host no | «El arranque apunta a un programa que ya no existe.» |
| Carpeta con restos sin host | «Quedan restos de una instalación anterior.» |
| Cartel en marcha sin instalar | «Hay un cartel en marcha que no está instalado.» |

La ventana muestra **Instalación incompleta · pulsa Reparar** y el botón pasa a
**Reparar**, que vuelve a dejar la instalación completa (`Instalar` + `Aplicar`).

### Texto de banda largo

`DibujarBanda` mide el texto con un rect grande y reduce la fuente si no cabe a
lo ancho, con un mínimo de 6 px. Ya no se recorta un texto de 20 caracteres en
una banda estrecha.

---

## 2. Cambios de comportamiento

- Instalar / Actualizar / Reparar / Reinstalar comparten botón y cambian de
  texto según el estado; el usuario no tiene que saber qué flujo toca.
- La actualización pide confirmación y conserva la configuración y el arranque.
- Reparar puede volver a escribir el INI con lo que haya cargado la ventana; si
  el INI faltaba, se crea con los valores por defecto (no hay nada que
  conservar).
- La versión del producto pasa a **1.1.0.0** en los dos `.rc` y en
  `VersionProducto`.

---

## 3. Evidencias

### Actualización 1.0.0.0 → 1.1.0.0

La máquina tenía instalado un host 1.0.0.0 de **2.763.410 B** (compilado en
Debug desde el IDE) con la configuración `texto=text`.

- La ventana mostró `Instalado · host 1.0.0.0 → 1.1.0.0 disponible`, botón
  **Actualizar** y el aviso correspondiente.
- Tras confirmar: host instalado **1.1.0.0**, **440.320 B**; proceso en marcha;
  `Run` idéntico; INI con `texto=text`; banda regenerada.
- La cabecera de la ventana mostró `v1.1.0.0`.

### Reparación

- **Sin `Run`:** botón **Reparar**, mensaje «Falta el arranque automático.»;
  tras reparar, `Run` restaurado, host en marcha y `texto=text` conservado.
- **`Run` a `C:\no-existe\...`:** botón **Reparar**; tras reparar, `Run`
  apuntando al host instalado.
- **Sin INI:** botón **Reparar**, mensaje «Falta el archivo de configuración.»;
  se restauró el INI del usuario después de comprobar la detección.

### Texto largo

Prueba de renderizado con `MÁQUINA DE PRODUCCIÓN` (20 caracteres) en una banda
de 700 × 120 px: el texto se reduce y queda completo, con márgenes y centrado.

---

## 4. Medidas

| | Tamaño | RAM |
|---|---|---|
| Host 1.1.0.0 | **440.320 B** | working set ~0,9 MB; privada ~3,2 MB |
| Configurador 1.1.0.0 | **2.693.120 B** | VCL, solo al abrirse |

La actualización sustituyó el host Debug de 2,76 MB por el Release de 440 KB.

---

## 5. Capturas

Las capturas de la ventana final están en
[docs/capturas/cartel.png](capturas/cartel.png) y
[docs/capturas/banda.png](capturas/banda.png).

---

## 6. Pendiente (opcional)

- Icono en la bandeja o menú del host.
- Degradado/sombra de la banda y copia de color entre cartel y banda.
- Firma digital / icono propio de los ejecutables.

La lista obligatoria de la fase 3 está cerrada.
