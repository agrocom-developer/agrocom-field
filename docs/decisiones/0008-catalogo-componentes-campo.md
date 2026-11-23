# ADR 0008 — Catálogo de componentes «campo»: modo de alto contraste de los flavors `piloto` y `auxiliar`

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

El piloto y el auxiliar trabajan al aire libre: sol directo, guantes, el control remoto del dron (Android de gama media) y poca atención disponible. Esa condición pide un lenguaje visual de contraste muy alto, con objetivos táctiles grandes y una sola acción principal por pantalla. El flavor `cliente` no trabaja en esas condiciones y usa el tema claro de ADR 0003 (ver «Alcance»).

## Decisión

### Alcance

El modo campo es el tema global de los flavors `piloto` y `auxiliar` (`AgrocomThemeCampo.construir()` en el `MaterialApp`) y de todas sus pantallas: login, selector de rol, ofertas, servicio asignado, sesión de vuelo, incidencias, carga, bloqueo de versión y emergencia. Convive con `AgrocomTheme.light()` (ADR 0003), que usa el flavor `cliente`. Ambos lenguajes comparten tokens de espacio y radio en `nucleo/ui`.

El modo se expone como una `ThemeExtension` propia (`TemaCampo`) más los tokens `ColoresCampo` y `TipografiaCampo`. Una pantalla no declara colores, radios ni espacios propios.

### Tokens de color (`lib/nucleo/ui/colores_campo.dart`)

Contraste medido con la fórmula de luminancia relativa de WCAG:

| Token | Valor | Contraste medido |
|---|---|---|
| `fondoProfundo` | `#07110A` | — |
| `superficie` | `#0A1A0E` | — |
| `textoPrincipal` (sobre `fondoProfundo`) | `#F0FDF4` | 18.34:1 (AAA) |
| `acentoLima` (CTA/éxito/OK) | `#A3E635` | texto `fondoProfundo` sobre botón lima: 12.74:1 (AAA); texto lima sobre fondo profundo: 12.74:1 (AAA) |
| `acentoAmbarTexto` (alerta/pendiente) | `#FDE68A` sobre `fondoProfundo` | 15.42:1 (AAA) |
| `acentoAmbar` (fondo/borde de alerta) | `#FBBF24` | — (fondo translúcido, no texto) |
| `acentoRojo` (error/reintento) | `#F87171` sobre `fondoProfundo` | 6.94:1 (AA; no AAA en texto normal) |

`textoPrincipal` es un único color; la jerarquía se resuelve con opacidad (`.48` a `.8`), no con grises nuevos. `acentoRojo` sirve para texto de alerta puntual y no para bloques largos.

### Tipografía

Manrope para texto humano y JetBrains Mono para dato técnico (etiquetas en mayúscula, badges, marcas de tiempo, estado de sync). Son fuentes variables empaquetadas en `assets/fonts/` (SIL OFL 1.1; procedencia en `assets/fonts/FUENTES.md`) y declaradas en `pubspec.yaml`. No se usa el paquete `google_fonts`: resolver fuentes por red en ejecución contradice el funcionamiento sin señal del lote. `TipografiaCampo` define la escala con nombre: `tituloHero`, `tituloPantalla`, `tituloSeccion`, `valorDestacado`, `tituloTarjeta`, `cuerpo`, `cuerpoSecundario`, `etiquetaMono`, `datoMono` y `datoMonoDestacado`. Un ajuste puntual se hace con `copyWith`, nunca redefiniendo la familia en una pantalla.

### Catálogo de componentes (`lib/nucleo/ui/componentes/`)

Un archivo por widget, cada uno sobre `TemaCampo`/`ColoresCampo`:

- `boton_primario_campo.dart` — CTA pill lima, alto mínimo 56.
- `boton_secundario_campo.dart` — pill con borde, transparente.
- `boton_circular_campo.dart` — botón redondo (40 por defecto, 56 junto a un CTA).
- `tarjeta_campo.dart` — superficie translúcida con borde de 1 px; acepta `onTap` con ripple recortado.
- `stat_chip_campo.dart` — etiqueta mono arriba y valor grande abajo, con badge opcional.
- `badge_estado_campo.dart` — pill de estado (pendiente, ok, reintento, genérico) fijado por `enum`.
- `selector_segmentado_campo.dart` — pill de N opciones, con variante desplazable.
- `barra_progreso_campo.dart` — pista oscura con relleno lima.
- `item_lista_campo.dart` — fila ícono/avatar, título/subtítulo y valor; acepta `onTap`.
- `boton_agregar_punteado_campo.dart` — slot de borde punteado para agregar un ítem o una evidencia faltante.
- `banner_alerta_campo.dart` — franja de alerta semántica (sin red, fuera de rango).
- `nota_tecnica_campo.dart` — texto mono atenuado para exponer el estado de sincronización en pantalla.
- `nota_inline_campo.dart` — nota de una línea junto a un botón primario.
- `encabezado_campo.dart` — encabezado con botón «volver» y título, en lugar del `AppBar` por defecto.
- `barra_navegacion_campo.dart` — navegación inferior con acción central elevada e insignia de conteo.
- `grid_evidencias_campo.dart` — grilla 2x2 de evidencias; una celda sin foto es un slot «agregar», en ámbar si es obligatoria.
- `campo_texto_campo.dart` — campo de texto sobre un `TextFormField` real, con etiqueta mono, borde lima con foco y acción corta opcional.
- `fondo_foto_campo.dart` — foto con degradado a `fondoProfundo`; única forma de poner una foto detrás de una pantalla.
- `logo_agrocom_campo.dart` — logo sobre foto o fondo liso.
- `pie_entorno_campo.dart` — flavor, entorno y versión al pie, con el entorno en ámbar para no operar contra producción por error (ADR 0004).
- `componentes_campo.dart` — archivo barril: un solo `import` para todo el catálogo.

`ImagenesCampo` centraliza las rutas de `assets/imagenes/`.

### Reglas

- **Iconografía**: `Icons.*` de Material, nunca glifos Unicode crudos; llevan semántica y accesibilidad.
- **Radios y espacios**: constantes nombradas en `TemaCampo` (pill 999, tarjeta grande 24 a 26, tarjeta chica 14 a 20, badge 7 a 9).
- **Datos**: la pantalla muestra solo lo que existe en `drift` o en el contrato de `agrocom-api`; ningún dato de muestra llega a una pantalla real.
- **Estados**: cada pantalla define carga, vacío, error, sin red y éxito con los átomos del catálogo.
- **Pruebas**: cada átomo y cada pantalla tienen golden tests; una vista previa de componentes (`lib/nucleo/ui/vitrina_campo/`) solo es alcanzable en `kDebugMode`.

## Alternativas descartadas

- **Un único modo oscuro para los tres flavors**: el cliente usa la app en casa u oficina, con red y sin guantes; el contraste extremo y el acento lima le restarían claridad y confianza.
- **`google_fonts`**: ver «Tipografía».
- **Glifos Unicode como iconos**: sin semántica para lectores de pantalla.
- **Colores o radios por pantalla**: reintroduce la divergencia que los tokens evitan.

## Consecuencias

- El costo de arranque de las fuentes empaquetadas en un control remoto de gama media se vigila; si se degrada de forma perceptible, se revisa la tipografía.
- El tema del flavor `cliente` vive en ADR 0003 y en la tarea de sistema de diseño de la cola.
