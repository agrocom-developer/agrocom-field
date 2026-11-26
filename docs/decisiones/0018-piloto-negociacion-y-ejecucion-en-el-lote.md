# ADR 0018 — El piloto: negociación en línea y ejecución en el lote

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Desarrolla el ADR 0016 para los flavors `piloto` y `auxiliar`.

## Contexto

El piloto decide dónde ofertar mirando un mapa, negocia el precio por hectárea con el cliente y, una vez adjudicado el servicio, trabaja en un lote sin señal. Son dos mundos: lo que se negocia exige red porque lo deciden dos partes; lo que se ejecuta tiene que funcionar sin ella.

## Decisión

### Negociación: llamadas directas, sin outbox

`lib/nucleo/marketplace/proveedor/negociacion/` (con `domain/`, `data/` y `presentation/`) concentra el mapa de solicitudes abiertas, el detalle previo a ofertar, la primera oferta, mis ofertas, el chat y los avisos.

- **Mapa.** `flutter_map` con un marcador por solicitud (lleva el precio por hectárea escrito) y filtros por macrorregión, hectáreas, precio, cultivo y orden. Valles y Chiquitania van primero entre las zonas. El resumen por zona responde cuántas solicitudes y hectáreas hay en cada una.
- **Oferta.** Aceptar el precio propuesto o contraofertar el propio. La clave `uuid_cliente` nace en el dispositivo al primer intento y se conserva si la respuesta se pierde: reenviar devuelve la misma oferta. Una respuesta del servidor cierra el intento y el siguiente nace con otra clave.
- **Mis ofertas.** Ordenadas por quién tiene el turno. La app habilita solo lo que cada oferta permite (`autor`, `estado`, `es_definitiva`) y traduce `oferta_no_vigente`, `solicitud_ya_adjudicada` y `equipo_no_disponible` a un texto que dice qué pasó; después recarga.
- **Chat.** Texto de hasta 1000 caracteres con `uuid_cliente` por mensaje. Se actualiza cada 8 segundos mientras la pantalla está abierta, sin servicio en segundo plano.
- **Avisos.** El interruptor de nuevas solicitudes (con zonas y hectáreas mínimas) se guarda en el servidor. Al abrir o refrescar el mapa, `AvisadorSolicitudesNuevas` consulta el mercado completo y muestra una notificación local por lo nuevo que encaja con las preferencias. La primera consulta solo registra lo que ya hay. El permiso de notificaciones se pide al activar el interruptor.

### Ejecución: offline-first sobre `drift`

El esquema pasa a la versión 15 con tres tablas nuevas, solo con `CREATE TABLE` (ninguna fila existente se toca):

| Tabla | Qué es |
|---|---|
| `servicio_adjudicado` | Espejo de `servicios_asignados` de `GET /api/sync/catalogo`: la solicitud con sus lotes, el precio acordado y el contacto del cliente. Es lo que lee la UI. |
| `registro_ejecucion` | Outbox liviano de `inicio`, `avance` y `cierre`, con `uuid_cliente` y `secuencia` locales. |
| `foto_ejecucion` | Cola de fotos de avance, separada de la anterior (invariante 7). El archivo vive en disco, comprimido a menos de 300 KB. |

`EjecucionLocal` escribe cada acción como inserción local más actualización del espejo, en una sola transacción. `EjecucionSyncEngine` sube, por este orden y uno por uno: los registros por `secuencia`, las fotos y, al final, baja el catálogo. Un corte de red o un error del servidor detiene el ciclo sin romper el orden; un rechazo definitivo (`403`, `404`, `409`, `422`) marca esa fila `rechazado` con su motivo y el ciclo sigue. Reenviar es idempotente: el servidor responde `200` con lo ya registrado y `200` y `201` valen lo mismo. Un pull no pisa el estado ni el avance de una solicitud con registros pendientes.

Se creó una cola propia y no se usó `cola_sync` porque esos registros no viajan en lote a `POST /api/sync`: cada uno va a un endpoint de la solicitud (`/inicio`, `/avance`, `/cierre`, `/evidencias`). `SyncEngine` y `OutboxRepository` no se tocaron.

Un servicio finalizado sigue visible con su precio: estimado (hectáreas ejecutadas por precio acordado) hasta que el servidor devuelve `monto_final`, que es el que manda. Al cerrar sesión se descarta lo ya subido y lo que el siguiente usuario no debe ver; lo pendiente de subir se conserva.

### Ubicación del piloto

Solo mientras la pantalla de un servicio en ejecución está abierta, cada 30 segundos, con `PUT /api/ubicacion`. No pasa por el outbox: sin red se omite. El permiso se explica antes de pedirlo («Dile al cliente dónde estás») y el piloto lo acepta con un botón; si ya estaba concedido, empieza solo. Deja de publicar al cerrar la pantalla o al finalizar. No hay seguimiento en segundo plano, no se guarda el recorrido y el auxiliar no comparte ubicación. Dependencia nueva: `geolocator`, por ser el paquete mantenido que cubre los permisos de Android e iOS.

### Acceso y registro

Inicio de sesión por usuario y contraseña (`POST /api/auth/token`, nunca correo). El login no lleva rol: declara la app `piloto` y solo entran cuentas de proveedor; una cuenta de cliente recibe `tipo_de_cuenta_incorrecto` (ADR 0024). El token vive solo en almacenamiento seguro y un `401` devuelve al ingreso.

El alta del piloto independiente tiene cuatro pasos: datos de la persona, licencia, dron y fotos del dron (frontal, lateral y placa de serie, desde la cámara o la galería). Cada foto se comprime a menos de 300 KB con una escalera de calidad y lado; si ninguna pasada alcanza, no se sube. El envío hace cuenta → sesión → dron → fotos y, si falla a medias, reintentar retoma desde el paso que faltó sin crear nada dos veces. Termina en «en revisión»: sin aprobación de un administrador no se ve el mapa. El alta incluye además la verificación de identidad de la persona (selfie con cámara y documento, ADR 0024).

### Qué se quitó

La bandeja de ofertas con cuenta regresiva, el servicio asignado de la sesión de vuelo y la mezcla del auxiliar ya no existen en `piloto` ni `auxiliar`: lo operativo en el lote se acuerda en persona y la app solo sube fotos, marca el avance y muestra el precio.

## Consecuencias

- El esquema `drift` y el motor de subida son críticos: se anotan en `runs/revision-pendiente.txt` para la revisión línea por línea. La migración v14 → v15 se prueba con datos (`test/nucleo/db/migracion_ejecucion_test.dart`) y la subida con la prueba de replay (`test/nucleo/marketplace/proveedor/ejecucion/ejecucion_local_test.dart`).
- El perfil de una cuenta que es piloto de un tercero (cuenta de proveedor con `rol_en_proveedor: piloto`, sin proveedor propio) muestra a la persona y su reputación, sin drones: `proveedores/mi` le responde `403`.
- Pendiente de contrato: la vida útil de la batería por dron (la app usa un valor fijo para dibujar el desgaste) y las hectáreas por mes del perfil.
- Pendiente de producto: agregar un dron después del alta y registrar al auxiliar desde la app.
