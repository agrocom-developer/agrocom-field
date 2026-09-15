# ADR 0008 — Catálogo de componentes "campo" (TE-15), modo alto contraste sobre ADR 0003

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

TE-15 (`docs/gestion/plan_sprints.md`, Sprint 15) pide un catálogo de widgets reutilizables sobre el tema ya definido, con la convención de "cero widget suelto por pantalla", antes de construir pantallas nuevas. Quedó fuera del ciclo automático (`docs/gestion/cola_tareas.md`) porque su criterio de aceptación exige fijar una decisión de arquitectura visual nueva y una zona (`docs/decisiones/`) que el propio ciclo tiene prohibido descongelar sin revisión del dueño — necesitaba que el dueño la revisara en persona.

El dueño trajo un mockup de referencia (`/Users/miguel/Downloads/Agrocom Field.dc.html`, un canvas de Claude Design con 9 pantallas de piloto/auxiliar) en un lenguaje visual de contraste mucho más alto que el tema actual: fondo casi negro, un único acento lima muy saturado, jerarquía por opacidad de un solo color de texto en vez de una paleta de grises. Es, en esencia, la misma motivación que ya dejó escrita ADR 0003 (guantes, sol directo, RC de gama media/baja) llevada a un extremo mayor. **Aclaración explícita del dueño durante esta sesión**: el HTML es un demo para extraer el lenguaje visual — componentes, tokens, patrones —, no una especificación de datos; los campos de negocio que aparecen ahí (p. ej. pH de la calda, litros/ha en la mezcla) no reflejan el contrato real de `agrocom-api` y este ADR no los toma como tales ni los implementa.

## Decisión

Se documenta un **modo alto contraste ("campo")**, alternativo al `ThemeData` de ADR 0003, no un reemplazo: convive con `AgrocomTheme.light()`/`.dark()` como una `ThemeExtension` propia (`TemaCampo`, en `lib/nucleo/ui/tema_campo.dart`) que cualquier pantalla nueva puede adoptar. Ninguna pantalla existente migra por este ADR — ese es un cambio aparte, a decidir pantalla por pantalla.

### Tokens de color (`lib/nucleo/ui/colores_campo.dart`)

Extraídos del mockup, verificados contra WCAG (fórmula de luminancia relativa estándar, no una herramienta externa — cálculo documentado en el propio commit):

| Token | Valor | Contraste medido |
|---|---|---|
| `fondoProfundo` | `#07110A` | — |
| `superficie` | `#0A1A0E` | — |
| `textoPrincipal` (sobre `fondoProfundo`) | `#F0FDF4` | 18.34:1 (AAA) |
| `acentoLima` (CTA/éxito/OK) | `#A3E635` | texto `fondoProfundo` sobre botón lima: 12.74:1 (AAA); texto lima sobre fondo profundo: 12.74:1 (AAA) |
| `acentoAmbarTexto` (alerta/pendiente) | `#FDE68A` sobre `fondoProfundo` | 15.42:1 (AAA) |
| `acentoAmbar` (fondo/borde de alerta) | `#FBBF24` | — (uso en fondo translúcido, no como texto) |
| `acentoRojo` (error/reintento) | `#F87171` sobre `fondoProfundo` | 6.94:1 (AA, no AAA en texto normal) |

`textoPrincipal` nunca cambia de color para variar jerarquía — el mockup la resuelve con **opacidad** (`.48` a `.8`), no con grises nuevos; el catálogo reproduce ese criterio con un solo color + una escala de opacidad fija (`0.48, 0.55, 0.62, 0.7, 0.8, 1.0`) en vez de que cada pantalla invente su propia opacidad suelta.

### Tipografía

**Se descarta traer Manrope/JetBrains Mono como paquete** (Google Fonts o asset embebido): reabriría el motivo que ADR 0003 ya resolvió — costo de arranque/memoria en el RC de gama media/baja, Android 10 — sin evidencia nueva que lo justifique. Se preserva la *jerarquía* del mockup (texto humano vs. dato técnico monoespaciado) con lo que ya está disponible sin paquete nuevo:
- Texto humano (títulos, botones, párrafos): fuente de plataforma (la que ya usa ADR 0003), variando peso/tamaño/`letterSpacing`.
- Dato técnico (labels en mayúscula, badges de estado, timestamps, notas de sync): `fontFamily: 'monospace'` — familia monoespaciada nativa del SO, sin paquete ni descarga.

### Catálogo de componentes (`lib/nucleo/ui/componentes/`)

Un archivo por widget, cada uno consumiendo `TemaCampo`/`ColoresCampo` en vez de valores sueltos:

