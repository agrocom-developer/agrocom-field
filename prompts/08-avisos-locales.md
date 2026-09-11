<!-- ciclo: critica=no turno-noche=1 rama=feature/avisos-locales etapas=3 descongela=tests -->

# Tarea 08 — HU-62: avisos locales del dispositivo (recortada)

## Qué hacer

Implementar notificaciones locales generadas por reglas que corren en el
dispositivo, sin servidor push ni FCM (`docs/gestion/plan_sprints.md`,
Sprint 15, HU-62). Sprint 15 es enteramente del flavor `auxiliar` — el
flavor `piloto` no recibe trabajo nuevo todavía (nota del propio sprint),
así que esta feature se wirea solo en `main_auxiliar.dart`.

**Recorte explícito, con su porqué** (mismo criterio que ya usó HU-05 para
"cerrar trabajo"): la HU menciona tres disparadores de ejemplo — batería
caliente, sesión abierta hace muchas horas, orden nueva sincronizada. De
los tres, **hoy solo el tercero tiene datos locales para alimentarlo**:

- *Orden nueva sincronizada*: `OrdenCatalogo` ya existe y lo pueblan
  TE-06/HU-04 — implementable ahora.
- *Sesión abierta hace muchas horas*: `SesionLocal` la escribe y lee el
  piloto (invariante 4 de `CLAUDE.md`); el flavor `auxiliar` no tiene
  sesiones en su base local — no hay pull de sesión hacia el auxiliar
  (`GET /api/sync/catalogo` solo trae órdenes/lotes/personas). **Fuera de
  esta tarea.**
- *Batería caliente*: depende de `recarga` (HU-13, con
  `alerta_temperatura`), que a su vez depende de TE-07 (cola de
  evidencias) — ninguna de las dos existe en este repo todavía. **Fuera de
  esta tarea.**

Esta tarea entrega la HU con ese alcance recortado — construye la
infraestructura de notificación + el motor de reglas de forma extensible,
pero solo conecta la regla de "orden nueva" hoy. Dejá el recorte escrito en
`runs/08.md` igual que hizo `runs/05.md` con `cierre_trabajo`.

Cargá `verificacion` antes de cerrar etapas y `flujo-git-pr` antes de
rama/commits/PR. No es tarea crítica (no toca `nucleo/sync` ni
`nucleo/db`: lee `OrdenCatalogo` que ya existe, no agrega tablas).

### Piezas a construir

1. **`pubspec.yaml`** — agregar `flutter_local_notifications` (versión
   estable vigente).
2. **`lib/nucleo/notificaciones/notificador_local.dart`** — interfaz +
   impl, mismo patrón que `nucleo/auth` (abstracta para poder fakear en
   tests sin canal de plataforma real):
   - `abstract class NotificadorLocal { Future<bool> pedirPermiso();
     Future<void> mostrar({required int id, required String titulo,
     required String cuerpo}); }`
   - `class NotificadorLocalPlugin implements NotificadorLocal` — envuelve
     `FlutterLocalNotificationsPlugin`. `pedirPermiso()` cubre Android 13+
     (`POST_NOTIFICATIONS` en runtime — la propia API del plugin expone
     `requestNotificationsPermission()` en versiones recientes; usala en
     vez de sumar `permission_handler` como dependencia nueva).
   - Agregar el permiso en `android/app/src/main/AndroidManifest.xml`
     (`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`)
     y el ícono/canal por defecto que pida el plugin.
   - Registrar `NotificadorLocal` en `service_locator.dart`.
3. **`lib/features/avisos_locales/domain/`** — dominio puro (sin
   `flutter_local_notifications` ni `drift` acá):
   - Una función/clase que, dada la lista de `OrdenVigente` actual y el
     conjunto de ids ya notificados, devuelve cuáles son "nuevas" (mismo
     criterio de pureza que `reglas_sesion.dart` de `sesion_vuelo`).
