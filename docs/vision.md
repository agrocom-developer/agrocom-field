# Visión del proyecto — `agrocom-field`

Este documento orienta a quien empieza a trabajar en este repo sin tener que releer `agrocom-api` entero primero. No reemplaza la especificación ni los ADR — los resume y apunta al original. La fuente de verdad completa vive en `agrocom-api` (ruta local en esta máquina: `/Applications/MAMP/htdocs/agrocom-api`); si algo de acá y la fuente original no coinciden, gana la fuente original y este documento está desactualizado.

## Qué problema resuelve

Agrocom SRL aplica agroquímicos con drones (Agras) sobre lotes de sus clientes. El piloto y el auxiliar trabajan en el lote, sin conectividad — hay Starlink en la base, no en el campo. El sistema completo (backend + panel + esta app) automatiza doce funciones (operaciones, trazabilidad, acta de conformidad, reportes, gastos, ingresos, planilla, contabilidad básica, mantenimiento, inventario, portal del cliente, gestión de usuarios), pero **este repo solo cubre la primera pieza de esa cadena: capturar el dato en el lote con la misma fidelidad que si hubiera señal**, y no perder ni una hectárea a un reintento de red.

## Las dos apps, un solo código

Cuatro superficies en todo el sistema; dos de ellas son este repo (especificación §2):

| Superficie | Quién | Qué hace | Dónde |
|---|---|---|---|
| App piloto | Piloto | Abrir trabajo, condiciones, cerrar lote (ha + captura RC), incidencias, presentar acta | `agrocom-field`, flavor `piloto` |
| App auxiliar | Auxiliar | Caldo recibido, recargas, batería, combustible, incidencias | `agrocom-field`, flavor `auxiliar` |
| Panel web | Jefe de campo, encargado, dueño | Todo lo demás (validación, contratos, planilla, mantenimiento...) | `agrocom-api` |
| Portal cliente | Dueño del campo, agrónomo | Reportes de sus lotes, solo lectura | `agrocom-api` |

Piloto y auxiliar **se instalan por separado** (dos APK), pero para el desarrollo **son una sola base de código** con dos puntos de entrada (`main_piloto.dart` / `main_auxiliar.dart`) que comparten sincronización, autenticación, cola offline y evidencias. Un rol tiene, en la práctica, más permisos que su propio flavor: el jefe de campo puede abrir trabajo, registrar recarga, cerrar lote y validar trabajos de otros pilotos (especificación §3) — la especificación no resuelve todavía si eso lo hace desde una de estas dos apps o desde el panel web cuando está en el campo; confirmarlo antes de construir pantallas específicas para ese rol acá.

## El flujo de un lote, de punta a punta

1. El agrónomo del cliente emite una **orden de aplicación** vigente sobre un lote (litros/ha, parámetros de vuelo acordados). Sin orden vigente, el sistema no deja abrir trabajo.
2. El piloto **abre el trabajo**: valida que la orden exista y que las condiciones (viento, temperatura, humedad) estén dentro de rango, o las registra fuera de rango con observación firmada por el agrónomo (`autorizado_con_observación`).
3. El piloto **abre una sesión** (piloto + dron + hectárea inicial acumulada del lote — esto es lo que evita el doble conteo si otro piloto ya venía volando ese lote).
4. El auxiliar **recibe el caldo** del cliente (litros, calidad) y lo carga en **recargas** por sesión (litros, batería, temperatura de batería).
5. Cualquiera de los dos registra **incidencias** con evidencia si algo sale mal (caldo, ESC, batería, mecánica, clima).
6. El piloto **cierra la sesión**: hectáreas de esa sesión, captura del RC, motivo de cierre (completado / relevo de piloto / cambio de dron / falla / clima / fin de jornada / otro).
7. Si el lote quedó a medias (relevo, falla, fin de jornada), el trabajo queda `parcial` y un piloto entrante **abre una sesión nueva** — cada sesión se valida y se paga por separado, aunque compartan lote.
8. Del lado del panel web (fuera de este repo): el jefe de campo o el encargado **validan** cada sesión — nunca el propio piloto de esa sesión, a nivel de persona, no de rol — lo que dispara el devengo automático. Cuando todas las sesiones del trabajo están validadas, el agrónomo **firma el acta** y el lote queda conformado.

Detalle completo de la máquina de estados de sesión y trabajo: especificación §5.

## Lo que hoy contradice la especificación entre sí (y cuál versión seguir)

