# Visión del producto — `agrocom-field`

Este documento orienta a quien empieza a trabajar en este repo. Describe el producto, las dos superficies móviles y lo que cada una hace. Las reglas de trabajo están en `CLAUDE.md`; las decisiones de arquitectura, en `docs/decisiones/`; el contrato de API, en `docs/api/openapi.yaml` de `agrocom-api` (ruta local: `/Applications/MAMP/htdocs/agrocom-api`), con los estados, reglas y recursos de la negociación en `docs/especificacion/negociacion-contrato.md` de ese repo. Si este documento y el contrato no coinciden, manda el contrato.

## Qué es Agrocom

Agrocom es un **marketplace de servicio de fumigación con drones** donde el precio se negocia entre quien pide el servicio y quien lo hace. Un cliente publica una solicitud sobre su propiedad con un precio por hectárea; los pilotos la ven en un mapa y aceptan ese precio o proponen el suyo; el cliente compara las ofertas y elige. Los drones son los «vehículos».

- **Clientes**: dueños de campo o sus encargados. Publican, negocian, siguen y califican servicios.
- **Proveedores**: pilotos de Agrocom, pilotos independientes y dueños de drones. Compiten en igualdad.
- **Dos apps, dos tipos de cuenta.** El cliente usa la app `cliente` y el proveedor la app `piloto`; cada una admite un solo tipo de cuenta, con su propio usuario, verificación y aprobación. Cualquiera se registra y entra a su app, pero no publica, ofrece ni acepta hasta estar aprobado (ADR 0024). Un cliente que quiere ser proveedor se registra de nuevo en la app `piloto`; una misma persona tiene a lo sumo una cuenta de cada tipo.
- **Agrocom**: capta clientes, es el nexo entre ambos lados y el registro del estado y del resultado; además es proveedor propio. Lo operativo en el lote (cómo se trabaja, cuándo se vuela) lo acuerdan en persona el cliente y el piloto. La app no cobra: el pago se hace fuera de ella.

### Negociación

El cliente propone un precio por hectárea. El piloto, antes de ofertar, revisa el estado de la propiedad y de los lotes (lotes dibujados, cultivo, accesos, observaciones y fotos), y acepta el precio o contraoferta con el dron que usará. El cliente recibe varias ofertas, las compara por precio, calificación y dron (el orden recomendado pone primero a los proveedores propios de Agrocom y luego a los mejor calificados, y el cliente lo cambia), y acepta una, contraoferta o rechaza. La distancia no se calcula: se acuerda en la negociación. En cada negociación hay una sola oferta vigente y hay un máximo de ofertas; aceptar la oferta vigente de la contraparte adjudica la solicitud y cierra las demás. Todo lo decide y valida el servidor; la app muestra y envía.

## Las dos superficies móviles

Un solo código Flutter, dos flavors (ADR 0009, ADR 0021):

| Flavor | Quién lo usa | Qué hace | Conectividad |
|---|---|---|---|
| `cliente` | Dueño del campo o encargado | Registrarse y verificarse, marcar propiedad y lotes en el mapa, publicar una solicitud con su precio por hectárea, comparar y elegir ofertas, ver fotos de avance, chatear, ver la última ubicación del piloto, calificar | Online-first, sin outbox |
| `piloto` | Piloto o proveedor (control remoto del dron o celular) | Registrarse y verificarse con sus datos y los de su dron con fotos, ver el mapa de solicitudes abiertas, ofertar, ajustar sus avisos y su disponibilidad; ejecutar: marcar inicio, subir fotos, marcar avance, cerrar con las hectáreas ejecutadas | Negociación con red; ejecución offline en el lote |

Las superficies web (panel admin y motor del marketplace) viven en `agrocom-api`: verificación y aprobación de clientes y proveedores, aprobación de drones con sus fotos, moderación de calificaciones, reclamos y métricas.

### Qué es online y qué es offline

- **El lote no tiene señal.** Lo que sucede entre adjudicar y finalizar es offline-first: la UI lee de `drift`, toda escritura se inserta localmente y se encola en el outbox en una sola transacción, y cada registro nace con su `uuid_cliente`.
- **Negociar requiere red.** Ofertar, contraofertar, aceptar, rechazar y retirar van directo a la API, sin outbox; la adjudicación la confirma el servidor. Es una excepción documentada y revisable (ADR 0016).
- **El cliente siempre opera con red.** La app abre con la última lista conocida y avisa claramente cuando no hay conexión.

