# ADR 0017 — Seguimiento del servicio: avance, fotos, mensajes y ubicación

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: ADR 0040 de `agrocom-api`.

## Contexto

Tras adjudicar, cliente y piloto se ven en el lote y acuerdan cómo trabajar; eso queda fuera de la app. El piloto solo sube fotos de su avance y marca su progreso; el cliente ve las fotos, conversa y ve la última ubicación del piloto. Al final aparece el precio a pagar. El lote no tiene señal, y la ubicación y el contacto son datos personales.

## Decisión

### Lo que escribe el piloto en el lote (offline-first)

Registros con `uuid_cliente`, `secuencia` local y outbox, en una sola transacción con el insert local:

| Registro | Contenido | Efecto en el servidor |
|---|---|---|
| `inicio` | `solicitud_id` | `adjudicada` pasa a `en_ejecucion` |
| `avance` | hectáreas acumuladas o porcentaje, nota; `motivo_correccion` si baja | El cliente ve el avance |
| `cierre` | hectáreas ejecutadas | Con las fotos mínimas subidas, la solicitud pasa a `finalizada` y se congela el precio final |
| `mensaje` | texto | Entra al chat al recuperar red |

La UI del lote lee de `drift`. Una corrección es un registro nuevo con motivo; lo confirmado no se reescribe. El orden es por `secuencia`, nunca por reloj. Estos registros entran en la prueba de replay.

### Fotos de avance

El piloto y el auxiliar fotografían el avance; la foto se comprime a menos de 300 KB antes de subir y viaja en la cola de evidencias, separada de los registros livianos. Se puede cerrar con fotos aún subiendo; el servicio queda «cierre pendiente» hasta que el servidor las confirma, y la pantalla lo dice.

### Mensajes

Chat de texto entre el cliente y el piloto adjudicado. El cliente escribe en línea. El piloto escribe por el outbox y ve «enviado al recuperar red» hasta la confirmación. La lectura es por cursor con consulta periódica corta (cada 5 segundos con el chat abierto) y aviso push; el transporte puede pasar a un canal en tiempo real sin cambiar los repositorios.

### Ubicación del piloto

La app `piloto` envía su posición a `PUT /ubicacion` cada 30 segundos mientras la solicitud está `en_ejecucion` y la app está abierta en el servicio; no pasa por el outbox y, sin red, se omite. El piloto puede desactivarla desde la pantalla del servicio. El permiso de ubicación se pide solo al iniciar un servicio, explicando que el cliente verá su última posición mientras dure. Al finalizar la app deja de enviar. El cliente ve un punto en el mapa que se refresca con la antigüedad («hace 2 min»); si es vieja o falta, dice «sin ubicación reciente». No hay ruta ni tiempo estimado. La ubicación nunca se guarda en `drift`, logs ni reportes de error.

### Precio final

Al finalizar, ambas apps muestran el precio final que calcula el servidor: hectáreas ejecutadas por precio acordado. El texto dice que el pago se hace fuera de la app. El proveedor puede marcar que lo recibió.

### Calificación y reclamo

El cliente califica al proveedor en un registro propio durante 7 días desde `finalizada`; el proveedor califica al cliente en otro, privado. Cualquiera abre un reclamo dentro de su plazo.

## Alternativas descartadas

- **Registrar sesión de vuelo, mezcla y condiciones en la app**: es operación que las partes acuerdan en persona; la app no las exige para cerrar.
- **Guardar el historial de posiciones**: dato personal sin uso.
- **Enviar la ubicación por el outbox**: una posición vieja entregada tarde engaña al cliente.

## Consecuencias

- `nucleo/sync` suma los tipos `inicio`, `avance`, `cierre` y `mensaje`; el replay los cubre.
- El flavor `auxiliar` queda con el servicio adjudicado y las fotos de avance.
- Los registros operativos detallados del lote que la app capturaba dejan de ser requisito para cerrar; el servidor los sigue aceptando mientras existan en dispositivos.

## Revisión (27/11/2026) — reportar y bloquear en el chat, y ubicación de emergencia

El dueño decidió ajustarse a lo que exigen las tiendas (ADR 0025 de este repo; ADR 0047 de `agrocom-api`). Cambia respecto de la primera versión de este ADR:

1. **Chat.** Cada mensaje, la conversación y cada foto de avance se pueden **reportar** (motivo, detalle opcional y aviso de que soporte podrá leer lo reportado) y el chat permite **bloquear** a la otra parte; ambas son llamadas en línea, sin outbox. Bloquear cierra el chat de esa solicitud (solo lectura) y no rompe un servicio adjudicado. Soporte lee solo lo reportado, no el chat completo.
2. **Ubicación.** La regla pasa a su formulación exacta: la ubicación del piloto durante la ejecución se guarda solo como última posición en el servidor y se elimina al finalizar; la única otra ubicación es la de una emergencia o incidencia, que la persona adjunta al pulsar el SOS o reportar, y viaja dentro del registro de la incidencia hasta sincronizarse. Motivo: el servidor ya guardaba esa posición y la regla absoluta lo contradecía.
3. **Fotos.** Las fotos de avance se comprimen sin metadatos de ubicación.
