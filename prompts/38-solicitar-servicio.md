<!-- ciclo: critica=no turno-noche=1 rama=feature/solicitar-servicio etapas=4 descongela=tests -->

# Tarea 38 — Solicitar servicio: lote en el mapa, hectáreas, producto y fecha

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Flujo de solicitud del flavor `cliente`, en pasos cortos: 1) lote, 2) producto y hectáreas, 3) fecha, 4) resumen y envío.
2. Lote: mapa con `flutter_map` y teselas abiertas (decisión revisable, sin clave de proveedor). El cliente dibuja un polígono sobre el mapa o elige un lote guardado; el área se calcula en el dispositivo y se propone como hectáreas, editable. Hectáreas y cualquier monto en decimal exacto (ADR 0002).
3. Producto: lista del catálogo del contrato. Fecha: fecha deseada con la anticipación mínima del contrato.
4. Envío con clave de idempotencia generada al crear la solicitud; un doble toque o un reintento no crea dos servicios. Sin red: el formulario conserva lo escrito y lo dice. No hay outbox.
5. Al enviar, pantalla de confirmación con el estado «Buscando proveedor» y acceso al seguimiento.
6. La ubicación del dispositivo solo se usa para centrar el mapa, con permiso pedido en contexto.
7. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/38.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No agregues cobro ni selección de proveedor por el cliente: el motor asigna.
- No importes `nucleo/sync` ni `nucleo/db` desde `lib/cliente/`.
- Calidad de UI: seguí la política de `CLAUDE.md`. Tokens de `nucleo/ui`, una acción principal por pantalla, estados de carga, vacío, error, sin red y éxito, textos en español con acentos, golden tests en teléfono pequeño y grande.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/cliente/solicitar` devuelve 0, con casos: polígono a hectáreas decimales, doble envío con una sola solicitud, sin red conserva el formulario y fecha inválida.
- `flutter test test/arquitectura/importaciones_test.dart` devuelve 0.

## Cierre de cada etapa

`runs/38.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/38.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/38.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