## El recorrido de un servicio

1. **Publicación.** El cliente marca su propiedad y sus lotes en el mapa, elige el departamento y la provincia, escribe el municipio y la comunidad, declara hectáreas (decimal exacto), cultivo, producto, fecha deseada (puede ser dentro de semanas o meses), accesos, observaciones, un requisito de dron si lo necesita y su precio por hectárea. La solicitud viaja con una clave de idempotencia generada en el dispositivo y queda `abierta`.
2. **Mapa de solicitudes.** El piloto ve las solicitudes abiertas que le corresponden en un mapa, con filtro por departamento, hectáreas, precio, fecha y cultivo; decide si quiere ir y la distancia se acuerda en la negociación. No hay zonas ni restricción geográfica. Si activó las notificaciones y no está «Ocupado» ni «En trabajo», recibe un aviso por oleadas: primero los propios de Agrocom y los mejor calificados que cumplen todos los filtros (del sistema, del cliente y los suyos), luego, anillo por anillo, más proveedores y al final todos los elegibles (la súper ola), sin avisar dos veces al mismo en un ciclo. Mientras no haya push el aviso se ve dentro de la app (campana y lista). Un proveedor aún no aprobado no ve el mapa: ve solo cuántas solicitudes abiertas hay.
3. **Oferta.** El piloto abre el detalle, acepta el precio o contraoferta. Esa es su **aceptación** y llega a la **bandeja** del cliente (el piloto ve «Tu oferta está en cola» o «El cliente la está viendo»); ofertar no oculta la solicitud a los demás pilotos, y abrir la pantalla de precios sin enviar nada no cambia nada. La negociación es asíncrona: cada quien responde cuando puede.
4. **Elección.** El cliente conversa con hasta 3 pilotos a la vez, compara las ofertas y negocia ronda por ronda hasta que una parte acepta la oferta de la otra. Las demás aceptaciones esperan en una cola que el cliente no ve y pasan a su bandeja, por prioridad, cuando rechaza o cierra una conversación. Cuando la conversación llega a un punto sólido, el cliente marca la solicitud «En acuerdo» y ya no se avisa a más pilotos. Si nadie acepta, queda «Esperando piloto» (al cliente solo se le avisa cuánto lleva sin respuesta): no se desactiva ni vence, y el cliente la relanza a mano o por el horario que eligió (mínimo 2 días por semana, a lo más uno por día) o la cancela. Un dron que no cumple lo pedido puede ofertar y se le marca al cliente. La solicitud queda `adjudicada` con su precio acordado; se abren los datos de contacto y el chat.
5. **Ejecución.** Las partes acuerdan en persona cómo trabajan. El piloto marca el inicio (`en_ejecucion`), sube fotos de su avance y marca el progreso (porcentaje u hectáreas). Todo se sincroniza cuando vuelve la señal; las fotos, comprimidas a menos de 300 KB, viajan en una cola aparte. El cliente ve las fotos, el avance, los mensajes y la última ubicación del piloto como un punto en el mapa.
6. **Cierre.** El piloto cierra con las hectáreas ejecutadas. El servidor calcula el precio final (hectáreas ejecutadas por precio acordado) y ambos lo ven como el monto a pagar. La solicitud queda `finalizada`.
7. **Calificación.** El cliente califica al proveedor en un registro propio y la solicitud pasa a `calificada`; el proveedor lo ve y un admin lo modera. El proveedor califica al cliente en otro registro, privado. Cualquiera puede abrir un reclamo dentro de su plazo.

Una solicitud sin adjudicar no vence sola: sigue hasta que se adjudica o el cliente la cancela. Cancelar antes de adjudicar no tiene consecuencia; después de adjudicar se registra quién cancela y se muestra en su tasa de cancelación, sin penalidad en dinero.

## Proveedores y drones

