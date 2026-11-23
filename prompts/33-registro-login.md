<!-- ciclo: critica=no turno-noche=1 rama=feature/registro-login etapas=4 descongela=tests -->

# Tarea 33 — Registro e inicio de sesión de cliente y de proveedor

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Registro e inicio de sesión de las dos poblaciones. Objetivo: un cliente se registra y entra desde el flavor `cliente`; un proveedor se registra desde `piloto` o `auxiliar` y queda pendiente de aprobación hasta que el admin lo apruebe.
2. Cliente: formulario de registro (nombre, teléfono, correo, contraseña), login, cierre de sesión que borra el token y revoca el dispositivo.
3. Proveedor independiente: registro propio con los datos que pide el contrato; al terminar, pantalla «Tu cuenta está en revisión» con el estado leído de `GET /api/auth/sesion`; sin acceso a ofertas hasta la aprobación. El piloto registra a su auxiliar desde su perfil; el auxiliar queda pendiente de aprobación del admin.
4. El token vive solo en `TokenStoreSeguro`. Ningún dato personal ni token en logs.
5. Los errores de validación del servidor (`422`) se muestran junto al campo; sin red, el formulario conserva lo escrito.
6. El selector de rol del flavor `auxiliar` (ADR 0005) sigue funcionando con el `409` y el `role_id`.
7. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/33.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No implementes la recuperación de contraseña si el contrato no la publica.
- No guardes la contraseña en el dispositivo.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/cliente/auth test/piloto/auth test/nucleo/auth` devuelve 0, con casos: registro exitoso, `422` por campo, `409` con selector de rol, cuenta pendiente de aprobación y cierre de sesión que borra el token.

## Cierre de cada etapa

`runs/33.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/33.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/33.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
