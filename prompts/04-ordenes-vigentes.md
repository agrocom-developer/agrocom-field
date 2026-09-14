<!-- ciclo: critica=no turno-noche=1 rama=feature/ordenes-offline etapas=2 descongela=tests -->

# Tarea 04 — HU-04: ver órdenes vigentes offline

## Qué hacer

Pantalla de lista + detalle de órdenes de aplicación vigentes, leyendo
**siempre** de `drift` (invariante 1 de `CLAUDE.md`) — el pull de catálogo
(TE-06, ya integrado) ya deja `OrdenCatalogo`/`LoteCatalogo` pobladas en
`lib/nucleo/db/tablas/`. Esta tarea no agrega ninguna tabla ni migración:
es pura lectura sobre lo que ya está local. No es tarea crítica.

Cargá el skill `verificacion` antes de cerrar cualquier etapa, y
`flujo-git-pr` antes de rama/commits/PR. `protocolo-sync` no hace falta —
no se toca `nucleo/sync` ni `nucleo/db`.

Contexto de datos (ya leído, no hace falta releer el backend):
`lib/nucleo/db/tablas/orden_catalogo.dart` (PK `id` de servidor,
`litrosHa`/límites climáticos y de vuelo como `Decimal`, `estado` texto
libre, `loteId` sin FK) y `lib/nucleo/db/tablas/lote_catalogo.dart` (PK `id`,
`codigo`, `hectareas` `Decimal`, `geometria` texto plano). Sin FK entre
ambas a propósito (el pull es incremental por cursor) — una orden puede
existir sin que su lote haya llegado todavía.

Piezas a construir, en `lib/features/ordenes/` (feature nueva, compartida
por los dos flavors — ambos roles pueden ver órdenes según espec §3, no va
en un futuro `piloto/`/`auxiliar/`):

1. **`domain/orden_vigente.dart`** — entidad Dart pura (`OrdenVigente` o el
   nombre que prefiera `arquitectura-flutter`): campos de `OrdenCatalogo`
   más `loteCodigo`/`loteHectareas` (nullable — el lote puede no haber
   llegado aún). Sin dependencia de `drift` ni `dio`, testeable sin
   emulador (ADR 0005).
2. **`data/ordenes_repository.dart`** — `OrdenesRepository` sobre
   `AppDatabase`: un método que devuelve `Stream<List<OrdenVigente>>`
   reactivo (`select(...).join(...).watch()` de `drift`, `leftOuterJoin`
   contra `LoteCatalogo` por `loteId`), filtrado por `estado == 'vigente'`
   (defensivo: el pull ya solo trae vigentes del lado servidor, pero no
   está de más filtrar acá — ver nota abajo), ordenado por fecha de
   emisión descendente. No hace falta una segunda consulta para el
   detalle: la pantalla de detalle recibe el `OrdenVigente` ya cargado en
   memoria desde la lista, por navegación.
3. **`presentation/`** — `OrdenesEstado` (sealed: cargando/lista/vacía),
   `OrdenesCubit` (se suscribe al `Stream` del repositorio, emite estados;
   cierra la suscripción en `close()`), `OrdenesVista`/`OrdenesPantalla`
   (mismo split que `features/auth`: vista pura testeable inyectando el
   cubit, pantalla arma el cubit real) y una pantalla de detalle que
   muestra todos los campos (litros/ha, límites climáticos, parámetros de
   vuelo, observaciones, fecha de emisión, lote).
4. Registrar `OrdenesRepository` en `lib/nucleo/di/service_locator.dart`.
5. **`lib/app.dart`**: reemplazar el placeholder de `_RaizApp`
   (`Scaffold(body: Center(child: Text('agrocom-field — ${flavor.name}')))`)
   por `OrdenesPantalla` cuando hay token — ese placeholder existe desde
   HU-03 exactamente para que esta tarea lo reemplace (ver el comentario
   en el archivo). Actualizá `test/app_test.dart`: el segundo caso ("con
   token guardado, salta el login") deja de verificar el texto del
   placeholder y pasa a verificar que aparece la lista de órdenes (podés
   necesitar una `AppDatabase` en memoria como fake/fixture para ese test,
   mismo patrón que ya usa `test/nucleo/catalogo/catalogo_repository_test.dart`
   con `NativeDatabase.memory()`).

**Nota sobre el filtro `estado == 'vigente'` en el cliente**: el pull de
catálogo del lado servidor (`LecturaOrdenesVigentesEloquent`) solo entrega
órdenes vigentes — pero una vez que una orden deja de serlo, el servidor no
vuelve a enviarla (deja de matchear el filtro), así que la fila local queda
tal cual quedó la última vez que sí era vigente. El filtro local no arregla
esa limitación (no es alcance de esta tarea, ni de TE-06 ya integrada) —
solo evita mostrar una fila con `estado` distinto de `'vigente'` si alguna
vez llega una encolada de otra forma. No lo documentes como solución a la
limitación, solo como filtro defensivo.

## Cómo repartir las etapas

- Etapa 1: `domain/` + `data/` (repositorio con el join reactivo) + tests
  de repositorio contra una base `drift` en memoria (primera carga vacía,
  join con lote presente/ausente, filtro de `estado`, reactividad: insertar
  una fila nueva y verificar que el `Stream` emite de nuevo).
- Etapa 2: `presentation/` (cubit + vista + pantalla de detalle) + wiring
  en `service_locator.dart`/`app.dart` + `test/app_test.dart` actualizado +
  tests de cubit (`bloc_test`) y de widget (lista, detalle, estado vacío).

## Qué NO hacer

- No agregar ningún botón ni flujo de "abrir trabajo" — eso es HU-05, tarea
  aparte sobre otra rama, que va a construir sobre esta pantalla.
- No tocar `OrdenCatalogo`/`LoteCatalogo` ni su migración — son de TE-06,
  ya integrada.
- No deserializar `LoteCatalogo.geometria` (HU-61, mapa, fuera de alcance)
  — mostrala como "sin datos" o simplemente no la muestres en el detalle.
- No construir un mecanismo de refresco manual/pull-to-refresh contra la
  red — esta pantalla solo lee `drift`; disparar un nuevo pull de catálogo
  es responsabilidad de otra pieza (no implementada todavía, fuera de
  alcance).

## Criterio de aceptación

`./bin/verify` devuelve 0. Entre los tests: reactividad del repositorio
(inserción posterior a la suscripción se refleja en el `Stream`), cubit
traduciendo cada estado del `Stream`, widget test de lista + detalle +
estado vacío, y `test/app_test.dart` actualizado y en verde.

## Cierre obligatorio de cada etapa

`runs/04.estado`: `PARCIAL` si avanzó pero la HU sigue abierta, `OK` recién
con las dos etapas completas y `bin/verify` en verde, `BLOQUEADA` si
aparece algo irresoluble acá (no debería, el contrato de datos ya está
confirmado arriba).

`runs/04.md`: qué se hizo y qué falta, concreto.

Al cerrar con `OK`, `runs/04.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que
el qué: uno para `domain/`+`data/` con sus tests, uno para `presentation/`,
uno para el wiring de `app.dart`/DI + actualización de `app_test.dart`. Sin
trailer `Co-Authored-By`.
