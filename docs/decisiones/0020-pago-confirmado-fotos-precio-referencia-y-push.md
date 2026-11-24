# ADR 0020 — Pago confirmado, fotos, precio de referencia y token push

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: `docs/api/openapi.yaml` de `agrocom-api` (`/api/solicitudes/{id}/pago-confirmado`, `/api/perfil/foto`, `/api/terrenos/{id}/fotos`, `/api/referencias/precio`, `/api/dispositivos`).

## Contexto

La API expone cinco rutas que completan el marketplace sin cobrar en la app: el proveedor informa que recibió el pago, las cuentas tienen foto de perfil, el cliente fotografía su terreno, el solicitante ve un precio de referencia por hectárea y el aparato registra su token de push. Esta decisión fija dónde viven en la app, por qué canal viajan y qué se protege.

## Decisión

### Dónde viven

Todo es compartido entre flavors y se queda en `nucleo/`, detrás de una interfaz con implementación de red y una en memoria para el modo demo y las pruebas:

| Capacidad | Interfaz | Red | Demo |
|---|---|---|---|
| Pago confirmado | `PagosRepositorio` | `PagosRed` | `PagosDemo` |
| Precio de referencia | `ReferenciasRepositorio` | `ReferenciasRed` | `ReferenciasDemo` |
| Foto de perfil | `FotoPerfilRepositorio` | `FotoPerfilRed` | `FotoPerfilDemo` |
| Fotos de terreno | `FotosTerrenoRepositorio` | `FotosTerrenoRed` | `FotosTerrenoDemo` |
| Token push | `DispositivosPushRepositorio` | `DispositivosPushRed` | `DispositivosPushDemo` |

Las redes usan `MarketplaceHttp`, la puerta común hacia `ApiClient`. Los flavors no se importan entre sí: cada uno compone las que necesita. `Lote.fotos`, `Proveedor.fotoUrl` y `ProveedorOfertante.fotoUrl` son campos opcionales del dominio; sin foto quedan vacíos o nulos.

### Todo va en línea, nada por el outbox

- **Pago confirmado.** Lo escribe el proveedor titular después del servicio, fuera del lote, y el cliente solo lo lee. El servidor fija el monto, un solo registro por solicitud, y rechaza un segundo `uuid_cliente` con `409 pago_ya_confirmado`; un `403 pago_solo_titular` indica que la cuenta no es la titular. Es una confirmación que el usuario espera ver aceptada, no un registro del lote capturado sin señal, así que no entra al outbox (que no se toca). Sin red, la pantalla ofrece reintentar; el `uuid_cliente` se genera una vez al abrir la acción y se reutiliza en cada reintento, con lo que repetir es seguro (`200` con el mismo registro).
- **Fotos de perfil y de terreno.** Las sube el cliente o la cuenta desde una pantalla con red; la foto va comprimida a menos de 300 KB y la app no envía una mayor. Máximo 8 por terreno.
- **Precio de referencia.** Es una lectura; es una guía, no un límite, y la app no lo aplica como regla.
- **Token push.** Se registra al iniciar sesión y se retira al cerrarla, antes de borrar el token de sesión.

### Fotos de avance del servicio

La subida de fotos de avance, finales e incidencias del lote usa `POST /api/solicitudes/{id}/evidencias` (multipart, idempotente por `uuid_cliente`, `tipo` en `foto_avance`, `foto_final`, `foto_incidencia`), tal como lo hace el motor de ejecución. Sigue en la cola de evidencias, separada de los registros livianos.

### Seguridad

- El token push vive solo en almacenamiento seguro (`TokenPushStoreSeguro`, Keychain/Keystore). Nunca en preferencias planas, logs, mensajes de error ni capturas; los errores de `registrar` y `retirar` no lo incluyen. Cerrar sesión lo retira del servidor; sin red queda guardado para reintentar, y un `404` se toma como hecho.
- Las URL de fotos son firmadas y duran 15 minutos: no se guardan; se piden de nuevo con la sesión o con el terreno. Se piden sin token.
- Dinero y hectáreas son `Decimal` (ADR 0002): el monto del pago, el precio de referencia y las hectáreas del terreno.

### Errores

`MarketplaceHttp` traduce `403`, `404`, `409` y `422` a `OperacionRechazada` con `codigo` HTTP y `motivo` de negocio (`MotivoPago.yaConfirmado`, `MotivoPago.soloTitular`); la falta de red, a `SinConexion`.
