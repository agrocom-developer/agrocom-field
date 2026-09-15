# CLAUDE.md — invariantes de `agrocom-field`

Este repo es la app de campo de Agrocom SRL: **Flutter, una sola base de código con dos flavors** (`piloto`, en el RC Android del dron; `auxiliar`, en el celular Android), sin conectividad en el lote. Es el hermano de `agrocom-api` (backend Laravel + panel web) — mismo dueño único, mismos agentes de IA como implementadores principales, mismas invariantes de fondo, adaptadas al lado cliente.

**La fuente de verdad funcional/técnica no vive en este repo.** Vive en `agrocom-api`, clonado en esta misma máquina en `/Applications/MAMP/htdocs/agrocom-api`:

- `docs/especificacion/especificacion_funcional_tecnica.md` — sobre todo §2 (arquitectura y protocolo de sincronización, "el problema de mayor riesgo del proyecto"), §3 (roles), §4.3 (modelo de datos de Operación), §5 (máquinas de estado), §7 (alcance del caldo/mezcla), §8 (endpoints).
- `docs/decisiones/0005-flutter-bloc-feature-first.md` — la decisión de arquitectura que rige este repo entero.
- `docs/decisiones/0006-gitflow-simplificado.md`, `0008-separacion-backend-frontend-monolito.md`, `0014-documentacion-api-code-first-openapi.md`.
- `docs/api/openapi.yaml` — el contrato de API que este repo consume. Se regenera del lado `agrocom-api`; acá nunca se edita a mano.

Este `CLAUDE.md` no repite ese contenido — lo resume donde hace falta y remite al original. `docs/vision.md` en este mismo repo da el panorama completo para no tener que cruzar de repo en cada tarea nueva. Si la ruta de arriba cambia (otra máquina, otro clon), actualizala acá y en `docs/vision.md` antes de seguir trabajando.

## Invariantes no negociables

Adaptación al lado cliente de las invariantes ya vigentes en `agrocom-api` — mismo principio, ejecutado del otro lado de la sincronización. Fundamento completo en la especificación §2 y §2.1, y en ADR 0005.

1. **Offline-first sin excepción.** La UI nunca lee de la red directamente: siempre de `drift` (SQLite local). Un bloc que llama a la API en vez de leer un `Stream` del repositorio local es un bug de arquitectura, no un detalle de implementación.
2. **Todo registro nace con su `uuid_cliente` en el dispositivo**, antes de tocar la red — nunca se genera en el servidor ni se reutiliza entre reintentos. Es lo que hace la sincronización idempotente del otro lado (`UNIQUE (uuid_cliente)`).
3. **Escribir = insertar local + encolar en outbox, en una sola transacción.** Ningún bloc espera respuesta del servidor para confirmar una acción del usuario — la pantalla ya cambió antes de que exista señal.
4. **Un solo rol escritor por tipo de registro.** La sesión la escribe el piloto, la mezcla el auxiliar — nunca dos dispositivos editando la misma fila. Si una pantalla nueva necesitara que dos roles toquen el mismo registro, la respuesta correcta es dividirlo en dos registros, nunca escribir lógica de merge.
5. **Orden causal explícito por `secuencia` local, nunca por reloj de dispositivo.** Los relojes de dos celulares no se comparan entre sí; lo que ordena un lote de sync es la secuencia que cada dispositivo lleva de sus propios registros.
6. **Ningún registro ya confirmado por el servidor se reescribe localmente.** Una corrección es un registro nuevo con motivo y autor — el mismo principio del lado servidor (nunca sobrescribir lo validado), aplicado también a lo que ya se sincronizó.
7. **`piloto/` y `auxiliar/` no se importan entre sí.** Solo importan de `nucleo/`. Si una función parece necesaria en los dos flavors, va a `nucleo/`, no se duplica ni se importa cruzado.
8. **Evidencias comprimidas antes de subir** (objetivo <300 KB por imagen), en una cola de sincronización separada de los registros livianos — una sesión puede quedar `confirmada` con evidencia aún subiendo, pero la validación exige la evidencia ya subida.
9. **Dinero y hectáreas nunca en `double`/`float`.** Mismo problema que del lado servidor (que usa `DECIMAL`, nunca float): un cálculo mostrado en pantalla (litros, hectáreas, montos si algún día se muestran acá) usa un tipo decimal exacto, no `double`. No asumir que alcanza sin confirmar qué paquete Dart se adopta antes de introducir el primer cálculo.
10. **Prueba de replay obligatoria antes de la primera pantalla del esqueleto vertical**: aplicar el mismo lote de sincronización dos, tres, diez veces, en orden y en desorden parcial, tiene que dejar el estado final de la base idéntico. Se escribe antes que cualquier UI, no después.

## Convenciones

Heredadas de `agrocom-api` — ver ese `CLAUDE.md` para el detalle completo, acá solo lo que aplica directo a este repo:

- **Dominio en español, infraestructura en inglés**: mismo vocabulario que el backend (`Trabajo`, `Sesion`, `Mezcla`, `hectareas_declaradas`), pero `SyncEngine`, `Repository`, `Outbox`. No se traduce el dominio ni se reinventa un vocabulario propio del lado Flutter.
- **El nombre visible de la app es «Agrocom»**, nunca «Agrocom Field». `agrocom-field`/`agrocom_field` es el nombre del repo y del paquete Dart (imports, `applicationId`, base local) y no aparece en ningún texto que vea el usuario: el logo ya lleva el wordmark, y el flavor se distingue aparte (`Agrocom Piloto` / `Agrocom Auxiliar` como label del launcher).
- **Commits en español, imperativo**, sin trailer `Co-Authored-By` (`.claude/settings.json` ya lo declara).
- **GitFlow simplificado** (ADR 0006, "en ambos repositorios"): `master` + `develop` + `feature/*` + `fix/*`, todo por PR, auto-merge cuando el CI está en verde. Ver el skill `flujo-git-pr` de este repo.
- **Arquitectura**: BLoC feature-first en tres capas por feature (`presentation/`, `domain/`, `data/`), espejo de la arquitectura modular del backend (ADR 0003 de `agrocom-api`) — ver ADR 0005 para la estructura completa de carpetas.

## Qué no delegar sin revisión línea por línea

El motor de sync (outbox, replay, idempotencia por `uuid_cliente`) y el esquema de `drift` y sus migraciones locales — son el espejo cliente exacto de lo que `agrocom-api` ya marca como crítico (motor de sync, TE-05) y una migración de esquema local mal escrita pierde datos de campo capturados sin conectividad, sin forma de recuperarlos después.

Misma filosofía que `agrocom-api` (ver ese `CLAUDE.md`, "qué no delegar sin revisión"): la revisión es posterior a la integración, no previa — un PR crítico sin revisar todavía es un riesgo acotado y visible; una rama que no entra bloquea todo lo que viene detrás.
