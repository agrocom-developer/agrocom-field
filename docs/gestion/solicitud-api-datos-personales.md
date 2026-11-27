# Solicitud de API: edición única de datos personales y solicitud de cambio

Destino: `agrocom-api` (el contrato `docs/api/openapi.yaml` no se edita desde este repo).
Estado: propuesta. La app ya tiene la interfaz `DatosPersonalesRepositorio`
(`lib/nucleo/cuenta/datos/`), la versión demo y las pantallas; la
implementación real (`DatosPersonalesRed`) responde «no disponible» y Ajustes
oculta la fila «Datos personales» hasta que estos endpoints existan.

## Por qué no sirve lo que hay

- No existe un endpoint para editar nombre, correo, teléfono, empresa o
  documento de la cuenta (solo `/api/perfil/foto`, contraseña, teléfono por
  verificación y eliminación de cuenta).
- `/api/reclamos` es el reclamo **de un servicio** (uno por solicitud, con
  motivos de servicio). No cubre pedirle a atención al cliente que corrija un
  dato personal.

## Regla de negocio

1. Tras el registro, la persona puede editar **todos** sus datos personales
   **una sola vez**, por si se equivocó.
2. Después, los datos quedan fijos para ella. Si necesita un cambio, lo pide
   con un motivo escrito a atención al cliente (en el sistema es un reclamo;
   a la persona se le muestra como «solicitud de cambio»).
3. Un administrador revisa la solicitud y, si está justificada, edita los
   datos desde el panel. Los datos aprobados no se tocan por la API de la app.

## Endpoints propuestos

### `GET /api/cuenta/datos`

Datos personales vigentes y si queda la edición libre.

```json
{
  "datos": {
    "nombre": "Hugo Antelo Suárez",
    "correo": "hugo@ejemplo.com",
    "telefono": "+59177123456",
    "empresa": "Agropecuaria Los Tajibos",
    "documento": null
  },
  "puede_editar": true,
  "solicitud": null
}
```

- `empresa` y `documento` solo vienen si el rol o el tipo de persona los
  tiene (la app muestra solo los que no son `null`).
- `solicitud`: la más reciente
  `{ "motivo": "…", "estado": "pendiente|en_revision|resuelta", "creada_en": "ISO-8601" }`
  o `null`.
- `puede_editar` lo decide el servidor (flag «edición usada» por cuenta). La
  app no lo calcula.

### `PUT /api/cuenta/datos`

Gasta la única edición. Cuerpo con todos los campos editables:
`{ "nombre", "correo", "telefono", "empresa?", "documento?" }`.

- `200`: mismo cuerpo que `GET /api/cuenta/datos` (con `puede_editar: false`).
- `409 edicion_agotada`: ya se usó (también ante dos peticiones a la vez: la
  segunda pierde). La app relee el estado y lo avisa.
- `422`: validación por campo (correo, teléfono, duplicados), con el formato
  de errores ya usado por el contrato.
- Atómico: marca la edición como usada en la misma transacción que guarda.
- Correo o teléfono cambiados: la cuenta queda con ese dato **sin verificar**
  y el servidor reutiliza la verificación existente
  (`/api/cuenta/telefono/verificacion`, y el equivalente de correo si se
  define). Hay que fijar si el cambio bloquea algo hasta verificarlo.
- Auditoría: registro con valores anteriores y nuevos, autor y fecha (la
  corrección posterior es un registro nuevo con motivo y autor).

### `POST /api/cuenta/datos/solicitudes`

Cuerpo: `{ "motivo": "texto de 10 a 1000 caracteres" }`.

- `201`: `{ "solicitud": { "motivo", "estado": "pendiente", "creada_en" } }`.
- `409 edicion_disponible`: todavía puede editar él mismo.
- `409 solicitud_abierta`: ya tiene una `pendiente` o `en_revision`.
- Crea el caso en atención al cliente (reclamo de tipo `cambio_de_datos`,
  sin servicio asociado) y notifica al panel.

### Solo lectura de la solicitud

`GET /api/cuenta/datos` ya devuelve la más reciente. Para el historial
completo, `GET /api/cuenta/datos/solicitudes` (paginado), no urgente.

## Panel (administración)

Pantalla para atender la solicitud: ver motivo y datos actuales, editar los
datos de la persona con motivo obligatorio, y cerrarla como `resuelta`
(o rechazada con explicación). La edición del administrador no gasta ni
devuelve la edición libre de la persona. Notificar a la persona al resolver.

## Pendiente de decidir (dueño)

- ¿Qué campos son editables por rol? (cliente persona vs empresa; proveedor:
  ¿documento de identidad editable?).
- ¿Se puede devolver la edición libre a una cuenta (error de soporte)?
- Reverificación al cambiar correo y teléfono.