- `boton_primario_campo.dart` — CTA pill, lima, alto mínimo 56 (mismo criterio de touch target que ADR 0003).
- `boton_secundario_campo.dart` — pill con borde, transparente.
- `tarjeta_campo.dart` — superficie translúcida + borde 1px, radio configurable (20/24/26 según jerarquía, nunca un valor suelto).
- `stat_chip_campo.dart` — label mono arriba + valor grande abajo, con badge de alerta opcional debajo (p. ej. "Ráfagas" en ámbar junto a viento sostenido).
- `badge_estado_campo.dart` — pill chico de estado (pendiente/ok/reintento/genérico), color semántico fijado por un `enum`, no por string suelto.
- `selector_segmentado_campo.dart` — pill de N opciones con una seleccionada en lima.
- `barra_progreso_campo.dart` — track oscuro + fill lima, radio pill.
- `item_lista_campo.dart` — fila ícono/avatar + título/subtítulo + valor, patrón "line item" (mezcla, baterías, cola de sync).
- `boton_agregar_punteado_campo.dart` — slot con borde punteado, para "agregar ítem" o evidencia faltante.
- `banner_alerta_campo.dart` — franja de alerta (offline, ráfagas fuera de rango), color semántico.
- `nota_tecnica_campo.dart` — texto mono chico y atenuado dentro de una tarjeta sutil, para exponer estado de sync en la propia UI (coherente con invariante 1 de `CLAUDE.md`: el offline-first se ve, no se esconde).
- `encabezado_campo.dart` — header con botón "volver" circular + título, reemplaza el `AppBar` de Material por defecto en pantallas que adopten este modo.
- `barra_navegacion_campo.dart` — bottom nav con un botón de acción central elevado, insignia de conteo opcional por ítem (p. ej. "Sync 4").
- `grid_evidencias_campo.dart` — grid 2x2 de evidencias fotográficas; una celda sin miniatura se muestra como slot "agregar", en ámbar si es obligatoria.
- `componentes_campo.dart` — barrel file: un solo `import` para todo el catálogo.

**Iconografía**: `Icons.*` de Material, nunca los glifos Unicode crudos del mockup (→ ← ◉ ▤ ⌬ ↑ ◔ ⋯ ● ◆) — mismo criterio que ya usa el resto del código (`orden_detalle_pantalla.dart`, `login_vista.dart`), con mejor soporte de semántica/accesibilidad que un glifo suelto.

**Radios y espaciados** como constantes nombradas en `TemaCampo` (pill = 999, tarjeta grande = 24-26, tarjeta chica = 14-20, badge = 7-9), no números sueltos repetidos por pantalla.

## Alternativas descartadas

- **Reemplazar `AgrocomTheme.dark()` directamente con esta paleta**: prematuro — es un salto de contraste mucho mayor que el resto de la app, y decidir que este es *el* modo oscuro único de Agrocom Field es una decisión que le toca al dueño evaluar viendo pantallas reales construidas, no algo que este ADR deba forzar de entrada.
- **`google_fonts` para Manrope/JetBrains Mono**: ver tipografía arriba.
- **Glifos Unicode como iconografía real** (tal cual el mockup, pensado para verse en un navegador): se descartan por accesibilidad/semántica, a favor de `Icons.*`.
- **Colores nuevos por pantalla en vez de tokens**: exactamente el problema que ADR 0003 ya previno con `_cardTheme`/`_inputDecorationTheme` — un radio o una opacidad distinta a criterio de quien escribe cada pantalla nueva.

## Consecuencias

- El modo queda disponible para features nuevas que elijan adoptarlo; no migra ninguna pantalla existente por este ADR — login, órdenes y sesión de vuelo siguen con `AgrocomTheme` estándar hasta que se decida lo contrario.
- Transiciones/animaciones estándar (la otra mitad del criterio de aceptación de TE-15, `Hero`/`PageRouteBuilder`/estados de carga) quedan **fuera de este ADR** — se documentan aparte cuando haya una pantalla real que las necesite, para no fijar una convención de movimiento sin un caso concreto que la valide.
- `acentoRojo` sobre `fondoProfundo` pasa AA pero no AAA en texto normal (6.94:1) — aceptable para texto de alerta puntual (badge "RETRY"), no recomendado para bloques largos de texto en ese color.

## Ampliación (14/9/2026) — ronda 2 del mockup: tokens de tipografía y átomos que faltaban

