# CLAUDE.md — reglas de `agrocom-field`

Este repo es la app móvil de Agrocom: **Flutter, una sola base de código con tres flavors** — `cliente`, `piloto` y `auxiliar`. Agrocom es un marketplace de servicio de fumigación con drones donde el precio se negocia: el cliente publica una solicitud con un precio por hectárea, los proveedores (pilotos propios de Agrocom, pilotos independientes y dueños de drones, con sus auxiliares) aceptan o contraofertan, el cliente elige, y los drones son los «vehículos». Agrocom es el nexo y el registro del estado y del resultado; lo operativo en el lote lo acuerdan en persona las partes. Es el hermano de `agrocom-api` (motor del marketplace y web admin, Laravel) — mismo dueño, mismos agentes de IA como implementadores principales.

**La fuente de verdad del contrato no vive en este repo.** Vive en `agrocom-api`, clonado en esta misma máquina en `/Applications/MAMP/htdocs/agrocom-api`: `docs/api/openapi.yaml` es el contrato de API que este repo consume (se regenera allá; acá nunca se edita a mano). `docs/vision.md` de este repo da el panorama completo del producto. Si la ruta del otro repo cambia, se actualiza acá y en `docs/vision.md`.

## Política de marketplace vista desde la app

- **Tres flavors, tres roles de uso.** `cliente` (celular del dueño del campo o su encargado), `piloto` (control remoto Android del dron, también celular) y `auxiliar` (celular del ayudante en el lote). Un proveedor independiente o dueño de dron usa el flavor `piloto` o `auxiliar` según lo que haga ese día; el rol activo lo fija el flavor (ADR 0005) y el login.
- **Qué es online-first y qué es offline.** El flavor `cliente` es **online-first**: publica, negocia, sigue y califica servicios contra la red; no tiene outbox. Lo que el piloto registra en el lote — inicio, avance, cierre, mensajes y fotos de avance — es **offline-first** en `piloto` y `auxiliar`, porque el lote no tiene señal.
- **Excepción documentada: negociar requiere red.** Publicar, ofertar, contraofertar, aceptar, rechazar y retirar una oferta son llamadas en línea con confirmación del servidor; la adjudicación es un acuerdo entre dos partes que se resuelve de forma atómica y no pasa por el outbox (ADR 0016). Todo lo posterior a la adjudicación se baja a `drift` y se ejecuta sin red.
- **Negociación.** El cliente propone un precio por hectárea; el piloto lo acepta o contraoferta con su dron; el cliente elige, acepta, contraoferta o rechaza, por rondas con una sola oferta vigente por negociación. Aceptar la oferta vigente de la contraparte adjudica la solicitud. Estados: `borrador`, `abierta`, `con_ofertas`, `adjudicada`, `en_ejecucion`, `finalizada`, `calificada`, más `cancelada`, `expirada` y `disputada`. La decide y la valida el servidor: la app muestra las ofertas y envía la respuesta, y no replica reglas de rondas, vigencias ni turnos. No hay asignación automática ni prioridad de proveedores propios.
- **Qué hace el piloto.** Ve el mapa de solicitudes abiertas, ofrece, marca el inicio, sube fotos de avance, marca el progreso, cierra con las hectáreas ejecutadas y puede activar o desactivar las notificaciones de nuevas solicitudes por zona. El cliente ve las fotos, el avance, el chat y la última ubicación del piloto durante la ejecución.
- **Calificación.** La escribe el cliente en un registro propio; el proveedor solo la ve y un admin la modera. El proveedor califica al cliente con un registro propio del proveedor. Nunca dos roles editan la misma fila.
- **Alta de proveedores.** El proveedor independiente se registra solo, con los datos de la persona y del dron con sus fotos, y un admin lo aprueba antes de operar; el piloto registra a su auxiliar y el admin lo aprueba. Mientras no esté aprobado, la app no muestra el mapa de solicitudes ni permite ofertar.
- **Sin cobro en la app.** No se procesan pagos ni se calcula comisión. Al finalizar se muestra el precio final que calcula el servidor (hectáreas ejecutadas por precio acordado) como monto a pagar fuera de la app. Todo es solicitud por solicitud: no hay contratos ni campañas.

## Invariantes físicas (flavors `piloto` y `auxiliar`)

Responden al hecho de que el lote no tiene señal; no aplican al flavor `cliente`.

