# Solicitud de API: bandeja de notificaciones con mensajes entre personas

La bandeja de la app (cliente y piloto) muestra avisos del sistema y mensajes
entre cliente y piloto. El contrato actual (`GET /api/notificaciones`,
`POST /api/notificaciones/{id}/leida`) cubre solo los **avisos del sistema**:
título ya armado, `recurso_tipo` y `recurso_id`, sin cuerpo ni remitente.

## Qué hace hoy la app

- **Real (`BandejaRed`):** lista los avisos del contrato, todos como «sistema»,
  y marca cada uno como leído al abrirlo. «Marcar todas como leídas» llama
  una vez a `POST …/leida` por cada aviso no leído, porque no existe un
  endpoint masivo.
- **Demo (`BandejaDemo`):** además trae mensajes de persona a persona para
  ver el diseño completo.

## Lo que falta en `agrocom-api`

1. Un campo `cuerpo` (texto corto) en cada aviso, para el segundo renglón.
2. Un `origen` por aviso: `sistema` o `persona` con `nombre` del remitente,
   para los mensajes del chat de un servicio (hoy viven solo en el chat de
   cada solicitud).
3. `POST /api/notificaciones/leidas` para marcar todas en una llamada.
4. Paginación (`?antes=<id>`), porque hoy la lista corta en 50.
