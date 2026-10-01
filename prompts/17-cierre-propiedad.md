<!-- ciclo: critica=si turno-noche=1 rama=feature/cierre-propiedad etapas=2 descongela=tests -->

# Tarea 17 — TE-21: cerrar ADR 0020 (`campo` → `propiedad`) en la app

## Qué hacer

Cerrar la parte de TE-21 que el PR #49 no cubrió. El PR #49 ya renombró
`LoteCatalogo.campoId` → `propiedadId` (migración v9, `migracion_propiedad_test.dart`).
Falta **auditar** que no queden restos y dejar el criterio de TE-21 verificado
por un test, no por una lectura.

Cargá `verificacion`, `protocolo-sync` (toca `nucleo/db`) y `flujo-git-pr`.

Fuente del contrato: `/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml`
(solo lectura; este repo no tiene `docs/api/`). ADR 0020 está en
`/Applications/MAMP/htdocs/agrocom-api/docs/decisiones/`.

1. **`estadia_entrada`/`estadia_salida`.** `grep -rn estadia lib` no da nada:
   la app hoy no los emite. Confirmalo y dejalo escrito en `runs/17.md`. El
   contrato los define con `propiedad_id`, pero su pantalla no está en ninguna
   HU pendiente de este repo: **no construyas nada**, solo constatá.
2. **Textos de UI y dominio.** Buscá «campo» donde ahora es «propiedad»
   (`grep -rniE "\bcampo\b" lib`). Distinguí con cuidado: «modo campo»
   (`nucleo/ui/campo`, `vitrina_campo`, ADR 0008), `_Campo` del detalle de
   orden (una fila etiqueta/valor) y «en el campo» como lugar de trabajo
   **no** son el concepto eliminado. Cambiá solo lo que nombra la entidad
   `Campo` del negocio (p. ej. una etiqueta «Campo» que muestre una
   propiedad). Si no hay ninguna, no cambies nada y anotalo.
3. **Test de guarda.** Agregá un test en `test/nucleo/db/` que falle si el
   esquema actual de `drift` (`AppDatabase`) vuelve a tener una columna
   llamada `campo_id` en cualquier tabla (inspeccioná `allTables`/columnas).
   Las fixtures de migración vieja (`campo_id` en el DDL de
   `migracion_*_test.dart`) son legítimas: no las toques.
4. Verificá que la migración v8→v9 sigue en verde y que `schemaVersion` es 9
   (esta tarea **no** sube la versión).

## Cómo repartir las etapas

Etapa 1: auditoría (puntos 1, 2) y su registro. Etapa 2: test de guarda y cierre.

## Qué NO hacer

- No cambies `schemaVersion` ni agregues migración: TE-23 (tarea siguiente) es
  quien toca el esquema.
- No edites `CLAUDE.md` ni `docs/vision.md` (TE-24, fuera del ciclo).
- No renombres nada del modo campo ni de fixtures de migración vieja.
- No implementes estadías.

## Criterio de aceptación

`./bin/verify` devuelve 0, y además:
`grep -rniE "campo_?id" lib` solo devuelve comentarios que explican la
migración v9 (ninguna columna, campo Dart ni parser). El test de guarda existe
y pasa.

## Cierre obligatorio de cada etapa

`runs/17.estado` con una palabra: `PARCIAL`, `OK` o `BLOQUEADA`. `runs/17.md`
con qué se hizo y qué falta. Al cerrar con `OK`, `runs/17.pr.md`: título en la
primera línea, cuerpo debajo.

## Commits

Por pieza coherente (auditoría/textos si hubo cambios; test de guarda), en
español, imperativo, con el porqué. Sin trailer `Co-Authored-By`.