1. **La UI del lote lee de `drift`, nunca de la red.** Un bloc que llama a la API en vez de leer un `Stream` del repositorio local es un bug de arquitectura.
2. **Todo registro del lote nace con su `uuid_cliente` en el dispositivo**, antes de tocar la red; no se genera en el servidor ni se reutiliza entre reintentos. Eso hace la sincronización idempotente (`UNIQUE (uuid_cliente)`).
3. **Escribir = insertar local + encolar en outbox, en una sola transacción.** Ningún bloc espera al servidor para confirmar una acción del lote.
4. **Un solo rol escritor por tipo de registro.** El avance y el cierre los escribe el piloto, cada mensaje su autor, cada foto quien la sube. Si dos roles necesitaran editar lo mismo, se divide en dos registros; no hay lógica de merge.
5. **Orden causal por `secuencia` local, nunca por reloj de dispositivo.**
6. **Lo ya confirmado por el servidor no se reescribe.** Una corrección es un registro nuevo con motivo y autor.
7. **Evidencias comprimidas a menos de 300 KB** antes de subir, en una cola separada de los registros livianos. El cierre exige las fotos mínimas de avance ya subidas para finalizar el servicio.
8. **Dinero y hectáreas nunca en `double`.** Se usa el tipo decimal exacto del paquete `decimal` (ADR 0002) en cálculo, almacenamiento y presentación.
9. **Prueba de replay obligatoria.** Aplicar el mismo lote de sincronización dos, tres o diez veces, en orden y en desorden parcial, deja la base idéntica. La prueba corre en CI y ningún cambio de `nucleo/sync` o `nucleo/db` la desactiva.

## Reglas de importación y arquitectura

