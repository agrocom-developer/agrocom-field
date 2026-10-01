<!-- ciclo: critica=no turno-noche=1 rama=feature/ordenes-modo-campo etapas=2 descongela=tests -->

# Tarea 20 — Órdenes vigentes y detalle de orden al modo campo (ADR 0008)

## Qué hacer

Después del login (que ya está en modo campo), «Órdenes vigentes» y «Orden N.º»
se ven con el Material estándar de ADR 0003: `AppBar`, `Card` + `ListTile`,
filas «Etiqueta: valor» sin jerarquía. El dueño lo vio en el dispositivo y
decidió que todas las pantallas reales migran al modo campo — ADR 0008,
sección «Decisión (1/10/2026)». Esta tarea migra las dos pantallas de la
feature `ordenes` (HU-04), **solo el aspecto**.

Cargá `verificacion` y `flujo-git-pr`. No toca `nucleo/db` ni `nucleo/sync`.

Referencias (leelas antes de escribir):

- `lib/nucleo/ui/vitrina_campo/orden_detalle_campo_vitrina.dart` — la
  pantalla 08 de la vista previa: foto superior con `FondoFotoCampo`
  (`CoberturaFondoFoto.superior`), `BotonCircularCampo` para volver,
  `BadgeEstadoCampo` de estado, tarjetas por sección, `StatChipCampo` para
  los valores clave y el CTA con `BotonPrimarioCampo`. Su `dartdoc` lista qué
  del mockup se descartó por no estar en el contrato: respetalo.
- `lib/features/auth/login_vista.dart` — cómo una pantalla real se envuelve
  en `AgrocomThemeCampo.construir()`.
- ADR 0008 completo (`docs/decisiones/0008-catalogo-componentes-campo.md`).

### Piezas

1. **Lista** (`ordenes_vista.dart`): fondo `ColoresCampo.fondoProfundo`,
   título con `TipografiaCampo.tituloPantalla` (sin `AppBar` de Material),
   cada orden con `ItemListaCampo`/`TarjetaCampo` tocable (lote como título,
   «Aplicación N.º · l/ha o kg/vuelo · fecha» como dato mono). Estado vacío
   explícito con el mismo texto de hoy. El botón de emergencia (HU-68) sigue
   visible y accesible en un toque.
2. **Detalle** (`orden_detalle_pantalla.dart`): mismo lenguaje que la 08 —
   encabezado sobre foto, badge del estado de la orden, secciones (lote/s,
   aplicación, límites climáticos, parámetros de vuelo, observaciones) como
   tarjetas, y «Abrir trabajo» como `BotonPrimarioCampo`. Un valor nulo se
   muestra como hoy («sin datos»), **nunca** un dato inventado; si la orden
   trae `litros_ha` se muestra ese y si trae `kilos_por_vuelo` ese otro, nunca
   ambos.
3. Los campos que muestra cada pantalla son **los que hoy expone
   `OrdenVigente`** (con lo que haya dejado TE-23, tarea 18). Esta tarea no
   agrega ni quita campos del dominio: si la 08 muestra algo que
   `OrdenVigente` no tiene (p. ej. `lotes[]` con hectáreas por lote y el
   dominio todavía no lo expone), no lo inventes — anotalo en `runs/20.md`
   como pendiente.

## Cómo repartir las etapas

1: lista + sus tests. 2: detalle + sus tests y cierre.

## Qué NO hacer

- No cambies `OrdenesCubit`, `OrdenesRepository`, `OrdenVigente` ni ninguna
  tabla `drift`: es una migración visual.
- No cambies ninguna `Key` existente (`ordenes_lista`, `ordenes_vacia`,
  `orden_<id>`, `boton_abrir_trabajo`, …): los tests de comportamiento tienen
  que seguir pasando con el mismo criterio. Si un test busca un widget de
  Material por tipo (`find.byType(ListTile)`), cambialo a la `Key`, sin
  cambiar lo que verifica.
- No uses colores, radios, opacidades ni `TextStyle` sueltos: todo sale de
  `ColoresCampo`, `TemaCampo`, `TipografiaCampo` y los átomos del catálogo.
  Si falta un átomo, agregalo a `lib/nucleo/ui/componentes/` y exportalo en
  el barrel — no un widget privado en la pantalla.
- No muestres datos de la vista previa que no tengan fuente en `drift`.
- No toques la vista previa (`vitrina_campo/`) ni el login.
- No importes `piloto/` ni `auxiliar/` entre sí.

## Criterio de aceptación

`./bin/verify` devuelve 0, y además: ninguna de las dos pantallas usa
`AppBar`, `Card`, `ListTile` ni `FilledButton` de Material
(`grep -nE "AppBar|ListTile|\bCard\(|FilledButton" lib/features/ordenes/presentation`
sin resultados); las dos se construyen bajo `AgrocomThemeCampo.construir()`;
un test de widget por pantalla cubre el estado con datos y el estado vacío o
con nulos («sin datos», nunca `litros_ha` y `kilos_por_vuelo` a la vez).

## Cierre obligatorio de cada etapa

`runs/20.estado` con una palabra: `PARCIAL`, `OK` o `BLOQUEADA`. `runs/20.md`
con qué se hizo y qué falta. Al cerrar con `OK`, `runs/20.pr.md`: título en la
primera línea, cuerpo debajo.

## Commits

Uno por pantalla, en español, imperativo, con el porqué. Sin trailer
`Co-Authored-By`.
