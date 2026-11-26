# ADR 0005 — Selector de rol activo en el flavor `auxiliar`

**Estado:** Reemplazada por ADR 0021 y por ADR 0024 (el login ya no lleva rol: cada app admite un solo tipo de cuenta) · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

El flavor fija la superficie instalada (ADR 0009): `cliente`, `piloto` o `auxiliar`. En el marketplace hay proveedores con más de un rol: un piloto independiente que a veces opera y a veces ayuda como auxiliar en el servicio de otro. El control remoto del dron (flavor `piloto`) es hardware dedicado y nunca cambia de rol. El celular del lote (flavor `auxiliar`) lo usa la misma persona en uno u otro papel según el turno.

El contrato de `agrocom-api` (`POST /api/auth/token` en `docs/api/openapi.yaml`) acepta un `role_id` opcional. Si la persona tiene más de un rol vivo y no lo indica, responde `409` con `{message, roles: RolActivo[]}`; si el `role_id` pedido no está entre sus roles vivos, responde `403`. Cada token queda atado a un único rol y no existe un endpoint para cambiar el rol de un token vivo: obtener un token con otro rol requiere autenticar de nuevo, lo que revoca el token anterior del mismo `uuid_dispositivo`.

## Decisión

1. **El flavor `piloto` no tiene selector.** `Flavor.piloto` es la única fuente de verdad de lo que muestra esa instalación. El flavor `cliente` tampoco: su rol es siempre el de cliente.
2. **El flavor `auxiliar` resuelve el rol activo al emitir el token.** Si `POST /api/auth/token` responde `409`, la app muestra un selector con los roles del cuerpo y reintenta el login con el `role_id` elegido. Con un único rol vivo no hay selector.
3. **El rol activo es estado observable en `nucleo/auth`**, poblado desde el `RolActivo` del `201` o releído de `GET /api/auth/sesion` al reconectar. Dentro del flavor `auxiliar`, las pantallas leen ese estado para decidir qué mostrar, no el enum `Flavor`. `Flavor.auxiliar` sigue fijando la configuración de la instalación.
4. **Cambiar de rol es un re-login.** No hay cambio en caliente dentro de un token vivo: la app pide credenciales de nuevo y llama a `POST /api/auth/token` con el `role_id` nuevo. Si `agrocom-api` publica un mecanismo de cambio de rol sobre un token vivo, este ADR se actualiza.
5. **El selector se rehace con los componentes del modo campo** (`ItemListaCampo` tocable, ADR 0008).

## Alternativas descartadas

- **Selector también en `piloto`:** el control remoto es de un solo uso; el selector sumaría estado que nunca se ejercita.
- **Una instalación por rol:** fricción operativa sin beneficio; el rol varía por turno sin cambiar de dispositivo.
- **Ampliar el enum `Flavor` con el rol activo:** `Flavor` es una constante de compilación y el rol activo es estado de ejecución.
- **Guardar usuario y contraseña en el dispositivo** para reemitir el token: crea credenciales en el dispositivo, justo lo que `TokenStoreSeguro` evita.
- **Cachear un token por rol y alternar el encabezado `Authorization`:** el servidor revoca el token anterior en cada emisión, así que no pueden convivir dos tokens vivos.

## Consecuencias

- `nucleo/auth` expone el rol activo (un cubit o servicio observable) y se registra en `nucleo/di`.
- Decidir si el rol activo se persiste junto al token o se resuelve siempre contra `GET /api/auth/sesion` es una decisión de la tarea que lo implementa.
- Comparar contra `Flavor.auxiliar` para decidir una pantalla dentro de ese flavor es una violación de este ADR que la revisión señala.
- El nombre visible del launcher del flavor `auxiliar` («Agrocom Auxiliar») puede sugerir «solo auxiliar»; es una decisión revisable del dueño, y no cambia `applicationId`.
