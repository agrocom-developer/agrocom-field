# ADR 0009 — Arquitectura de las tres superficies móviles

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

Agrocom es un marketplace de servicio de fumigación con drones. La app móvil atiende a tres tipos de persona con necesidades opuestas en conectividad: el cliente solicita y sigue servicios con red; el piloto y el auxiliar ejecutan el servicio en un lote sin señal. Una sola base de código con tres flavors evita triplicar infraestructura (cliente HTTP, tema, autenticación, base local) y mantiene un contrato único con `agrocom-api`.

## Decisión

### Tres flavors, un código

| Flavor | Entrypoint | `applicationId` | Conectividad | Persistencia |
|---|---|---|---|---|
| `cliente` | `lib/main_cliente.dart` | `com.agrocom.agrocom_field.cliente` | online-first | caché liviana de lectura, sin outbox |
| `piloto` | `lib/main_piloto.dart` | `com.agrocom.agrocom_field.piloto` | offline-first en el lote | `drift` + outbox |
| `auxiliar` | `lib/main_auxiliar.dart` | `com.agrocom.agrocom_field.auxiliar` | offline-first en el lote | `drift` + outbox |

Cada flavor define su `Flavor` en `nucleo/flavor.dart`, su `applicationIdSuffix` y su label de launcher en `android/app/build.gradle.kts`, y su entrypoint. El nombre visible es «DronAgro» (titular Agrocom; `CLAUDE.md`).

### El flavor `cliente` es online-first

Las pantallas del cliente leen del repositorio, y el repositorio resuelve contra la red con una caché de lectura para que la app abra con la última lista conocida. No hay outbox, no hay `uuid_cliente` de sincronización diferida: una solicitud de servicio se envía con una clave de idempotencia generada en el dispositivo al crear la solicitud y se reintenta con la misma clave si la respuesta se pierde, de modo que un doble toque no crea dos servicios. Si no hay red, la pantalla lo dice y conserva lo ya escrito en el formulario.

### Los flavors `piloto` y `auxiliar` conservan el modelo del lote

Lectura desde `drift`, escritura local más outbox en una sola transacción, `uuid_cliente`, idempotencia, orden por `secuencia`, evidencias de menos de 300 KB en cola propia, decimal exacto. Son las invariantes físicas de `CLAUDE.md`. El servicio adjudicado se baja a `drift` al adjudicarse, de modo que el lote se ejecuta sin red.

### Negociar requiere red

Publicar, ofertar, contraofertar, aceptar, rechazar y retirar una oferta son llamadas en línea a la API, sin outbox. La adjudicación es un acuerdo entre dos partes que el servidor resuelve de forma atómica y su respuesta incluye el resultado. Una respuesta perdida se reintenta con el mismo `uuid_cliente` y el servidor devuelve la misma oferta. Es la única acción de negocio del proveedor que no pasa por el outbox; el detalle está en el ADR 0016.

### Estructura de carpetas

```
lib/
  main_cliente.dart  main_piloto.dart  main_auxiliar.dart
  nucleo/        api, auth, db, sync, evidencias, preferencias, tipos, ui, di, entorno
  cliente/       solicitar, seguimiento, calificar, servicios, cuenta
  nucleo/marketplace/proveedor/   mapa, ofertas, perfil, dron (superficie del proveedor, ADR 0012)
  piloto/        servicio_adjudicado, avance
  auxiliar/      servicio_adjudicado, fotos_avance
  features/      <feature>/{presentation,domain,data}  (hasta que cada una se ubique en su flavor)
```

Cada feature tiene tres capas: `presentation/` (pantallas y blocs), `domain/` (entidades y reglas puras) y `data/` (repositorios, fuentes remota y local).

### Reglas de importación

1. `cliente/`, `piloto/` y `auxiliar/` **no se importan entre sí**; solo importan de `nucleo/`.
2. Lo que dos flavors necesitan va a `nucleo/`; no se duplica ni se importa cruzado.
3. `nucleo/` no importa de ningún flavor.
4. `domain/` no importa de `data/` ni de `presentation/`; `presentation/` habla con `domain/` y nunca con la red ni con `drift` directamente.
5. `nucleo/sync` y `nucleo/db` solo los usan `piloto/` y `auxiliar/`. El flavor `cliente` no los importa, de modo que su compilación no arrastra el motor de sync.
6. Un test de arquitectura recorre los imports y falla si se viola alguna regla.

### Un rol escritor por registro

La solicitud la escribe el cliente; cada oferta, su autor (cliente o proveedor); el avance y el cierre, el piloto; cada mensaje, su autor; cada foto, quien la sube; la calificación del servicio, el cliente; la calificación del cliente, el proveedor. Cada una es un registro propio.

## Consecuencias

- Un cambio de contrato de `agrocom-api` se absorbe en `nucleo/api` y en los repositorios del flavor afectado.
- El flavor `cliente` se puede publicar y probar sin dispositivo de campo.
- La separación obliga a promover a `nucleo/` lo compartido (tema, autenticación, mapa, tipos decimales) en vez de copiarlo.
- La excepción de negociación con red es una decisión revisable: si la operación de campo demostrara que hace falta ofertar sin señal, se rediseña con reserva temporal en el servidor y no con una cola local.