La especificación tiene una inconsistencia real que **todavía no se limpió** (`docs/gestion/estado_proyecto.md` de `agrocom-api` lo registra como pendiente de una reunión de cierre): §3 (tabla de roles) y §4.3 (modelo de datos, entidades `recetas_mezcla`/`receta_items`) todavía listan "preparar mezcla" y "definir receta" como algo que Agrocom hace. **Eso quedó obsoleto.** §7, fechada y cerrada el 1/9/2026 (decisión de negocio CR-01, confirmada en entrevistas de campo), es la versión vigente: **el cliente prepara su propio caldo con su propio agrónomo; Agrocom lo recibe ya hecho y lo rocía.**

Consecuencia concreta para este repo: la app del auxiliar **no modela fórmula, receta, dosis por hectárea, cálculo de producto por tanque, ni checklist de incorporación** — ni siquiera como campo opcional. Lo que sí registra, según §7.2:

- Litros de caldo recibidos, cuándo y quién lo entregó.
- Litros consumidos por sesión.
- Sobrante al cerrar (que se devuelve al cliente).
- Retraso o rechazo por calidad del caldo (tarde, mal estado, mal filtrado, cantidad insuficiente) — es la prueba de que una demora no fue responsabilidad del servicio de aplicación.

Si en algún momento se retoma el modelo de `recetas_mezcla`/`receta_items` de §4.3 para algo, es una señal de que la especificación cambió de nuevo — no construir sobre esas tablas sin confirmar primero que §7 sigue vigente.

## Arquitectura Flutter (ADR 0005 de `agrocom-api`, decisión completa ahí)

BLoC, feature-first, tres capas por feature — espejo de la arquitectura modular del backend:

```
lib/
├── nucleo/          # ~70% del código, compartido entre flavors
│   ├── db/           # drift: tablas espejo + outbox
│   ├── sync/          # motor: cola, push/pull, estados — sin BLoC
│   ├── auth/  evidencias/  catalogo/  ui/
│   └── di/            # get_it
├── features/
│   ├── sesion_vuelo/    # flavor piloto
│   ├── preparacion_mezcla/  # ver nota arriba: hoy es solo caldo, no fórmula
│   └── recargas/ incidencias/ cierre_lote/ ...
└── main_piloto.dart / main_auxiliar.dart
```

Reglas de fondo (ver `CLAUDE.md` para la lista numerada completa): los blocs leen de `drift`, nunca de la API directo; escribir es insertar local + encolar en outbox en una transacción; Cubit para pantallas simples, Bloc para flujos con transiciones (sesión, checklist); `domain/` de cada feature es Dart puro, testeable sin emulador; `piloto/` y `auxiliar/` no se importan entre sí.

## El protocolo de sincronización — el riesgo mayor del proyecto

Resumen de especificación §2.1 (leer el original antes de tocar el motor de sync):

1. Base local SQLite (`drift`); la UI siempre lee de ahí.
2. Patrón **outbox**: tabla `cola_sync` local, estados `pendiente → enviado → confirmado | rechazado`.
3. `POST /api/sync` recibe un lote ordenado causalmente (trabajo antes que sesión, sesión antes que recarga); el servidor procesa **registro por registro** en transacciones individuales y devuelve `aplicado` / `duplicado` / `rechazado {motivo}` por cada uno — un rechazo no frena el resto del lote.
4. Idempotencia en la base (`UNIQUE (uuid_cliente)`), no en el código: reintentar un lote ya aplicado da `duplicado`, que el cliente trata como éxito.
5. Referencias entre registros por `uuid_cliente`, nunca por id de servidor, mientras están offline.
6. Pull de catálogo con cursor: `GET /api/sync/catalogo?desde={cursor}` — órdenes vigentes, recetas, productos, lotes, personal.
7. Evidencias en cola separada de los registros livianos.
8. Orden por `secuencia` local, nunca por comparación de relojes entre dispositivos.

**La simplificación que elimina conflictos de merge**: cada tipo de registro tiene exactamente un rol escritor. No hay dos dispositivos editando la misma fila, así que no hace falta lógica de merge — solo inserciones idempotentes y anulaciones.

**Prueba obligatoria** antes de la primera pantalla: reproducir el mismo lote de sincronización 10 veces, en orden y en desorden parcial, y que el estado final de la base sea idéntico.

## Qué datos crea y lee esta app

Del modelo de datos completo (especificación §4.3), lo que toca este repo:

- **Crea** (con `uuid_cliente`, vía `POST /api/sync`): `trabajos`, `sesiones`, `condiciones`, `recargas`, `incidencias`, `evidencias`, `estadias_hacienda` (entrada/salida del equipo en la hacienda). El caldo recibido y su sobrante van por los endpoints dedicados (`/api/trabajos/{id}/caldo`, `/caldo/sobrante`), no por el genérico de sync.
- **No genera ni presenta el acta.** Decisión del dueño del 11/9/2026: el acta (`POST /api/trabajos/{id}/acta`) y su firma por el agrónomo (`POST /api/actas/{id}/firmar`, especificación §16) se manejan desde el panel web (`agrocom-api`), no desde esta app — queda fuera de alcance de `agrocom-field`.
- **Lee** (pull de catálogo con cursor): órdenes de aplicación vigentes, lotes, personal. **No lee ni construye** recetas/productos con fines de fórmula (ver la nota de arriba sobre §7 vs. §4.3).