- El **proveedor independiente se registra solo**, con los datos de la persona (nombres, apellidos, documento, foto de perfil), su **teléfono** y su **correo de respaldo**, su licencia y los datos del dron (marca, modelo, año, serie, capacidad) con sus fotos; además se **verifica** con una selfie tomada con la cámara en el momento y un documento de identidad (carnet, licencia de conducir o pasaporte). Un admin lo aprueba antes de que vea el mapa y ofrezca. El **cliente se verifica igual** antes de publicar o aceptar ofertas.
- **Una persona, una cuenta de cada tipo, y el teléfono como referencia.** El teléfono es único por tipo de cuenta (el mismo teléfono puede estar en una cuenta de cliente y en una de proveedor) y la persona se identifica además por su documento; si ya tiene una cuenta de este tipo, la app le dice «Ya tienes una cuenta» y la lleva a iniciar sesión, donde le pide lo que le falte. Cada cuenta se verifica y se aprueba por separado y **no se reutiliza nada** de la otra: quien ya es cliente y se registra como proveedor sube de nuevo su selfie y su documento. **Límite:** un teléfono único no prueba que quien se registra sea su dueño; esa prueba será un código por SMS o WhatsApp cuando haya un proveedor, y hasta entonces la identidad la prueba la aprobación del administrador con selfie y documento.
- **Acceso desde la app.** Quien olvida su usuario o su contraseña los recupera desde la misma app con un código que llega a su correo de respaldo (no hay página web de restablecimiento); el teléfono se cambia con otro código a ese correo. Al registrarse se aceptan los términos y la privacidad vigentes.
- **Proveedor no aprobado:** no ve el mapa, los lotes, los clientes ni la ubicación; ve solo un contador de solicitudes abiertas («Hay N solicitudes abiertas que no puedes ver hasta que te aprueben»), que puede filtrar por departamento.
- **Pilotos de una empresa:** cada piloto tiene su cuenta propia vinculada a la empresa; el encargado de la empresa, con su cuenta, gestiona el vínculo y puede liberar al piloto para que trabaje por su cuenta con la misma cuenta. El cliente ve quién es el piloto solo después de adjudicar. En una empresa ofrece el encargado, que puede delegar la oferta a pilotos concretos (opción apagada por defecto; ADR 0023).
- **Empresas:** un cliente o proveedor puede cargar, opcionalmente, logo, NIT, razón social y nombre comercial.
- El **auxiliar no usa la app** (ADR 0021). El proveedor puede anotar, opcionalmente, nombre y celular de las personas de su equipo, solo como información, dentro del formulario del equipo; el cliente ve el equipo completo, con el piloto marcado, solo después de adjudicar.
- El **dron es el vehículo**: tiene matrícula, modelo, capacidad, fotos y estado, y pertenece a Agrocom o a un tercero. El cliente ve el modelo y las fotos aprobadas en cada oferta.
- Los **documentos del proveedor** (licencia de piloto, matrícula del dron, seguros) se suben desde su perfil y los revisa el admin.

## Arquitectura

- BLoC feature-first en tres capas (`presentation/`, `domain/`, `data/`) y un `nucleo/` compartido (ADR 0009).
- `cliente/` y `piloto/` no se importan entre sí; solo importan de `nucleo/`.
- Cliente HTTP manual sobre `dio` (ADR 0001); decimal exacto para hectáreas y dinero (ADR 0002); configuración de entorno por `--dart-define-from-file` (ADR 0004); versionado SemVer automatizado (ADR 0007).
- Tema claro derivado del logo para `cliente` (ADR 0003) y modo campo de alto contraste para `piloto` (ADR 0008).
- Sin selector de rol y sin rol en el token: el flavor fija el tipo de cuenta que admite la app y el login lo declara (ADR 0024, que reemplaza al ADR 0005 y concreta el ADR 0021).
- Negociación de ofertas (ADR 0016), seguimiento del servicio (ADR 0017) y mercado sin zonas con avisos por oleadas (ADR 0023).

### Sincronización del lote