- BLoC feature-first en tres capas por feature: `presentation/`, `domain/`, `data/` (ADR 0009).
- `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; solo importan de `nucleo/`. Lo que dos flavors necesitan va a `nucleo/`.
- **Dominio en español, infraestructura en inglés**: `Servicio`, `Oferta`, `Proveedor`, `Dron`, `Calificacion`, pero `SyncEngine`, `Repository`, `Outbox`.
- El nombre visible de la app es «Agrocom», nunca «Agrocom Field». `agrocom_field` es el nombre del paquete Dart y no aparece en texto visible; el flavor se distingue solo en el label del launcher (`Agrocom`, `Agrocom Piloto`, `Agrocom Auxiliar`).

## Política de calidad de UI

La guía de diseño vigente es [`DESIGN.md`](DESIGN.md) (identidad Industrial AgTech); se consulta antes de cualquier cambio de UI y se actualiza después. Tokens, especificación de pantallas, capturas y prototipo están en `docs/diseno/`.

La interfaz es parte del producto, no un acabado. Una pantalla no está terminada hasta que cumple todo esto:

- **Dos lenguajes visuales, un sistema de tokens.** `piloto` y `auxiliar` usan el modo campo de alto contraste (ADR 0008): legible a pleno sol, objetivos táctiles de 56 dp o más, acciones con guantes. `cliente` usa un tema claro sobrio derivado del logo (ADR 0003): fondo neutro, un solo color de acento, jerarquía por tamaño y peso, no por decoración. Los colores, tipografías (Manrope, JetBrains Mono), espacios y radios viven en `nucleo/ui` como tokens; una pantalla no declara colores ni medidas propias.
- **Sin sobrecarga.** Una acción principal por pantalla, máximo tres niveles de jerarquía, espacio generoso, nada de ornamento sin función. Si algo no ayuda a decidir o actuar, se quita.
- **Contraste y accesibilidad.** Contraste AA como mínimo (AAA en modo campo), texto escalable hasta 200 % sin romper el layout, etiquetas semánticas en todo control, no depender solo del color para comunicar estado.
- **Todos los estados.** Cada pantalla define carga, vacío, error, sin red y éxito, con texto en español y una salida clara. Los estados vacíos orientan; los errores dicen qué hacer.
- **Movimiento con intención.** Transiciones cortas (150 a 250 ms) que expliquen un cambio de estado; respetan «reducir movimiento» del sistema.
- **Verificación.** Cada pantalla tiene pruebas golden en claro y oscuro (según el flavor), con la fuente real, a ancho de teléfono pequeño y grande. Un cambio de UI sin golden actualizado y revisado no se integra. Antes de abrir el PR de una pantalla se mira corriendo en el emulador de Android o el simulador de iOS.
- **Textos.** Español con ortografía correcta y acentos; tono directo, sin jerga técnica hacia el cliente.

## Política de seguridad

- **Secretos.** Ninguna credencial, token, keystore, `key.properties`, `.env` ni clave de API entra al repo ni a un prompt. Los hooks guardarraíl lo bloquean; no se esquivan. La configuración de entorno entra por `--dart-define-from-file` (ADR 0004) con archivos locales fuera de git.
- **Tokens y sesión.** El token del dispositivo vive solo en almacenamiento seguro (Keychain/Keystore). Nunca en `shared_preferences`, logs, reportes de error ni capturas. Cerrar sesión lo borra y revoca el dispositivo en el servidor.
- **Certificados y transporte.** Solo HTTPS en `staging` y `produccion`; sin excepciones de certificado en código de release. El texto plano queda restringido al entorno local de desarrollo.
- **Privacidad de ubicación.** La ubicación del lote y del piloto se pide solo cuando una función la necesita, con el motivo explicado antes del permiso. La app del piloto comparte su última posición con el cliente solo durante `en_ejecucion`, el piloto puede desactivarla y deja de enviarla al finalizar. Ninguna ubicación se guarda en `drift`, logs, reportes de error ni analíticas.
- **Datos del cliente.** Antes de ofertar, el piloto ve los lotes dibujados, las hectáreas, el cultivo, los accesos, las observaciones y las fotos del terreno, para decidir su precio. Nombre, teléfono, documento y dirección del cliente se muestran al proveedor solo después de adjudicar, y el teléfono del piloto al cliente. Un proveedor nunca ve datos de clientes que no le fueron adjudicados ni las ofertas de otros proveedores. Los documentos del proveedor (licencias, matrículas) se suben por HTTPS y no se cachean en claro fuera del almacenamiento privado de la app.
- **Datos en el dispositivo.** La base `drift` guarda solo lo que el rol necesita para operar sin red; al cerrar sesión se descarta lo que el próximo usuario no debe ver, salvo lo pendiente de sincronizar.
- **Dependencias.** Se agrega una dependencia solo con motivo escrito en el PR; se prefieren paquetes mantenidos y con licencia compatible.

## Política de entrega

- **GitFlow simplificado:** `master` + `develop` + `feature/*` + `fix/*`. Todo cambio entra por PR contra `develop`; nunca se edita, commitea ni empuja directo a `master`, `main` ni `develop`. Antes de tocar un archivo se verifica la rama; si es protegida se crea una rama desde `origin/develop`. Ver el skill `flujo-git-pr`.
- **Commits en español, imperativo, sin punto final**, sin trailer `Co-Authored-By`. Varios commits por PR; los borrados van en commits separados y descritos.
- **CI.** `flutter-tests` verde es la condición de integración; `auto-merge` mergea con squash cuando queda verde. «Sin checks» se trata como fallo. La compuerta local es `./bin/verify` (formato, análisis, codegen limpio, pruebas) y corre antes de cada commit de código.
- **Agentes en segundo plano.** El trabajo lo toma la cola (`docs/gestion/cola_tareas.md`) mediante `bin/ciclo`: cada tarea tiene su prompt en `prompts/`, su rama y su criterio de aceptación ejecutable. Una tarea sin criterio que un comando pueda evaluar la revisa una persona, no el ciclo. Los hooks del turno de noche congelan rutas por zona; si bloquean, la tarea declara `descongela=` o se detiene — no se esquivan.
- **Ciclos.** Una tarea es un PR. El ciclo implementa, verifica (independiente, en las críticas), abre el PR, espera el CI y planifica la siguiente. Una tarea trabada se marca y la cola sigue; varias seguidas sin integrar detienen el ciclo.
- **Documentación en presente.** Los documentos describen el sistema vigente. Lo que deja de ser verdad se elimina o se reescribe; el historial vive en git. Una decisión revisable se documenta como tal, con su motivo.

## Verificación y CI por impacto

- **`bin/verify` corre solo lo afectado** por el diff contra `origin/develop` (formato y análisis de los `.dart` tocados, pruebas afectadas y humo mínimo). `bin/verify --todo` corre todo. Nadie, ni persona ni agente, corre la suite entera por defecto.
- El selector (`bin/tests-afectados`, código en `tool/selector/`) falla hacia más pruebas: si el diff toca lockfiles, `config/`, `lib/nucleo/db`, `lib/nucleo/sync`, `.github/`, `bin/`, `tool/`, fixtures o helpers de prueba, o algo que no sabe clasificar, corre todo.
- En CI, un PR a `develop` corre lo afectado; la suite completa en shards corre en el PR a `master` (release), con la etiqueta `full-ci`, por `workflow_dispatch` y de noche sobre `develop`. El check requerido sigue siendo `flutter-tests`.
- El humo mínimo (replay del sync, contrato de API, reglas de importación, el selector) corre siempre. Detalle en `docs/gestion/ci-por-impacto.md` y en el skill `verificacion`.

## Qué no delegar sin revisión línea por línea

- El **motor de sync** (outbox, replay, idempotencia por `uuid_cliente`), el **esquema de `drift` y sus migraciones**, y todo lo que toque el **almacenamiento de tokens, permisos de ubicación y datos del cliente**. Una migración mal escrita pierde datos de campo capturados sin señal, sin forma de recuperarlos.
- La **excepción de negociación con red**: es el único punto donde una acción del proveedor no pasa por el outbox, y su manejo de errores, de vigencia y de conflicto define si dos partes creen haber acordado precios distintos o dos proveedores creen haber sido adjudicados.
- La **ubicación del piloto y los datos de contacto**: su envío, su eliminación al finalizar y el momento en que se muestran.

La revisión es posterior a la integración, no previa: un PR crítico sin revisar es un riesgo acotado y visible; una rama que no entra bloquea todo lo que viene detrás. Los PR críticos quedan anotados para la revisión del dueño sobre `develop`.