## Roles que usan esta app

Tabla completa en especificación §3. Lo que aplica directo a los dos flavors:

| Acción | Piloto | Auxiliar |
|---|---|---|
| Abrir trabajo / condiciones | ✔ | — |
| Registrar recarga y batería | — | ✔ |
| Registrar incidencia | ✔ | ✔ |
| Cerrar lote (ha + captura RC) | ✔ | — |
| Generar y presentar acta | ✔ | — |

Identidad: token por dispositivo (Sanctum, revocable desde el panel sin bloquear al usuario), no login de usuario/contraseña en cada sesión de uso — pero si la persona tiene más de un rol, el rol activo lo determina el flavor que abrió, no una elección en pantalla (a diferencia del panel web, donde sí se elige rol activo al iniciar sesión).

## Máquinas de estado que la app dispara pero no decide

La app **pide** una transición (por ejemplo, "cerrar sesión"); el servidor la aplica contra su tabla de transiciones permitidas y sus guardas (ADR 0003 de `agrocom-api`, invariante 7). El bloc modela el estado que el servidor confirma, nunca inventa una transición local.

- **Sesión**: `abierta → en_ejecucion → cerrada → validada` (o `cerrada_por_relevo` / `cerrada_por_falla` → abre una sesión nueva).
- **Trabajo**: `planificado → autorizado → en_ejecucion → parcial → completo → validado → conformado → facturado`, con `bloqueado` / `autorizado_con_observacion` como ramas.

Detalle completo y condiciones de cada transición: especificación §5.

## Endpoints que consume esta app

Contrato completo (payloads, códigos de respuesta) en `agrocom-api/docs/api/openapi.yaml`, generado code-first (ADR 0014) — nunca se edita a mano desde acá. Subconjunto relevante de especificación §8:

```
POST   /api/sync                        Lote offline, idempotente por uuid_cliente
GET    /api/ordenes?lote_id=&estado=    Órdenes vigentes para el piloto
POST   /api/trabajos                    Abrir trabajo
POST   /api/trabajos/{id}/sesiones      Abrir sesión
POST   /api/sesiones/{id}/condiciones   Registrar condiciones
POST   /api/trabajos/{id}/caldo         Caldo recibido del cliente
POST   /api/trabajos/{id}/caldo/sobrante  Sobrante al cerrar
POST   /api/sesiones/{id}/recargas      Recarga + batería + litros
POST   /api/sesiones/{id}/incidencias   Incidencia con evidencia
POST   /api/sesiones/{id}/cerrar        Hectáreas + captura RC + motivo
POST   /api/trabajos/{id}/imagen        Imagen del campo (dron)
POST   /api/trabajos/{id}/acta          Generar acta
POST   /api/actas/{id}/firmar           Firma del agrónomo
GET    /api/version                     Versión mínima/autorizada del APK (polling, sin FCM)
```

## Estado actual (10/9/2026)

- Este repo se acaba de crear: sin `flutter create` corrido todavía, sin `pubspec.yaml`. El workstation (este documento, `CLAUDE.md`, CI/CD, agentes y skills) se arma antes que el código para que el primer commit de código ya tenga dónde encajar.
- Del lado `agrocom-api`: TE-05 (`POST /api/sync` idempotente) es la tarea crítica en curso — el contrato que esta app va a consumir se está terminando de construir ahora mismo. TE-04 (base local `drift` + outbox) y TE-06 (pull de catálogo, lado app) son de este repo y siguen sin empezar.
- GitFlow: `develop` recién creado acá, siguiendo el mismo patrón que `agrocom-api` (ADR 0006, "en ambos repositorios").

## Qué NO hace esta app

- No formula ni calcula composición de mezcla (ver la nota sobre §7 arriba) — el sistema registra volumen, nunca fórmula.
- No decide una transición de estado por su cuenta ni corre lógica de devengo, validación o facturación — todo eso es autoridad del servidor.
- No define su propio modelo de permisos — hereda `sec_*` del backend; acá solo hay token por dispositivo y el rol que trae ese token.
- No es una app con red garantizada: cualquier pantalla que asuma "la API va a responder ahora" está mal planteada — ver invariantes 1 y 3 de `CLAUDE.md`.