1. Base local SQLite (`drift`); la UI del lote siempre lee de ahí.
2. Outbox `cola_sync` con estados `pendiente → enviado → confirmado | rechazado`.
3. `POST /api/sync` recibe un lote ordenado causalmente con los registros `inicio`, `avance`, `cierre`, `mensaje` e `incidencia`; el servidor procesa registro por registro y devuelve `aplicado`, `duplicado` o `rechazado` con motivo. Un rechazo no frena el resto.
4. La idempotencia vive en la base (`UNIQUE (uuid_cliente)`); un `duplicado` se trata como éxito.
5. Las referencias entre registros usan `uuid_cliente`, nunca ids del servidor, mientras están offline.
6. El catálogo de servicios adjudicados y en ejecución se baja con cursor (`GET /api/sync/catalogo`).
7. Las fotos viajan en una cola separada; el servicio puede cerrarse con fotos aún subiendo, pero pasa a `finalizada` cuando el servidor las tiene.
8. El orden es por `secuencia` local, nunca por reloj de dispositivo.
9. Cada tipo de registro tiene un solo rol escritor, así que no hay lógica de merge.

La prueba de replay (el mismo lote aplicado varias veces, en orden y en desorden parcial, deja la base idéntica) corre en CI.

## Contrato de API

El contrato completo está en `docs/api/openapi.yaml` de `agrocom-api`, generado code-first; nunca se edita desde este repo. Los grupos funcionales que la app consume:

| Grupo | Quién lo usa | Conectividad |
|---|---|---|
| Autenticación sin rol (`POST /api/auth/token` con la app de origen, `GET /api/auth/sesion`, que devuelven cuenta, persona y verificación), registro de cliente y de proveedor con persona única y verificación de identidad (selfie y documento) | Los dos flavors | Con red, sin outbox |
| Terrenos, solicitud (publicar, precio, ajustes, relanzar, cancelar), comparador de ofertas, avance, ubicación del piloto, calificación | `cliente` | Con red |
| Mapa de solicitudes abiertas, detalle, ofertar, contraofertar, aceptar, rechazar, retirar | `piloto` | Con red, sin outbox |
| Mensajes de la solicitud | `cliente`, `piloto` | Cliente con red; piloto por outbox |
| Perfil, documentos, drones y fotos del dron | `piloto` | Con red |
| Preferencias de notificación y token de push | `cliente`, `piloto` | Con red |
| Ubicación del piloto (`PUT /api/ubicacion`) | `piloto` | Con red, sin outbox; se omite sin señal |
| Catálogo de servicios adjudicados (`GET /api/sync/catalogo`) | `piloto` | Pull con cursor |
| Registros del lote (`POST /api/sync`) y fotos (`POST /api/evidencias`) | `piloto` | Offline, outbox |

## Publicación en las tiendas y privacidad

Lo que Google Play y la App Store exigen sobre privacidad, eliminación de cuenta, permisos, contenido de usuarios, edad y cuentas para los revisores, el mapa de datos que las apps recogen y el panorama de protección de datos en Latinoamérica están en `docs/politicas/tiendas-y-privacidad.md` de `agrocom-api` (`/Applications/MAMP/htdocs/agrocom-api`), que es la fuente de verdad, con la decisión en el ADR 0047 de ese repo y el de las apps en el ADR 0025 de este. No es asesoría legal. El dueño decidió ajustarse a lo que las tiendas exigen. Lo que toca a las apps:

- **«Eliminar mi cuenta»** dentro de cada app (Perfil, Privacidad y datos): contraseña y código al correo de respaldo, 7 días para arrepentirse, anonimización de los datos personales en el servidor y una página web para quien no puede entrar. Se conservan, declarados, la selfie y el documento 90 días (12 meses con antecedentes), un registro mínimo antifraude y los servicios y calificaciones sin datos identificables.
- **Reportar y bloquear en el chat.** Reportar un mensaje, la conversación o una foto abre un reclamo de conducta que soporte atiende leyendo solo lo reportado; bloquear cierra el chat y la negociación y oculta las solicitudes del otro, sin romper un servicio adjudicado.
- **Ubicación de emergencia.** El botón de auxilio y las incidencias adjuntan una posición que el servidor guarda 90 días tras cerrar el caso; en el piloto es la del dispositivo y en el cliente la del terreno del servicio (la app del cliente no declara permisos de ubicación).
- Textos de propósito de cámara, fotos, ubicación y notificaciones por flavor, con una explicación previa dentro de la app, y permisos de Android por flavor (el cliente no usa ubicación); el detalle está en [seguridad/permisos.md](seguridad/permisos.md).
- Enlaces a los términos y la privacidad en el registro y en los ajustes, contacto de soporte visible y declaración de mayoría de edad (18 años).
- Manifiesto de privacidad de iOS, teselas del mapa y push, que son terceros que hay que declarar. Sign in with Apple no aplica.
- Declaraciones de Data safety y App Privacy para cada app.
- Antes de enviar: dominio, HTTPS y las páginas públicas `/terminos`, `/privacidad` y `/eliminar-cuenta`, trabajo de infraestructura del dueño con su lista de verificación en «Antes de publicar en las tiendas».

