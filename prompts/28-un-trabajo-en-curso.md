<!-- ciclo: critica=si turno-noche=1 rama=feature/un-trabajo-en-curso etapas=2 descongela=tests -->

# Tarea 28 — un solo trabajo en curso y alineación del cierre dado de baja

## Qué hacer

Cierra dos pendientes que dejó la tarea 27 en
`docs/gestion/peticiones_agrocom_api/2026-10-01-trabajo-asignado-en-catalogo.md`.
Las decisiones son del dueño (2/10/2026).

Cargá `verificacion`, `protocolo-sync` (toca `TrabajoRepository`, que
escribe `trabajo_local` y encola en `cola_sync`) y `flujo-git-pr`.

Fuente: el **código** de `agrocom-api` (`/Applications/MAMP/htdocs/agrocom-api`,
solo lectura, develop con el PR de `feature/cierre-trabajo-dado-de-baja`).

### Etapa 1 — no abrir un segundo trabajo

Hoy «Abrir trabajo» desde `OrdenDetallePantalla` abre un trabajo nuevo
aunque haya otro en curso; solo se bloquea la segunda sesión.

1. Misma regla que «Crear aplicación» en «Inicio» (tarea 27): con una
   sesión abierta o un `trabajo_local` abierto, «Abrir trabajo» queda
   deshabilitado, con el motivo y un acceso a lo que está en curso.
   Reutilizá la regla de dominio que ya existe; no la dupliques.
2. Defensa también en el repositorio/cubit: `abrirTrabajo` y
   `abrirTrabajoAsignado` rechazan con un error de dominio si ya hay algo en
   curso, sin escribir ni encolar nada.
3. Volver al MISMO trabajo en curso no es un segundo trabajo:
   `abrirTrabajoAsignado` sigue siendo idempotente y lleva a ese trabajo.
4. Flavor auxiliar: sin cambios.

### Etapa 2 — trabajo dado de baja, alineado con el servidor

Desde ese PR, el servidor acepta el cierre de lo que ya estaba en curso
sobre un trabajo dado de baja, y sigue rechazando una sesión nueva.

1. Confirmalo en el código. Si difiere, PR en borrador con la diferencia y
   detenete.
2. El aviso de `dado_de_baja` de la pantalla de sesión dice lo correcto: no
   se abre una sesión nueva; la sesión abierta y el trabajo se cierran y se
   registran igual. La sesión nueva sigue bloqueada como en la tarea 27.
3. En la petición del 1/10/2026, el pendiente «cerrar un trabajo
   `dado_de_baja`» queda resuelto, con el PR y el SHA.

## Qué NO hacer

- Sin migración de esquema: si hiciera falta, detenete y avisá.
- No cambies el payload del sync ni el motor de sync. Ningún `uuid_cliente`
  nuevo para algo que ya existe (invariante 2).
- Mismas `Key`s. Los tests existentes no cambian de criterio.

## Criterio de aceptación

`./bin/verify` devuelve 0. Tests nuevos: «Abrir trabajo» deshabilitado con
sesión abierta y con trabajo abierto sin sesión, rechazo en el repositorio
sin escribir ni encolar, volver al mismo trabajo asignado sin abrir otro, y
el aviso nuevo de `dado_de_baja`.

## Commits

Uno o más por etapa, en español, imperativo, con el porqué. Sin
`Co-Authored-By`. PR contra `develop` marcado «revisión línea por línea
pendiente del dueño», con el SHA de `agrocom-api`.
