# Fase 2 — Cartel y banda configurables

**Estado:** implementada y probada
**Fecha:** 24/10/2026
**Base:** [PLAN-DOS-PROGRAMAS.md](PLAN-DOS-PROGRAMAS.md)

---

## 1. Qué se ha añadido

La ventana de configuración pasa a tener **dos pestañas**:

- **Cartel:** texto (1–4 caracteres), color del panel, color del texto, tamaño,
  opacidad del panel, opacidad del texto, radio de las esquinas y márgenes.
- **Banda:** activa sí/no, color, color del texto, altura, texto y alineación
  (derecha, centro, izquierda).

Además:

- **Reaplicar banda**: recompone el fondo con la configuración actual. Sirve
  cuando el usuario cambia el fondo de escritorio a mano.
- **Vista previa fiel**: usa el mismo `DibujarDistintivo` y `DibujarBanda` que
  el host y el generador de fondo, con el texto y los colores reales.
- El **color del texto del cartel** y el de la **banda** ya se usan de verdad
  (antes se guardaban pero el cartel pintaba blanco).
- El texto del cartel se **ajusta automáticamente** para que 1–4 caracteres
  quepan en el panel.

### Claves nuevas

| Clave | Valores | Notas |
|---|---|---|
| `banda.alineacion` | `derecha` / `centro` / `izquierda` | Por defecto `derecha` |

`[general] version` pasa a **2**. Los INI con versión 1 se leen sin problema: la
alineación toma el valor por defecto y el resto se conserva.

---

## 2. Correcciones incluidas

### Último carácter recortado

Con textos de más de un carácter, GDI+ dibujaba solo los primeros: `VM1` salía
como `VM` y `ABCD` como `ABC`.

Causa: `MeasureString` se llamaba con el rect del cartel (200 px) y GDI+
devolvía la **anchura recortada** (131,08 px para `ABCD` en vez de 386,81 px).
El factor de ajuste salía 1,0, el texto se dibujaba a tamaño completo y GDI+
cortaba lo que no cabía en el rect.

Solución: medir con un rect grande (`Px * 10`) para obtener la anchura real y
calcular bien el factor antes de dibujar.

### BOM UTF-8

Al editar los `.pas` con acentos, el editor eliminó el BOM y la primera
compilación de la fase 2 mostró «ConfiguraciÃ³n» en el título. Hay que
comprobar/restaurar el BOM UTF-8 después de editar fuentes con acentos.

---

## 3. Criterios de aceptación

| Criterio | Resultado |
|---|---|
| Cambiar color y altura de la banda y verlo al aplicar | Banda `#2A9D8F` al **14 %**: 202 px en el PNG (14 % de 1440) |
| Texto distinto en banda y cartel | Cartel `B2`, banda `PRODUCCIÓN` |
| Los cambios se guardan y sobreviven al reinicio | INI con `texto=B2`, `alto=0.14`, `alineacion=centro`; tras cerrar y relanzar el host sigue `B2` |
| La vista previa coincide con el resultado real | Mismo renderizador; capturas de la UI y del cartel real |
| Valores fuera de rango se recortan sin romper | Prueba unitaria: `alto=0.5` → 0,20; texto de 25 → 20; alineación inválida → `derecha`; 0 fallos |

### Evidencia

- Cartel real: `B2` amarillo (`#FFD166`) sobre panel morado (`#7B2CBF`), 200 px,
  esquinas al 30 %, panel al 45 % y texto al 80 %.
- Banda real: verde azulada (`#2A9D8F`), 14 %, `PRODUCCIÓN` centrado en blanco.
- Botón **Aplicar** de la UI: escribí `B2` en el campo, moví el deslizador de
  altura al 14 % y pulsé Aplicar; el INI, el PNG y el cartel cambiaron.
- **Reaplicar banda:** puse el fondo original a mano, pulsé el botón y volvió
  `fondo-distintivo.png` con la banda.
- **Persistencia:** `/quit` y relanzar el host; siguió mostrando `B2` con los
  mismos colores.

---

## 4. Medidas

| | Tamaño | RAM |
|---|---|---|
| Host | **440.320 B** | working set ~0,31 MB; privada ~3,27 MB |
| Configurador | **2.684.928 B** | VCL, solo al abrirse |

El host crece ~512 B respecto a la fase 1 por el campo `ColorTexto` del estilo.

---

## 5. Pruebas realizadas

- Compilación limpia del grupo y de ambos ejecutables.
- Dos capturas de la UI (pestañas Cartel y Banda) y comprobación de acentos.
- Recorte del PNG generado: color, altura y texto de la banda.
- Captura de la esquina del escritorio: cartel `VM1` primero y `B2` después.
- Cambio de texto y altura desde la UI y Aplicar.
- Reaplicar tras cambiar el fondo.
- Cerrar/relanzar el host.
- Prueba unitaria de `uSettings`: defaults, round-trip, rangos, alineación
  inválida, migración del INI antiguo y `version=2`.
- Desinstalación final con `/discard`: `Run` borrado, carpeta borrada y
  `TranscodedWallpaper` restaurado con el hash original.

---

## 6. Pendiente para la fase 3

- Versión visible y actualización guiada del host.
- Detección/reparación de instalaciones huérfanas.
- Icono en la bandeja o menú del host (decisión aplazada).
- Opcionales: degradado/sombra de la banda, copia de color entre cartel y banda.
- Ajuste automático del texto de la banda si es muy largo en pantallas pequeñas.