## Qué no hace la app

- No procesa cobros ni calcula comisión: el precio final se muestra y el pago ocurre fuera de ella.
- No gestiona contratos ni campañas: todo es solicitud por solicitud.
- No administra mantenimiento, inventario, planilla ni contabilidad.
- No decide la negociación ni la moderación; las valida el servidor y el panel admin.
- No dirige la operación en el lote: sesión de vuelo, mezcla y condiciones las acuerdan las partes en persona.
- No muestra ruta ni tiempo estimado de llegada del piloto: solo su última ubicación.
- No sincroniza nada del flavor `cliente` por outbox.

**Modelo de negocio, sin decidir.** Cómo lucra Agrocom (una suscripción de acceso a la plataforma, un periodo de gratuidad previo y qué permiten las tiendas) está en exploración en el ADR 0048 de `agrocom-api` (`docs/decisiones/0048-modelo-de-negocio-suscripcion-y-periodo-de-gratuidad.md`). Mientras no se decida, las apps no muestran precios, enlaces de pago ni compras; lo que no se cobra en la app es el servicio, y una suscripción de acceso sería otra cosa.

## Decisiones por defecto, revisables

| Decisión | Motivo |
|---|---|
| El panel web admin vive dentro de `agrocom-api` | Un solo despliegue y un solo modelo de datos |
| Negociar requiere red | La adjudicación es un acuerdo entre dos partes que el servidor resuelve; el lote sigue offline |
| El cliente elige entre las ofertas; no hay adjudicación automática | El cliente decide con precio, calificación y dron; el orden recomendado (propios primero, luego calificación) solo sugiere |
| Los avisos de nuevas solicitudes salen por oleadas desde el servidor y la app no los calcula | Prioridad por tiempo para los propios y los mejor calificados sin avisar dos veces; ADR 0023 |
| La solicitud no vence sola; si nadie acepta queda «Esperando piloto» y el cliente la relanza o la cancela | Un trato puede tardar semanas; el cliente decide cuándo cancelar; ADR 0023 |
| Sin push por ahora: los avisos se ven dentro de la app (campana y lista) | El push (Firebase o Supabase) se implementa después; el modelo de oleadas no cambia; ADR 0023 |
| Sin zonas, sin distancia y sin precio de referencia | El mercado es abierto; los precios los ponen el cliente y el proveedor |
| El piloto ve lotes y fotos antes de ofertar, y el contacto solo tras adjudicar | Decide su precio con información sin exponer al cliente |
| La calificación la escribe el cliente en un registro propio; el proveedor solo la ve; el admin modera | Un solo rol escritor por registro |
| Sin cobro ni comisión calculada en la app | Reduce superficie y riesgo; el modelo de ingresos es del negocio |
| La ubicación del piloto es solo la última posición durante la ejecución; la única otra que se guarda es la de una emergencia o incidencia, 90 días tras cerrarla | Privacidad: sin historial ni ruta, y lo que se guarda por seguridad está declarado |
| El cliente y el proveedor se registran solos, se verifican (selfie con cámara y documento) y el admin aprueba cada cuenta | Se entra y se ve la app sin frenar el alta, pero no se negocia con terrenos, dinero y drones ajenos sin saber que la persona existe |
| Una cuenta por app y una persona con a lo sumo una cuenta de cada tipo | Son dos apps; evita cuentas repetidas de la misma persona y que la persona se contrate a sí misma sin verlo |
| El auxiliar no es usuario de la app (ADR 0021) | No hay trabajo propio que justifique una app ni un selector de rol |
| El mapa usa `flutter_map` con teselas abiertas de OpenStreetMap solo mientras dura la beta; para publicar, el dueño decide el proveedor de teselas (ADR 0025, punto 19) | Evita gestionar una clave de mapas en la primera versión; las teselas públicas no son base para una app publicada |