El dueño trajo una segunda ronda del mismo mockup (`Agrocom Field.dc (1).html`, sección "Ronda 2 · pantalla de login": dos variantes de login sobre foto, 2a "foto plena" y 2b "hoja + último usuario") y fijó el criterio de construcción: **componentes reutilizables por pantalla, a la manera de atomic design pero más liviano** — tokens → átomos → moléculas → pantallas, sin la ceremonia de cinco niveles. Mismo estatus que la ronda 1: el HTML aporta el lenguaje visual, no el contenido — lo que la pantalla muestra sale de `docs/` y de `lib/`, nunca del demo. Y el nombre visible es «Agrocom» a secas (ver `CLAUDE.md`, convenciones): la etiqueta "FIELD · APLICACIÓN CON DRONES" del mockup no se reproduce.

Al recrear las primeras pantallas con el catálogo (`lib/nucleo/ui/vitrina_campo/`, vista previa solo alcanzable en `kDebugMode`) quedó a la vista lo que el catálogo inicial no cubría y cada pantalla repetía a mano:

**Tokens nuevos** (un nivel arriba de `componentes/`, junto a `ColoresCampo`):
- `TipografiaCampo` (`tipografia_campo.dart`) — escala tipográfica con nombre: `tituloHero`, `tituloPantalla`, `tituloSeccion`, `valorDestacado`, `tituloTarjeta`, `cuerpo`, `cuerpoSecundario` en fuente de plataforma; `etiquetaMono`, `datoMono`, `datoMonoDestacado`, `notaMono` en la monoespaciada nativa. Cada estilo fija familia, tamaño, peso y opacidad; un uso puntual ajusta con `copyWith`, nunca reescribe la familia. Antes cada pantalla armaba `TextStyle(fontFamily: 'monospace', fontSize: 11, ...)` a mano — el mismo problema que la sección de tokens de color ya había resuelto para el color.
- `ImagenesCampo` (`imagenes_campo.dart`) — rutas de los assets (logo y fondos de `assets/imagenes/` — el dueño reemplazó las tres fotos de Pexels de la ronda 1 por cinco fotos de drones Agras propias del proyecto el 14/9/2026; procedencia y peso en `FUENTES.md`), para que un rename se corrija en un solo lugar.

**Átomos nuevos** (`componentes/`, exportados por el barrel):
- `boton_circular_campo.dart` — extraído de `EncabezadoCampo` (era privado ahí) porque el onboarding y la vista previa lo necesitaban igual; `tamano` 40 por defecto, 56 junto a un CTA.
- `fondo_foto_campo.dart` — foto + degradado a `fondoProfundo` + contenido, con dos coberturas (`plena` para onboarding/login, `superior` para inicio/detalle). Es la única forma de poner una foto detrás de una pantalla: los tokens de contraste de este ADR se midieron sobre `fondoProfundo`, y el degradado es lo que garantiza que el texto llegue a ese fondo sobre cualquier foto.
- `logo_agrocom_campo.dart` — el logo tal como va sobre foto o fondo liso, con el `drop-shadow` del mockup hecho con una copia del PNG teñida y desenfocada (sigue la silueta; un `BoxShadow` rectangular no).
- `campo_texto_campo.dart` — el campo de texto del modo campo (label mono arriba, valor grande, borde lima con foco, acción corta opcional tipo "VER"). Envuelve un `TextFormField` real para que `Form`/validadores y las pruebas por `Key` sigan funcionando como con el campo "filled" de ADR 0003.
- `nota_inline_campo.dart` — "● texto" de una línea junto a un botón primario, color semántico.
- `pie_entorno_campo.dart` — flavor · entorno · versión al pie, con el entorno en ámbar: la respuesta del mockup a "no cargar contra producción por error" (ADR 0004). El widget recibe texto ya resuelto — no lee configuración.

**Cambios en átomos existentes**: `TarjetaCampo` y `ItemListaCampo` aceptan `onTap` (ripple recortado al radio, chevron en el ítem) — el patrón "fila que navega" aparecía en el mockup (roles, órdenes) y no tenía forma de hacerse sin un `GestureDetector` suelto por pantalla. `EncabezadoCampo` e `ItemListaCampo` pasan a leer sus estilos de `TipografiaCampo`.

**Qué NO se decide acá**: qué pantalla real migra al modo campo. El login real es la candidata obvia (la ronda 2 es literalmente sobre él) y se resuelve en su propio cambio, con la variante que corresponda al flujo real (token por dispositivo persistido ⇒ no hay "último usuario" que ofrecer, así que 2b no aplica tal cual). Transiciones/animaciones estándar siguen fuera, por el mismo motivo de la sección Consecuencias.
