# ADR 0028 — Íconos dedicados del dominio en SVG con `flutter_svg`

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

El sistema visual (`docs/diseno/sistema-visual.md §6`) usa una sola familia de íconos, Material Icons redondeados, y lo deja así para todo lo genérico (volver, cerrar, aceptar, chevron). Pero el dominio de Agrocom tiene formas que Material no cubre y que el cliente y el piloto necesitan distinguir de un vistazo: los seis modelos de dron DJI Agras T-series que opera la flota (T10, T20, T25, T30, T40, T50 — se diferencian por tamaño, brazos y tanque), el tanque de pulverizado, el lote, el cultivo, la batería, el mando RC, la hectárea y el check de equipo. Dibujar esas siluetas requiere trazos propios, no glifos de una fuente de íconos genérica.

`Icon` con `IconData` solo pinta glifos de una fuente de íconos (vectores con un único color de relleno, sin curvas compuestas finas). Para una silueta reconocible de un dron con brazos y rotores el camino natural es un vector SVG dibujado a mano, con trazo (`stroke`) uniforme — el mismo lenguaje que ya usan los Material Icons "outlined" del catálogo.

Opciones evaluadas para pintar esos SVG en Flutter:

1. **`flutter_svg`** (`pub.dev/packages/flutter_svg`, repositorio `flutter/packages/third_party/packages/flutter_svg`): mantenido por el equipo de paquetes de Flutter (se movió de `dnfield/flutter_svg` a `flutter/packages` en 2024), licencia BSD-3, sin dependencias de red en tiempo de ejecución (los SVG son assets locales igual que `assets/imagenes/`), soporta Android, iOS e iPad sin diferencias de plataforma. Versión fijada: `2.5.1` (requiere Dart `^3.12.0`; el SDK instalado en el proyecto es `3.13.3`, y el `environment: sdk: ^3.11.1` del `pubspec.yaml` es el mínimo declarado del proyecto, no el que usa `pub` para resolver — no hay conflicto).
2. **`jovial_svg`**: también mantenido, pero formato propio de caché (`.si`) que agrega un paso de compilación extra sin beneficio claro para ~15 íconos pequeños.
3. **Convertir cada SVG a `CustomPainter` a mano** (sin dependencia nueva): cero dependencias, pero cada ajuste de un trazo exige tocar código Dart en vez de un archivo `.svg` editable con cualquier editor vectorial, y pierde la portabilidad del archivo fuente si algún día se redibuja fuera de Flutter.
4. **`vector_graphics` (motor interno de `flutter_svg` 2.x)**: ya es la base de `flutter_svg` 2.x (precompila el SVG a un formato binario en tiempo de build para pintarlo más rápido); se obtiene gratis al usar `flutter_svg`, no hace falta declararlo aparte.

## Decisión

Se agrega `flutter_svg: ^2.5.1` como dependencia de `lib/nucleo/ui/` únicamente. Los archivos fuente viven en `assets/iconos/*.svg` (24×24, trazo de 2 px, esquinas redondeadas, un solo color por `currentColor`/`fill="none" stroke="#000"` que `IconoAgrocom` sobrescribe con `colorFilter`). El widget `IconoAgrocom` (`lib/nucleo/ui/componentes/icono_agrocom.dart`) envuelve `SvgPicture.asset` y expone `semanticLabel`, `color` (token de `PaletaCampo`) y `tamano` (token), igual que un `Icon` de Material — así una pantalla no distingue en el código si un ícono es de Material o dedicado.

Los SVG se dibujan a mano en este repo, en una cuadrícula simple de líneas y arcos — siluetas genéricas inspiradas en la categoría del dron agrícola, sin copiar el logo, el isotipo ni material con derechos de DJI. No se usa ninguna imagen ni trazado de un tercero.

## Alternativas descartadas

- **`jovial_svg`**: paso de compilación extra sin beneficio para un catálogo chico de íconos estáticos.
- **`CustomPainter` a mano por ícono**: más control, pero cada ajuste visual exige tocar Dart en vez de un archivo editable, y es más código de mantener que una dependencia angosta y bien mantenida.
- **No agregar íconos dedicados y seguir solo con Material**: Material no tiene un glifo de un dron, un tanque de pulverizado ni un mando RC; forzar un ícono genérico ("ventilador", "control remoto de TV") pierde el reconocimiento inmediato que pide el modo campo.

## Consecuencias

- `assets/iconos/` se declara en `pubspec.yaml` junto a `assets/imagenes/`; un ícono nuevo se agrega ahí y se registra en `IconoAgrocomId` (ver `docs/diseno/componentes.md`).
- `flutter_svg` resuelve el SVG a su representación interna (`vector_graphics`) en tiempo de build; no hay descarga ni parseo de red en tiempo de ejecución, compatible con el uso sin señal del flavor `piloto`.
- Si el catálogo de íconos dedicados crece mucho (varias decenas), conviene revisar si conviene precompilar con el flag `--no-vector_graphics` desactivado o activar la compilación offline del paquete; no es necesario con el tamaño actual.
