<!-- ciclo: critica=si turno-noche=1 rama=feature/sesion-en-curso etapas=3 descongela=tests -->

# Tarea 27 — sesión en curso y trabajos no vigentes en «Inicio»

## Qué hacer

Resuelve los tres pendientes de
`docs/gestion/peticiones_agrocom_api/2026-10-01-trabajo-asignado-en-catalogo.md`
que quedaron después de la tarea 26. Las decisiones son del dueño (1/10/2026).

Cargá `verificacion`, `protocolo-sync` (lee `sesion_local`, `trabajo_local`
y `cola_sync`) y `flujo-git-pr`.

Fuente: el **código** de `agrocom-api` (`/Applications/MAMP/htdocs/agrocom-api`,
solo lectura, develop con #313). Confirmá en
`EscrituraSincronizacionEloquent::abrirSesion()` y `registrarCondiciones()`
qué rechaza el servidor en cada caso. Si no coincide con lo de abajo, PR en
borrador con la diferencia y detenete.

### Etapa 1 — volver a una sesión o a un trabajo en curso (flavor piloto)

Hoy, si el piloto sale de la pantalla de sesión, pierde el acceso a una
sesión que sigue abierta: el estado «sesión activa» vive solo en la memoria
de `SesionBloc`.

1. Leé de `drift` (nunca de la red) lo que este dispositivo tiene en curso:
   una `sesion_local` abierta o, si no hay, un `trabajo_local` abierto.
2. «Inicio» muestra arriba de todo una tarjeta «Sesión en curso» o «Trabajo
   en curso» (lote, inicio, motivo de retiro si el trabajo quedó retirado),
   con un botón que lleva a `SesionVueloPantalla` de ESE trabajo. Se muestra
   aunque el trabajo esté retirado o sea un trabajo abierto por la app (sin
   fila en `trabajo_catalogo`).
3. `SesionBloc` arranca en el estado que corresponde a lo que hay en `drift`:
   con la sesión abierta → `SesionActiva` con ESA sesión (mismo
   `uuid_cliente`); sin sesión abierta → `SesionInicial`, desde donde se
   puede cerrar el trabajo. Evento o carga inicial nueva; no cambies los
   eventos existentes, el payload ni la lógica de apertura/cierre.
4. Mientras haya algo en curso, «Crear aplicación» sobre otro trabajo queda
   deshabilitado, con el motivo. No dejes dos sesiones abiertas a la vez.
5. Si el modelo permite más de una sesión o trabajo abierto a la vez, mostrá
   el más reciente por `secuencia` local (invariante 5, nunca por reloj) y
   anotalo como pendiente.

### Etapa 2 — trabajo de una orden pausada

El servidor no retira los trabajos de una orden pausada y acepta sesiones
sobre ellos, pero el dueño decidió que no se vuele sobre una orden pausada:

1. Si la orden del trabajo asignado está retirada con estado `pausada`,
   «Inicio» muestra el trabajo con un badge «Orden pausada» y «Crear
   aplicación» deshabilitado, con el motivo. Cuando la orden vuelve a
   vigente, se habilita solo.
2. Una sesión ya abierta sobre ese trabajo no se toca: se puede seguir y
   cerrar.

### Etapa 3 — sesión nueva sobre un trabajo dado de baja

El servidor rechaza con `trabajo_no_existe_aun` una sesión nueva sobre un
trabajo `dado_de_baja`. Si el piloto la carga sin señal, se pierde al
sincronizar:

1. Con motivo `dado_de_baja`, la app no permite abrir una sesión NUEVA (ni
   desde «Inicio» ni desde `SesionVueloPantalla`): se bloquea en el
   formulario, con el motivo. Cerrar una sesión ya abierta y cerrar el
   trabajo se siguen permitiendo.
2. `reasignado`, `cerrado`, `orden_cerrada` y `fuera_de_alcance`: el
   servidor acepta sesiones nuevas, no las bloquees. Mostrá el motivo como
   aviso en la pantalla de sesión.

## Qué NO hacer

- Sin migración de esquema: si hiciera falta, detenete y avisá.
- No cambies el payload del sync ni el motor de sync. Ningún `uuid_cliente`
  nuevo para algo que ya existe (invariante 2).
- Mismas `Key`s. Los tests existentes no cambian de criterio.

## Criterio de aceptación

`./bin/verify` devuelve 0. Tests nuevos: volver a una sesión abierta y
cerrarla, volver a un trabajo abierto sin sesión y cerrarlo, trabajo
retirado con sesión abierta visible en «Inicio», «Crear aplicación»
deshabilitado con algo en curso, orden pausada → reanudada, y sesión nueva
bloqueada solo con `dado_de_baja`. Al terminar, la petición del 1/10/2026
marca resueltos los pendientes que esta tarea cierra.

## Commits

Uno o más por etapa, en español, imperativo, con el porqué. Sin
`Co-Authored-By`. PR contra `develop` marcado «revisión línea por línea
pendiente del dueño», con el SHA de `agrocom-api`.
