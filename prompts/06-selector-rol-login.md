<!-- ciclo: critica=no turno-noche=1 rama=feature/selector-rol-login etapas=3 descongela=tests -->

# Tarea 06 — HU-69 (caso simple): selector de rol al loguear, flavor `auxiliar`

## Qué hacer

Implementar el punto 2 de la **decisión ya tomada** en
`docs/decisiones/0005-selector-rol-flavor-auxiliar.md` (léela entera antes
de tocar código — este prompt resume, ese documento decide): cuando
`POST /api/auth/token` responde `409` (más de un rol vivo) en el flavor
`auxiliar`, la app muestra un selector con los roles del cuerpo y reintenta
el login con el `role_id` elegido. **No hace falta ningún ADR nuevo** — el
0005 ya cubre exactamente este alcance, con sus alternativas descartadas
documentadas.

`cola_tareas.md` ya anotaba que este caso "se retoma como tarea propia una
vez que 03 esté integrada" — HU-03 (login) está mergeada (PR #14), así que
esta tarea ya no depende de nada.

Cargá `verificacion` antes de cerrar etapas y `flujo-git-pr` antes de
rama/commits/PR. No es tarea crítica (no toca `nucleo/sync` ni `nucleo/db`).

### Contrato exacto (ya confirmado en el ADR, no lo reabras)

`POST /api/auth/token` (`docs/api/openapi.yaml`, operationId
`emitirTokenDispositivo`):

- Acepta `role_id` opcional en el body.
- `201`: cuerpo incluye `rol: RolActivo` (`{id, name, description}`),
  además de `token`/`token_type`/`usuario`/`dispositivo`.
- `409`: `{message: string, roles: RolActivo[]}` — los roles vivos entre
  los que hay que elegir.
- `403`: el `role_id` pedido no está entre los roles vivos (caso borde —
  ver "Qué NO hacer").

## Piezas a construir

1. **`lib/nucleo/auth/rol_activo.dart`** — `RolActivo` (id, name,
   description nullable), Dart puro.
2. **`lib/nucleo/auth/resultado_login.dart`** — `LoginRolAmbiguo` deja de
   ser `const LoginRolAmbiguo()` sin datos: pasa a llevar
   `List<RolActivo> roles`, parseados del `roles` del 409. El comentario
   que hoy dice "HU-69, fuera de alcance acá" queda obsoleto — actualizalo.
3. **`lib/nucleo/auth/login_service.dart`** — `login()` acepta `roleId`
   opcional (`int?`), lo manda como `role_id` en el body cuando no es
   `null`. Al parsear un `409`, arma `LoginRolAmbiguo` con la lista de
   roles del cuerpo (no vacía — si el cuerpo no trae `roles` o viene mal
   formado, tratalo como `LoginErrorDesconocido`, no asumas una lista
   vacía).
4. **Persistencia del rol activo** — pieza nueva que el ADR deja señalada
   sin implementar (sección Consecuencias): un store hermano de
   `TokenStoreSeguro` (mismo mecanismo, `flutter_secure_storage`) que
   guarda el `RolActivo` devuelto en el `201` (o `null` si no hay
   ambigüedad y el login fue directo). Nombre a tu criterio
   (`RolActivoStore` es razonable). Registralo en
   `lib/nucleo/di/service_locator.dart`.
5. **`lib/features/auth/login_cubit.dart`** — `LoginCubit` recibe
   `Flavor` por constructor (además de `LoginService`) para decidir el
   comportamiento ante `LoginRolAmbiguo`:
   - `Flavor.piloto`: **sin cambios** — mismo mensaje genérico de hoy
     ("Tu usuario tiene más de un rol activo..."). El ADR es explícito:
     "El flavor piloto (RC) no cambia... No hay selector de rol en el
     flavor piloto" (punto 1 de la decisión). No le agregues el selector.
   - `Flavor.auxiliar`: emite un estado nuevo con los `roles` recibidos
     (ver `login_estado.dart` abajo), sin guardar nada todavía.
   - El Cubit necesita retener `usuario`/`contrasena` **en memoria**
     durante el intento en curso para poder reintentar con el `role_id`
     elegido (`elegirRol(int rolId)` → vuelve a llamar
     `LoginService.login` con las mismas credenciales + `roleId`) — nunca
     persistidas en disco (el ADR descarta explícitamente guardar
     usuario/contraseña localmente, alternativas descartadas).
   - En cualquier `201` (con o sin selector de por medio), guardá el
     `RolActivo` recibido con el store del punto 4 antes de emitir el
     estado de éxito.
