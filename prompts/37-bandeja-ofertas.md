<!-- ciclo: critica=si turno-noche=1 rama=feature/bandeja-ofertas etapas=4 descongela=tests -->

# Tarea 37 — Bandeja de ofertas del proveedor: aceptar y rechazar con red

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Bandeja de ofertas en `piloto`. Objetivo: el proveedor aprobado ve las ofertas vigentes con zona, hectáreas, producto, fecha y tiempo restante, y las acepta o rechaza. **Es la excepción documentada: la respuesta requiere red y no pasa por el outbox** (ADR 0009).
2. Lista en vivo (polling o el canal que publique el contrato) con cuenta regresiva local contra la hora del servidor. Una oferta vencida se marca y no se puede aceptar.
3. Aceptar y rechazar envían una clave de idempotencia generada en el dispositivo; un reintento tras una respuesta perdida devuelve el mismo resultado. Manejo explícito de: aceptada, ya tomada por otro proveedor, vencida, sin red y proveedor no aprobado. Nunca se muestra «aceptada» antes de la respuesta del servidor.
4. Al aceptar, el servicio asignado se baja a `drift` (pull inmediato del catálogo) antes de llevar al proveedor al detalle, de modo que pueda ejecutarlo sin red.
5. Los datos del cliente no se muestran en la oferta; solo después de aceptar.
6. Aviso de oferta nueva con notificación local si el contrato no publica push.
7. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/37.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No uses `cola_sync` ni `SyncEngine` para aceptar o rechazar.
- No repliques reglas de asignación (propios primero, escalado): las decide el servidor.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/nucleo/marketplace/proveedor` devuelve 0, con casos: aceptar con éxito, ya tomada, vencida, sin red (no queda aceptada), reintento idempotente y proveedor no aprobado.
- `grep -rnE 'cola_sync|SyncEngine' lib/nucleo/marketplace/proveedor/ofertas` no devuelve coincidencias (exit 1 de grep).

## Cierre de cada etapa

`runs/37.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/37.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/37.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop` marcado «revisión línea por línea pendiente del dueño».
