# ADR 0001 — Cliente API manual sobre `dio`

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` — numeración independiente de la serie de ADR de `agrocom-api` (que llega hasta 0018 a la fecha); acá arranca en 0001 porque es la primera decisión técnica de este repo que no está cubierta por ningún ADR de `agrocom-api`.

## Contexto

`agrocom-field` arranca su bootstrap técnico (ADR 0005 de `agrocom-api`: BLoC feature-first, `nucleo/` vs `features/`) y necesita, desde el primer commit de código, una forma de consumir el contrato de API que publica `agrocom-api` (`docs/api/openapi.yaml`, generado code-first por ADR 0014 de ese repo — "el código es la fuente de verdad y genera el YAML; el YAML versionado es el contrato que consume la app"). Ese contrato está activamente en movimiento: TE-05 (`POST /api/sync` idempotente) es, a la fecha, la tarea crítica en curso del lado servidor, y es justamente el endpoint del que depende el protocolo de sync (especificación §2.1).

ADR 0005 fija la arquitectura de carpetas y la regla de dependencia (los blocs leen de `drift`, nunca de la API directo) pero no decide con qué herramienta concreta se habla con la API ni dónde vive exactamente esa pieza dentro de `nucleo/`. Tampoco lo decide ningún otro ADR de `agrocom-api`, porque el cliente HTTP es una pieza exclusiva del lado app.

## Decisión

Cliente HTTP escrito a mano sobre el paquete `dio`, viviendo en `lib/nucleo/api/`:

- `ApiClient`: wrapper de `dio` con la configuración base (URL, timeouts).
- Interceptor de autenticación: agrega `Authorization: Bearer {token}` (token por dispositivo, Sanctum — ver `docs/vision.md`, sección "Identidad").
- Mapeo de errores a una excepción sellada `ApiExcepcion`, con variantes `ApiExcepcionRed`, `ApiExcepcionServidor` y `ApiExcepcionDesconocida`.

Los modelos de payload (DTOs) se modelan con `freezed` + `json_serializable`. Esto no agrega una herramienta nueva al proyecto: `drift_dev` (esquema de la base local) ya exige `build_runner`, así que `freezed`/`json_serializable` reutilizan la misma toolchain de generación de código.

Este cliente es **infraestructura pura de `nucleo/`**: ningún bloc ni nada en `presentation/` lo llama directo. Solo lo usan los repositorios de `nucleo/sync/` y `nucleo/catalogo/` — la misma regla de dependencia de ADR 0005 e invariante 1 de `CLAUDE.md` de este repo ("la UI nunca lee de la red directamente"). `ApiExcepcionRed` (sin conectividad) es el caso normal en el lote, no una excepción rara: el repositorio la captura y el registro queda `pendiente` en el outbox local (invariante 3 de `CLAUDE.md`); nunca sube como error visible de UI.

## Alternativas descartadas

- **Generar el cliente desde `openapi.yaml`** con `openapi-generator` u otra herramienta equivalente. Se descarta porque: (a) agrega una toolchain Java/Node adicional a un proyecto que hoy solo necesita Dart/Flutter; (b) el contrato está activamente en movimiento del lado servidor (TE-05 sigue en curso) — regenerar contra un contrato inestable cuesta más de lo que ahorra en esta etapa; (c) el estilo de código generado no encaja naturalmente con BLoC feature-first ni con el patrón "el repositorio es el único punto que toca outbox/red", que acá es manual por diseño.

## Consecuencias

- Mantener el cliente sincronizado con `openapi.yaml` es un trabajo manual: cada endpoint nuevo se agrega a mano cuando se implementa el caso de uso que lo necesita (TE-05/TE-06 y las features siguientes), no por regeneración automática.
- Revisar esta decisión si el contrato de API crece mucho en superficie o se estabiliza del todo — en ese punto el costo de generación automática podría justificarse.
- `logica-offline` y `modelo-datos-flutter` son quienes escriben los repositorios que consumen este cliente; `flutter-ui` y cualquier bloc no deberían importar `lib/nucleo/api/` directamente — si aparece un import de ese tipo en un PR, es una violación de esta decisión y de la invariante 1 de `CLAUDE.md`.