6. **`lib/features/auth/login_estado.dart`** — estado nuevo, p. ej.
   `LoginRequiereSeleccionRol(List<RolActivo> roles)`.
7. **`lib/features/auth/login_vista.dart`** — cuando el estado es el
   nuevo, mostrá la lista de roles (label: `description` si no es null,
   si no `name`) y al tocar uno llamá `cubit.elegirRol(rol.id)`.
8. **`lib/main_auxiliar.dart`/`lib/main_piloto.dart`** — pasá el `Flavor`
   correspondiente al construir `LoginCubit` en la factory que hoy arma
   `crearLoginCubit`.
9. **`docs/vision.md`** — el ADR 0005 deja pedido explícitamente
   actualizar dos frases que quedan desactualizadas con esta tarea: "el
   rol activo lo determina el flavor que abrió, no una elección en
   pantalla" (sección "Roles que usan esta app") y la nota de "todavía sin
   resolver" sobre roles con más permisos que su propio flavor (sección
   "Las dos apps, un solo código"). No es zona congelada, no hace falta
   `descongela` para tocarlo.

## Cómo repartir las etapas

- Etapa 1: `RolActivo` + `ResultadoLogin` extendido + `LoginService` con
  `roleId` + el store de rol activo, con tests (`login_service_test.dart`:
  409 con roles parseados, `role_id` viajando en el body cuando se pasa,
  201 persiste el rol recibido).
- Etapa 2: `LoginCubit` con `Flavor` + estado nuevo + `elegirRol`, con
  tests (`login_cubit_test.dart`: piloto+409 → mensaje genérico sin
  cambios respecto a hoy; auxiliar+409 → estado de selección; `elegirRol`
  reintenta con las credenciales retenidas; único rol vivo → sin
  selector, directo a éxito).
- Etapa 3: `LoginVista` con la UI de selección + wiring en `main_*.dart` +
  actualización de `docs/vision.md` + tests de widget (selector visible
  solo en el fixture `auxiliar`, tap dispara `elegirRol`).

## Qué NO hacer

- **No tocar "cambiar de rol en caliente"** (punto 3 de la decisión del
  ADR) — sigue bloqueado del lado `agrocom-api` (nota abierta de su ADR
  0004, extensión, punto 6). El selector de esta tarea es parte del flujo
  de login/re-login, nunca un cambio de contexto dentro de una sesión ya
  autenticada. Si te tienta resolverlo "ya que estás", no lo hagas — el
  ADR 0005 ya lo descarta explícitamente con su razonamiento.
- No agregar selector de rol al flavor `piloto` (punto 1 de la decisión).
- No persistir `usuario`/`contrasena` en disco para evitar pedir
  credenciales de nuevo — alternativa descartada explícitamente en el ADR.
- No tocar `applicationId`/`applicationIdSuffix`/nombre visible de la app
  (punto 4 del ADR, "nota abierta, no decidida acá" — queda a criterio del
  dueño, no de esta tarea).
- No manejar el `403` (role_id inválido) con una pantalla dedicada si no
  te alcanza el tiempo de la etapa — tratarlo como `LoginErrorDesconocido`
  (comportamiento ya existente hoy para códigos no mapeados) es aceptable
  para esta tarea; documentalo como pendiente en `runs/06.md` si lo dejás
  así.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba —
en particular, un test que confirme que el flavor `piloto` **no** cambia
de comportamiento ante un `409` (regresión, no solo caso nuevo).

## Cierre obligatorio de cada etapa

`runs/06.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/06.md`: qué se hizo y qué falta, concreto.

Al cerrar con `OK`, `runs/06.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que
el qué: `RolActivo` + `ResultadoLogin` + `LoginService` + store de rol,
`LoginCubit` + estado nuevo, `LoginVista` + wiring + `docs/vision.md`. Sin
trailer `Co-Authored-By`.
