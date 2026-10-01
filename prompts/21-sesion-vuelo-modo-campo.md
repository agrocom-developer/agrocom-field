<!-- ciclo: critica=no turno-noche=1 rama=feature/sesion-vuelo-modo-campo etapas=3 descongela=tests -->

# Tarea 21 — Sesión de vuelo e incidencia al modo campo (ADR 0008)

## Qué hacer

Segunda migración visual de la decisión del dueño del 1/10/2026 (ADR 0008,
«todas las pantallas reales migran al modo campo»). La feature `sesion_vuelo`
(abrir sesión con condiciones, cerrar sesión, cerrar trabajo con imagen del
campo) y la de `incidencias` siguen con `AppBar`, `TextFormField` «filled» y
`FilledButton` de ADR 0003. Esta tarea las lleva al modo campo, **solo el
aspecto**.

Cargá `verificacion` y `flujo-git-pr`. No toca `nucleo/db` ni `nucleo/sync`.

Referencias (leelas antes de escribir):

- `lib/nucleo/ui/vitrina_campo/crear_aplicacion_campo_vitrina.dart` (04) y
  `condiciones_campo_vitrina.dart` (06): lenguaje visual de los formularios
  — `CampoTextoCampo` (envuelve un `TextFormField` real: los validadores y
  las `Key`s siguen funcionando), `StatChipCampo` con alerta de fuera de
  rango, `BannerAlertaCampo`, `GridEvidenciasCampo` /
  `BotonAgregarPunteadoCampo` para la foto obligatoria, `BotonPrimarioCampo`.
  Su `dartdoc` dice qué del mockup no está en el contrato (pH, «Ráfagas»,
  dirección del viento, mezcla): eso **no** aparece en la pantalla real.
- `lib/features/auth/login_vista.dart` — patrón de pantalla real envuelta en
  `AgrocomThemeCampo.construir()`.
- `lib/features/ordenes/presentation/` tras la tarea 20, si ya está
  integrada: misma convención de encabezado y fondo.

### Piezas

1. **Apertura de sesión** (`sesion_vuelo_vista.dart`, formulario de
   apertura): condiciones (viento/temperatura/humedad), observación + firma
   cuando algo cae fuera de rango (`reglas_condiciones.dart`, sin cambiarlo),
   auxiliar, dron y hectárea inicial acumulada, con `CampoTextoCampo`. El
   fuera de rango se ve con el color semántico del catálogo, no con un rojo
   suelto.
2. **Sesión abierta y cierres**: estado de la sesión, «Reportar incidencia»,
   «Cerrar sesión» (hectáreas, acumulado final, motivo, litros) y «Cerrar
   trabajo» (litros sobrantes + foto del campo obligatoria con
   `GridEvidenciasCampo`/`BotonAgregarPunteadoCampo` en ámbar mientras
   falte). `_InfoRow` se reemplaza por átomos del catálogo.
3. **Incidencia** (`incidencia_vista.dart`): selector de tipo con
   `SelectorSegmentadoCampo` (variante desplazable si no entran), descripción
   con `CampoTextoCampo`, foto obligatoria con el mismo patrón del punto 2.
4. Los `SnackBar` de error/confirmación pueden quedar, pero con los colores
   del tema campo (que ya los resuelve `AgrocomThemeCampo.construir()`), no
   con colores sueltos.

## Cómo repartir las etapas

1: apertura de sesión. 2: sesión abierta, cierre de sesión y cierre de
trabajo. 3: incidencia y cierre. Cada etapa con sus tests en verde.

## Qué NO hacer

- No cambies `SesionBloc`, `TrabajoCubit`, `IncidenciaCubit`, sus eventos ni
  sus estados, ni ningún repositorio o tabla `drift`: es una migración visual.
  El hallazgo de «Reintentar tras error al cerrar» (deuda técnica, PR #17) no
  se arregla acá.
- No cambies ninguna `Key` existente (`apertura_*`, `cierre_*`,
  `boton_*`, `selector_tipo_incidencia`, `campo_descripcion`, `preview_foto*`,
  …). Si un test busca por tipo de widget de Material, cambialo a la `Key`
  sin cambiar lo que verifica.
- No agregues campos que el contrato no tiene (pH, ráfagas, dirección,
  mezcla del caldo).
- No uses colores, radios, opacidades ni `TextStyle` sueltos; si falta un
  átomo, va a `lib/nucleo/ui/componentes/` y al barrel.
- No uses `double` para hectáreas ni litros (invariante 9): los campos ya
  parsean a `Decimal`, no cambies eso.
- No toques la vista previa (`vitrina_campo/`), el login ni `ordenes`.

## Criterio de aceptación

`./bin/verify` devuelve 0, y además:
`grep -nE "AppBar|FilledButton|ElevatedButton|ListTile" lib/features/sesion_vuelo/presentation lib/features/incidencias/presentation`
sin resultados; las pantallas se construyen bajo
`AgrocomThemeCampo.construir()`; los tests existentes de `sesion_vuelo` e
`incidencias` pasan con el mismo criterio, y hay un test de widget nuevo que
verifica que la observación y la firma aparecen solo con una condición fuera
de rango y que «Cerrar trabajo» no se confirma sin foto (con el mismo
mecanismo que hoy, sea botón deshabilitado o validación).

## Cierre obligatorio de cada etapa

`runs/21.estado` con una palabra: `PARCIAL`, `OK` o `BLOQUEADA`. `runs/21.md`
con qué se hizo y qué falta. Al cerrar con `OK`, `runs/21.pr.md`: título en la
primera línea, cuerpo debajo.

## Commits

Por pantalla o bloque coherente, en español, imperativo, con el porqué. Sin
trailer `Co-Authored-By`.
