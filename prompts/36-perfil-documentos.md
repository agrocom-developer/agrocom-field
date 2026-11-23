<!-- ciclo: critica=no turno-noche=1 rama=feature/perfil-documentos etapas=3 descongela=tests -->

# Tarea 36 — Perfil y documentos del proveedor

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Perfil del proveedor en `piloto`: datos personales, zona de operación, disponibilidad (en línea o no), calificación recibida (solo lectura) y estado de aprobación.
2. Documentos (licencia de piloto, matrícula del dron, seguro): selección desde cámara o galería, compresión a menos de 300 KB, subida por HTTPS con reintento manual, estado por documento (pendiente, aprobado, rechazado con motivo del admin).
3. Los documentos no se cachean en claro fuera del almacenamiento privado de la app y se borran al cerrar sesión. La ubicación se pide solo al activar la disponibilidad, con el motivo explicado antes del permiso.
4. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/36.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No muestres la moderación interna del admin más allá del motivo de rechazo.
- No registres ubicación en logs.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/nucleo/marketplace/proveedor` devuelve 0, con casos de subida exitosa, imagen mayor a 300 KB comprimida, documento rechazado con motivo y cierre de sesión que limpia los documentos locales.

## Cierre de cada etapa

`runs/36.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/36.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/36.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
