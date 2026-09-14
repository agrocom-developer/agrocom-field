# ADR 0003 — Tema Material 3 a partir del logo de Agrocom

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

El bootstrap técnico de este repo necesita un tema visual antes de la primera pantalla real, compartido entre los dos flavors (`nucleo/ui/`, ya previsto en el árbol de carpetas de ADR 0005 de `agrocom-api`). El logo de Agrocom (`/Applications/MAMP/htdocs/agrocom-api/public/logo.png`) tiene un triángulo en degradado verde y un ícono de señal/wifi en naranja bajo el triángulo, con el texto "AGRO" en verde y "COM" en naranja. Material 3 ofrece `ColorScheme.fromSeed` para derivar un esquema completo y armónico a partir de un solo color semilla, pero derivar todo desde un único verde pierde el naranja real de la marca. Además, la app corre a campo abierto, con el usuario usando guantes y bajo sol directo, en el RC del dron (gama media/baja, Android 10) — condiciones que exceden lo que un tema Material 3 por defecto asume.

## Decisión

Tema Material 3 con `ColorScheme.fromSeed(seedColor: <verde del logo>, ...)`, fijando en la misma llamada (como parámetros directos de `fromSeed`, no con un `.copyWith` posterior) los campos `secondary`/`onSecondary`/`secondaryContainer`/`onSecondaryContainer` con el naranja real del isotipo.

Colores concretos:
- Seed / verde primario: `#2E7D32` (degradado del triángulo entre `#8BC34A` claro y `#1B5E20` oscuro).
- Secundario (naranja del ícono de señal): `#F57C00`.

Se definen un tema claro y uno oscuro en `lib/nucleo/ui/tema.dart` y `lib/nucleo/ui/colores_agrocom.dart`. Se ajustan además `materialTapTargetSize: MaterialTapTargetSize.padded` y un alto mínimo de 56 en botones, por el uso a campo abierto descrito arriba, donde el touch target compacto por defecto de Material no alcanza. Tipografía del sistema (Roboto), sin paquete de fuente propio, por costo de arranque/memoria en el RC del dron.

## Alternativas descartadas

- **Dejar que `fromSeed` derive todo el esquema solo del verde**: el `secondary` derivado automáticamente sale verdoso/grisáceo, perdiendo el naranja real de la marca.
- **Definir el `ColorScheme` completo a mano, sin `fromSeed`**: más control, pero pierde la armonía tonal automática de Material 3 y multiplica el mantenimiento en cada rol de color (más de una decena de roles en un `ColorScheme` de Material 3).

## Consecuencias

- Los valores exactos de contraste de los pares `on*`/`*Container` del naranja son un punto de partida razonable, **no verificados todavía** con una herramienta de contraste WCAG — pendiente a confirmar (idealmente AA, ideal AAA dado el uso a sol directo) antes de la primera pantalla real de producción. Queda como tarea abierta para `flutter-ui` o `estandares-flutter`.
- Ambos flavors comparten el mismo tema — no hay tema distinto por rol piloto/auxiliar; si en algún momento se necesitara diferenciarlos visualmente, esa es una decisión nueva que actualiza este ADR, no un `.copyWith` ad hoc dentro de una pantalla de feature.
