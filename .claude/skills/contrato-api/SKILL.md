---
name: contrato-api
description: Cómo se publica el contrato de API (openapi.yaml, generado en agrocom-api) y cómo lo consume agrocom-field — cliente manual sobre dio, DTOs, manejo de errores y qué hacer cuando el contrato cambia. Usar antes de agregar, cambiar o depender de un endpoint.
---

# Contrato de API — del servidor a la app

## Quién escribe qué

- **El contrato lo genera `agrocom-api`**, code-first: los atributos `OA\...` en los controllers, form requests y resources producen `docs/api/openapi.yaml` (ADR 0014 de ese repo, ruta local `/Applications/MAMP/htdocs/agrocom-api`). Se regenera con `composer openapi` y se versiona. **Acá nunca se edita a mano.**
- **La app lo consume a mano** (ADR 0001 de este repo): `lib/nucleo/api/ApiClient` sobre `dio`, DTOs con `freezed` y `json_serializable`, errores mapeados a `ApiExcepcion` (`ApiExcepcionRed`, `ApiExcepcionServidor`, `ApiExcepcionDesconocida`). No se genera el cliente desde el YAML.

## Regla de dependencia

Solo los repositorios de `nucleo/` y de cada feature usan `ApiClient`. Un bloc o un widget que llama a `dio` es un error de arquitectura. En `piloto` y `auxiliar` la UI lee de `drift`; en `cliente` el repositorio resuelve red con caché local.

## Agregar o usar un endpoint

1. Leé la operación en `openapi.yaml` (payload, códigos de respuesta, esquemas). Si no está, el endpoint no existe: pedilo a `agrocom-api` con una petición en `docs/gestion/peticiones_agrocom_api/`, no lo supongas.
2. Creá el DTO con los nombres del dominio tal como viajan (`hectareas_declaradas`, `uuid_cliente`). Dinero y hectáreas se parsean a decimal exacto, nunca a `double`.
3. Agregá el método al repositorio de la feature; no al bloc.
4. Escribí el test con un `dio` falso, incluyendo 401, 403, 404, 422 y corte de red.
5. En `piloto` y `auxiliar`, si el dato lo escribe el usuario en el lote, va por outbox (skill `protocolo-sync`) y no se llama directo. Negociar una oferta (ofertar, contraofertar, aceptar, rechazar, retirar) es la excepción: llamada en línea con confirmación del servidor.

## Cuando el contrato cambia

1. Compará el `openapi.yaml` nuevo con el anterior (diff de git en `agrocom-api`).
2. Cambio compatible (campo opcional nuevo): se adopta cuando haga falta.
3. Cambio incompatible (campo renombrado, tipo distinto, endpoint retirado): se coordina con `GET /api/version` para que la versión mínima de la app exija la versión que sabe leerlo, y se migra el esquema local con `migracion-esquema` si hace falta.
4. Un test de contrato mínimo por endpoint consumido (el DTO parsea un ejemplo del propio YAML) detecta el desvío antes de que llegue al campo.

## Qué nunca

- Editar `openapi.yaml` desde este repo.
- Inventar campos "porque seguro vienen".
- Dejar un cliente consumiendo un endpoint sin test de parseo.
- Guardar el token en preferencias planas: va en almacenamiento seguro (ver `confianza-seguridad`).
