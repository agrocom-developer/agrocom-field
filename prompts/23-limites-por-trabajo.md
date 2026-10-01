<!-- ciclo: critica=si turno-noche=1 rama=feature/limites-por-trabajo etapas=3 descongela=tests -->

# Tarea 23 — límites climáticos y de vuelo del trabajo asignado

## Qué hacer

El servidor dejó de mandar en `ordenes[]` los campos de clima y vuelo, y
ahora manda siete de ellos en `trabajos[]` del pull de catálogo. La app los
sigue leyendo de `orden_catalogo`, donde llegan en `null`, así que «Límites
climáticos» del detalle de orden muestra «sin datos» aunque el jefe de campo
los haya cargado al asignar.

Cargá `verificacion`, `protocolo-sync` (toca `nucleo/db` y el pull) y
`flujo-git-pr`.

Fuente: el **código** de `agrocom-api` (`/Applications/MAMP/htdocs/agrocom-api`,
solo lectura), no solo `openapi.yaml`, que puede estar atrasado.
Lo que manda es `Operaciones/Contratos/TrabajoAsignadoCatalogo::toArray()`
y `Operaciones/Infraestructura/LecturaTrabajosAsignadosEloquent`.

Pasos:

1. **Contraste.** Confirmá en ese código la lista exacta de campos de
   `trabajos[]` y su nulabilidad real. Nada que no esté en el código.
2. **Migración v12.** Agregá esas columnas a `trabajo_catalogo` con
   `ALTER TABLE` (nullable, sin perder filas) y reseteá el cursor para que el
   próximo pull vuelva a traer los trabajos ya bajados y complete las
   columnas nuevas. Prueba de migración v11→v12 con filas reales en todas las
   tablas, mismo patrón que `migracion_trabajo_catalogo_test.dart`. La prueba
   de replay sigue en verde.
3. **Pull.** Parseá esos campos de `trabajos[]` con la nulabilidad real
   (`Decimal`, nunca `double`: invariante 9). Extendé el fixture y el test de
   contrato.
4. **Pantallas.** El detalle de orden e «Inicio» muestran los límites del
   trabajo asignado de esa orden si existe, y si no, «sin datos». El trabajo
   asignado de una orden se elige con la misma regla que «Inicio»: el más
   reciente por `updated_at` del servidor entre los que este dispositivo no
   cerró. No inventes un valor ni lo tomes de otro trabajo. Mismas `Key`s;
   los tests existentes no cambian de criterio; agregá tests con y sin
   trabajo asignado.
5. Si al leer el código encontrás respuestas a las preguntas de
   `docs/gestion/peticiones_agrocom_api/2026-10-01-trabajo-asignado-en-catalogo.md`,
   anotalas en el PR. No las implementes acá.

## Cómo repartir las etapas

Etapa 1: contraste + migración v12 con su prueba. Etapa 2: parser, fixture y
test de contrato. Etapa 3: repositorios, pantallas y sus tests.

## Qué NO hacer

- No borres las columnas de clima/vuelo de `orden_catalogo`: queda para otra
  migración, cuando nada las lea.
- No filtres por equipo, no retires trabajos ni cambies el cierre de trabajo
  (preguntas abiertas de la petición del 1/10/2026).
- No pongas `double` en ningún decimal (invariante 9): `Decimal`.
- No edites `openapi.yaml` ni nada de `agrocom-api`.
- No reescribas migraciones anteriores.

## Criterio de aceptación

`./bin/verify` devuelve 0. La prueba v11→v12 conserva las filas de todas las
tablas, agrega las columnas en `null` y resetea el cursor. El test de
contrato parsea los siete campos de `trabajos[]`, con valor y en `null`. El
detalle de orden e «Inicio» muestran los límites del trabajo asignado, y
«sin datos» cuando la orden no tiene trabajo asignado.

## Cierre obligatorio de cada etapa

`runs/23.estado` (`PARCIAL`/`OK`/`BLOQUEADA`), `runs/23.md` con qué se hizo y
qué falta, y al cerrar con `OK`, `runs/23.pr.md` (título en la primera línea).

## Commits

Por pieza (esquema+migración, parser+contrato, pantallas), en español,
imperativo, con el porqué. Sin `Co-Authored-By`.
