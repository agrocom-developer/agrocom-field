<!-- ciclo: critica=no turno-noche=1 rama=feature/modo-emergencia etapas=3 descongela=tests -->

# Tarea 09 — HU-68: modo emergencia con linterna

## Qué hacer

Un botón de acceso a "modo emergencia" en un toque, visible desde
cualquier pantalla (incluida la de login — no requiere sesión iniciada ni
señal), con la linterna del dispositivo como acción concreta
(`docs/gestion/plan_sprints.md`, Sprint 15, HU-68). Sprint 15 es
enteramente del flavor `auxiliar` — gatealo por `Flavor.auxiliar`, no lo
sumes a `main_piloto.dart` (el RC no recibe trabajo nuevo este sprint).

**Recorte explícito, con su porqué**: la HU dice "con acciones rápidas —
incluida la linterna" (plural), pero ni `plan_sprints.md` ni ningún otro
documento de este repo o de `agrocom-api` especifica cuáles son las demás
acciones (¿llamar a un contacto? ¿compartir ubicación? nada de eso está
definido). Inventarlas sería escribir alcance que no sale del plan — regla
de la propia planificación de este ciclo. Esta tarea entrega **el punto de
entrada de un toque + la linterna**, que es lo único con criterio de
aceptación concreto y verificable. Documentá el recorte en `runs/09.md`
para que quede a la vista si el dueño quiere sumar más acciones después.

Cargá `verificacion` antes de cerrar etapas y `flujo-git-pr` antes de
rama/commits/PR. No es tarea crítica (no toca `nucleo/sync` ni
`nucleo/db`).

### Piezas a construir

1. **`pubspec.yaml`** — agregar un paquete de linterna establecido en
   pub.dev (p. ej. `torch_light`, o el que evalúes con mejor mantenimiento
   vigente al momento de implementar — documentá en `runs/09.md` cuál
   elegiste y por qué, mismo criterio que ya pide invariante 9 de
   `CLAUDE.md` para no asumir un paquete sin confirmarlo).
2. **`lib/nucleo/linterna/linterna_controlador.dart`** — interfaz + impl,
   mismo patrón que el resto de `nucleo/` (abstracta para poder fakear en
   tests sin canal de plataforma real):
   - `abstract class LinternaControlador { Future<bool> disponible();
     Future<void> encender(); Future<void> apagar(); }`
   - Impl concreta envolviendo el paquete elegido.
   - Registrar en `service_locator.dart`.
3. **Permisos Android** — agregar en
   `android/app/src/main/AndroidManifest.xml` lo que pida el paquete
   elegido (típicamente `android.permission.CAMERA` +
   `<uses-feature android:name="android.hardware.camera.flash"
   android:required="false"/>`, para no excluir dispositivos sin flash).
4. **`lib/features/emergencia/presentation/`** — botón flotante de un
   toque, montado a nivel raíz de la app (en `lib/app.dart`, envolviendo
   `_RaizApp` en un `Stack` — así aparece sobre `LoginPantalla` y sobre
   cualquier pantalla posterior, sin depender de en qué ruta esté el
   usuario), visible solo cuando `flavor == Flavor.auxiliar`. Al tocarlo,
   abre un panel simple (`BottomSheet`/`Dialog`, a tu criterio) con un
   control de linterna (encender/apagar, con estado visible) que usa
   `LinternaControlador`.
5. **`AgrocomApp`** — pasar el `Flavor` (ya lo recibe) hasta el widget que
   decide si monta el botón; no dupliques lógica de flavor en más de un
   lugar.

### Tests

- `LinternaControlador`: si el canal de plataforma del paquete elegido se
  puede mockear con las herramientas de `flutter_test`, cubrilo; si no,
  documentalo en `runs/09.md` (mismo criterio ya aceptado en la tarea 08
  para `NotificadorLocalPlugin`).
- Widget: con un fake de `LinternaControlador` (mocktail), confirmar que
  el botón de emergencia aparece en el fixture `auxiliar` (incluso sobre
  `LoginPantalla`, sin token) y **no** aparece en el fixture `piloto`; que
  tocarlo abre el panel; que tocar encender/apagar linterna llama al
  controlador y refleja el estado en pantalla.

## Cómo repartir las etapas

- Etapa 1: `LinternaControlador` + impl + permisos Android + DI, con sus
  tests (o la nota de por qué no se pudo testear el canal real).
- Etapa 2: botón flotante + panel de linterna, wiring en `app.dart`
  gateado por flavor, tests de widget.
- Etapa 3: verificación end-to-end liviana (aparece en login sin token,
  aparece después de loguearse, nunca en piloto) + `runs/09.md` con el
  paquete elegido y el recorte de "acciones rápidas" documentados.

## Qué NO hacer

- No inventar más acciones de emergencia que la linterna — ver el recorte
  de arriba. Si te tienta agregar "llamar a alguien" o "compartir
  ubicación", no lo hagas: no está definido en ningún documento del plan.
- No agregar el botón a `main_piloto.dart` ni a ninguna pantalla exclusiva
  de `piloto`.
- No exigir sesión iniciada para ver o usar el botón — es exactamente lo
  que la HU pide evitar ("sin salir de la app... sin login adicional").
- No agregar un nuevo endpoint ni registro de sync para esto — es
  puramente local, sin servidor de por medio.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba —en
particular, un test que confirme que el botón de emergencia es visible
incluso antes de loguearse (fixture `auxiliar` sin token) y ausente en el
fixture `piloto`.

## Cierre obligatorio de cada etapa

`runs/09.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/09.md`: qué se hizo, qué falta, el paquete de linterna elegido y por
qué, y el recorte de "acciones rápidas" documentado.

Al cerrar con `OK`, `runs/09.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: dependencia + `LinternaControlador` + permisos, botón flotante +
panel + wiring en `app.dart`. Sin trailer `Co-Authored-By`.
