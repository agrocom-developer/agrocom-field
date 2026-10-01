<!-- ciclo: critica=no turno-noche=1 rama=feature/tema-global-campo etapas=2 descongela=tests -->

# Tarea 22 — Modo campo como tema de toda la app: carga, bloqueo de versión y emergencia (ADR 0008)

## Qué hacer

Cierra la decisión del dueño del 1/10/2026 (ADR 0008, «todas las pantallas
reales migran al modo campo»). Las tareas 20 (órdenes) y 21 (sesión de vuelo
e incidencia) migran las pantallas de flujo; quedan las piezas transversales
que ve **cualquier** usuario de los dos flavors y que hoy salen con
`AgrocomTheme.light()`/`.dark()` (ADR 0003), según `ThemeMode.system`:

- `lib/app.dart`: el `MaterialApp` (`theme`/`darkTheme`/`themeMode`) y la
  pantalla de carga mientras se resuelve la sesión (`Scaffold` con
  `CircularProgressIndicator` sobre fondo claro u oscuro según el sistema).
- `lib/nucleo/version/version_bloqueada_pantalla.dart`: el bloqueo por
  versión mínima (HU-20).
- `lib/features/emergencia/presentation/`: el botón flotante y el panel de
  linterna en `showModalBottomSheet` (HU-68), que aparece encima de
  cualquier pantalla, incluido el login.

Cargá `verificacion` y `flujo-git-pr`. No toca `nucleo/db` ni `nucleo/sync`.

Referencias: `lib/nucleo/ui/tema_campo.dart` (`AgrocomThemeCampo`), ADR 0008
completo, `lib/features/auth/login_vista.dart` y lo que hayan dejado las
tareas 20/21 si ya están integradas.

### Piezas

1. **Tema global.** `MaterialApp` usa `AgrocomThemeCampo.construir()` como
   tema único (sin depender de `ThemeMode.system`: el modo campo es oscuro
   siempre). Los `Theme(data: AgrocomThemeCampo.construir())` por pantalla
   que ya existan quedan redundantes: quitalos solo si el test de esa
   pantalla sigue pasando sin cambiar de criterio; si no, dejalos y anotalo.
2. **Pantalla de carga.** Fondo `ColoresCampo.fondoProfundo` con el logo
   (`LogoAgrocomCampo`) y un indicador con el acento del tema — que el
   arranque no muestre un destello blanco antes del login.
3. **Bloqueo de versión.** Misma información y mismas `Key`s
   (`version_bloqueada_pantalla`, …), con tipografía y tarjetas del catálogo;
   el entorno/versión al pie con `PieEntornoCampo` si los datos ya llegan a
   esa pantalla (no agregues lectura de configuración nueva).
4. **Emergencia.** Botón con `ColoresCampo.acentoRojo` y panel de linterna
   con superficie, tipografía y switch del tema campo. Mismas `Key`s
   (`emergencia_boton`, `linterna_switch`, `linterna_estado`,
   `linterna_error`). Sigue alcanzable en un toque desde cualquier pantalla.
5. **`AgrocomTheme` de ADR 0003.** Si después de esto ninguna pantalla lo
   usa, **no lo borres**: anotalo en `runs/22.md` como candidato a retirar
   en un cambio aparte (ADR 0008 lo deja así).

## Cómo repartir las etapas

1: tema global + pantalla de carga + bloqueo de versión. 2: emergencia y
cierre.

## Qué NO hacer

- No cambies `VersionBloqueoOverlay`, el polling de versión, el cubit de
  linterna ni la lógica de sesión/token de `app.dart`: es una migración
  visual.
- No cambies ninguna `Key` existente; si un test busca por tipo de widget de
  Material, cambialo a la `Key` sin cambiar lo que verifica.
- No uses colores, radios ni `TextStyle` sueltos; si falta un átomo, va a
  `lib/nucleo/ui/componentes/` y al barrel.
- No construyas onboarding ni «Vincular dispositivo»: no tienen HU (ADR 0008).
- No toques la vista previa (`vitrina_campo/`).
- No edites `CLAUDE.md`.

## Criterio de aceptación

`./bin/verify` devuelve 0, y además: `grep -n "AgrocomTheme\.\(light\|dark\)" lib/app.dart`
sin resultados; `grep -nE "AppBar|FilledButton|ElevatedButton|ListTile" lib/nucleo/version lib/features/emergencia/presentation`
sin resultados; un test de widget verifica que la pantalla de carga y el
bloqueo de versión se construyen con el fondo `ColoresCampo.fondoProfundo`,
y los tests existentes de versión y emergencia pasan con el mismo criterio.

## Cierre obligatorio de cada etapa

`runs/22.estado` con una palabra: `PARCIAL`, `OK` o `BLOQUEADA`. `runs/22.md`
con qué se hizo y qué falta. Al cerrar con `OK`, `runs/22.pr.md`: título en la
primera línea, cuerpo debajo.

## Commits

Por pieza coherente, en español, imperativo, con el porqué. Sin trailer
`Co-Authored-By`.