4. **`lib/features/avisos_locales/data/`**:
   - Un store chico para persistir los ids/uuids de órdenes ya notificadas
     (`shared_preferences`, propio de esta feature — **no reutilices
     `PreferenciasStore` de TE-16**, que es solo tema/idioma/último
     flavor; esto es estado de la propia feature, no una preferencia de
     UI).
   - Un servicio (`AvisosLocalesWatcher` o nombre a tu criterio) que se
     suscribe al `Stream<List<OrdenVigente>>` de
     `OrdenesRepository.ordenesVigentes()` (mismo stream que ya consume
     `OrdenesCubit` — invariante 1, la UI y este watcher leen del mismo
     repositorio local, nunca de la red directo), descarta la primera
     emisión como línea de base (no notifica todo lo que ya estaba al
     arrancar) y dispara `NotificadorLocal.mostrar(...)` por cada orden
     nueva de ahí en adelante.
5. **Wiring** — instanciar y arrancar el watcher en `main_auxiliar.dart`
   después de `configurarDependencias` (vida larga, no atado al ciclo de
   una pantalla particular). `main_piloto.dart` no cambia.

### Tests

- Dominio: puro, sin widgets — casos con lista vacía, sin novedades, con
  una orden nueva, con varias.
- Data: `AvisosLocalesWatcher` con un fake de `OrdenesRepository`
  (`Stream` controlado a mano) y un fake de `NotificadorLocal` (mocktail o
  clase fake simple) — confirmar que la primera emisión no dispara nada y
  que una orden nueva sí, exactamente una vez (no reenviar la misma orden
  en la próxima emisión si no cambió el set de ids vistos).
- `NotificadorLocalPlugin`: si el canal de plataforma lo permite mockear
  con las herramientas de `flutter_test`, un test mínimo; si no es
  práctico, documentalo en `runs/08.md` como verificado solo por lectura
  de código (igual criterio que ya aceptó `CLAUDE.md` para piezas de
  infraestructura de plataforma puntuales).

## Cómo repartir las etapas

- Etapa 1: `NotificadorLocal`/`NotificadorLocalPlugin` + permiso Android +
  DI, con sus tests.
- Etapa 2: dominio (regla de "orden nueva") + store de ids vistos +
  `AvisosLocalesWatcher`, con tests puros y de integración liviana (stream
  fake).
- Etapa 3: wiring en `main_auxiliar.dart` + verificación manual de que
  `main_piloto.dart` no cambia + `runs/08.md` con el recorte documentado.

## Qué NO hacer

- No implementar "sesión abierta hace muchas horas" ni "batería caliente"
  — ver el recorte de arriba. No inventes un pull de sesión hacia el
  auxiliar ni una tabla `recarga` para destrabarlos: son dependencias que
  no existen, no un detalle de esta tarea.
- No reutilizar `PreferenciasStore` (TE-16) para el estado de "ya
  notificado" — son conceptos distintos aunque ambos usen
  `shared_preferences` por debajo.
- No agregar polling ni un temporizador de fondo (`WorkManager` o
  similar) — el disparador es el `Stream` reactivo del repositorio ya
  existente, igual criterio que ya sigue `OrdenesCubit`/`SyncCubit`. Un
  mecanismo de background nuevo es una decisión de infraestructura mayor,
  fuera de esta tarea.
- No tocar `main_piloto.dart`.
- No agregar `permission_handler` si la API del propio plugin de
  notificaciones ya cubre el permiso — no dupliques dependencias para lo
  mismo.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba —en
particular, un test que confirme que la primera emisión del stream de
órdenes nunca dispara notificaciones (solo las que llegan después cuentan
como "nuevas").

## Cierre obligatorio de cada etapa

`runs/08.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/08.md`: qué se hizo, qué falta, y el recorte (sesión/batería) documentado
explícito para que quede registrado en la cola.

Al cerrar con `OK`, `runs/08.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: dependencia + `NotificadorLocal`, dominio + store de vistos +
watcher, wiring en `main_auxiliar.dart`. Sin trailer `Co-Authored-By`.
