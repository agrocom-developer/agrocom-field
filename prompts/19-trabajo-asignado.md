<!-- ciclo: critica=si turno-noche=1 rama=feature/trabajo-asignado etapas=5 descongela=tests -->

# Tarea 19 — HU-70 (lado app): mostrar el trabajo ya asignado al iniciar sesión

## Qué hacer

El jefe de campo asigna un trabajo desde el panel; el piloto tiene que verlo
al entrar, sin que se lo manden por WhatsApp. Hoy `GET /api/sync/catalogo` ya
trae `trabajos` pero `CatalogoRepository.pull()` nunca los lee. Esta tarea
cubre **la HU-70 entera** de `docs/gestion/plan_sprints.md` (Sprint 16):

- Tabla `drift` de solo lectura para `TrabajoCatalogo` + upsert en `pull()`.
- Pantalla «Inicio» del flavor piloto con el trabajo asignado.
- Botón «Crear aplicación» que abre el flujo de sesión **sobre ese trabajo**.
- Estado vacío explícito si no hay trabajo asignado.

Asume integradas 17 y 18 (esquema en v9 o v10 según TE-23). Cargá
`verificacion`, `protocolo-sync` (esquema + pull) y `flujo-git-pr`.

Contrato: `/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml`,
esquema `TrabajoCatalogo` (solo lectura). `runs/18.md` deja anotado qué
cubrir. El `uuid_cliente` lo generó el panel: **se usa tal cual**, la app no
lo regenera (invariante 2 aplicada a un registro de origen servidor).

### Piezas

1. **Esquema.** Tabla `TrabajoCatalogo` en `lib/nucleo/db/tablas/`
   (`id`, `uuidCliente` único, `ordenId`, `loteId`, `hectareasDeclaradas`
   con `DecimalDriftConverter`, `equipoTrabajoId`, `updatedAt`). Es distinta
   de `TrabajoLocal` (que escribe el piloto): **no las mezcles** — un solo
   rol escritor por tipo de registro (invariante 4). Migración de una versión
   con test (mismo patrón que `migracion_propiedad_test.dart`).
2. **Pull.** `CatalogoRepository.pull()` upsertea `trabajos` en la misma
   transacción que el cursor. Idempotente: aplicar la misma página varias
   veces deja la base idéntica (extender la prueba de idempotencia existente,
   `catalogo_repository_idempotencia_test.dart`). Que `trabajos` no vacíos
   cuenten para el «hay más» del loop de catálogo, con test.
3. **Repositorio y dominio** en `lib/features/inicio/` (feature nueva, capas
   `data/domain/presentation`): stream reactivo del trabajo asignado con su
   orden y lote (`Stream` sobre `drift`, nunca la red — invariante 1).
   Definí y documentá la regla para «el trabajo asignado» si hay varios (p. ej.
   el más reciente por `updatedAt`, o lista); la HU habla de uno: decidí lo
   mínimo, anotalo en `runs/19.md`.
4. **Pantalla «Inicio»** (piloto): lote, hectáreas, l/ha o kg/vuelo (el que no
   sea nulo, nunca ambos), y estado vacío explícito «sin trabajo asignado»,
   jamás un dato inventado. Usá los átomos de `nucleo/ui/componentes` (ADR
   0008); no inventes widgets sueltos. Wiring en `main_piloto.dart` como
   pantalla inicial tras login. Sin importar `auxiliar/`.
   **Diseño**: la pantalla se construye en modo campo
   (`AgrocomThemeCampo.construir()`, decisión del dueño del 1/10/2026 en ADR
   0008) siguiendo `lib/nucleo/ui/vitrina_campo/inicio_piloto_campo_vitrina.dart`
   (la 03, con barra de navegación): foto superior, saludo, tarjeta del
   trabajo asignado con `StatChipCampo` (hectáreas, l/ha o kg/vuelo, lotes) y
   «Crear aplicación» con `BotonPrimarioCampo`. De la 03 se muestra **solo lo
   que tenga fuente en `drift`**: el clima de la tarjeta, «Sync 4»,
   «Equipos» y el nombre son mock. La `BarraNavegacionCampo` lleva solo
   destinos con pantalla real (Inicio y Órdenes); si el banner de pendientes
   necesita el conteo del outbox, leelo del repositorio local existente o
   dejalo fuera y anotalo — no lo inventes.
5. **«Crear aplicación».** Abre el flujo de sesión existente
   (`features/sesion_vuelo`) sobre **ese** `trabajo_uuid_cliente`. Investigá
   cómo hoy `TrabajoLocal` se crea al abrir trabajo; el trabajo asignado
   necesita su fila en `TrabajoLocal` con el mismo `uuid_cliente` del panel
   **sin encolar un `trabajo` nuevo al servidor** (ya existe allá). Si eso
   contradice el modelo actual y no se resuelve sin una decisión de
   arquitectura nueva, cerrá la etapa `BLOQUEADA` explicando la pregunta
   exacta; no inventes un merge (invariante 4).

## Cómo repartir las etapas

1: esquema + migración + test. 2: pull + idempotencia. 3: repositorio y
dominio (Cubit con tests). 4: pantalla + estado vacío + wiring. 5: «Crear
aplicación» sobre el trabajo asignado y cierre.

## Qué NO hacer

- No registres mezcla (HU-78), ni cambies el formulario por categoría de
  insumo ni «Ráfagas» (HU-79), ni reporte de equipos (HU-80).
- No toques el outbox ni `SyncEngine`.
- No leas de la red desde un bloc.
- No uses `double` para hectáreas (invariante 9).
- No ocultes «Sesiones»/«Pausas»: es HU-79.
- No reescribas migraciones anteriores ni el cursor.

## Criterio de aceptación

`./bin/verify` devuelve 0, con tests que cubran cada criterio de HU-70:
tabla y upsert idempotente de `trabajos`, pantalla con el trabajo asignado
(lote, hectáreas, l/ha o kg/vuelo, nunca ambos), estado vacío explícito, y
«Crear aplicación» abriendo sesión sobre ese trabajo. Prueba de migración con
filas conservadas.

## Cierre obligatorio de cada etapa

`runs/19.estado` (`PARCIAL`/`OK`/`BLOQUEADA`), `runs/19.md` con qué se hizo y
qué falta, y al cerrar con `OK`, `runs/19.pr.md` (título en la primera línea).

## Commits

Por pieza (esquema, pull, repositorio, pantalla, flujo), en español,
imperativo, con el porqué. Sin `Co-Authored-By`.

*Nota: esta tarea asume 17 y 18 integradas; si TE-23 cambió el esquema, usá la
versión que haya dejado.*
