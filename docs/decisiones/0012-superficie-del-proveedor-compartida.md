# ADR 0012 — La superficie del proveedor es una sola para `piloto` y `auxiliar`

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

En el marketplace quien negocia, tiene drones, documentos, auxiliares y calificaciones es el **proveedor**, no un rol dentro del lote. Todo proveedor opera con los dos roles: vuela como piloto y ayuda como auxiliar según el servicio. La app tiene un flavor por rol de campo (`piloto` y `auxiliar`), y los dos necesitan el mismo perfil, la misma lista de drones y la misma ejecución del servicio adjudicado. La regla 2 de ADR 0009 dice que lo que dos flavors necesitan va a `nucleo/` y no se duplica ni se importa cruzado.

## Decisión

### Dónde vive

La negociación, la ejecución, el perfil, los drones y el acceso del proveedor viven en `lib/nucleo/marketplace/proveedor/`, con las tres capas de siempre por feature:

```
lib/nucleo/marketplace/proveedor/
  negociacion/  domain · data (red y demo) · presentation (mapa, detalle, ofertar, mis ofertas, chat, avisos) · di
  ejecucion/    domain · data (drift, motor de subida, ubicación, demo) · presentation · di
  perfil/       domain (PerfilRepositorio) · data (red y demo) · presentation (PerfilCubit, perfil)
  dron/         domain (DronesRepositorio) · data (red y demo) · presentation (DronesCubit, lista)
  acceso/       domain · data (red) · presentation (ingreso, registro, puerta de acceso)
  demo/         AlmacenDemoProveedor (estado en memoria del modo demo)
  di/           DependenciasProveedor (los repositorios que monta cada flavor)
```

`DependenciasPiloto` y `DependenciasAuxiliar` componen un `DependenciasProveedor`. La app real se arma en `lib/nucleo/di/composicion_proveedor.dart` y la puerta de acceso (`AppProveedor`) decide entre el ingreso y la superficie. Las pruebas están en `test/nucleo/marketplace/proveedor/` y `test/ui/ui_negociacion_piloto/`.

### Navegación

- `piloto`: Mapa, Ofertas, Servicio, Drones, Perfil.
- `auxiliar`: Servicio, Perfil. No negocia ni comparte ubicación; los drones se abren desde el perfil.

### Estado en cubits

Cada pantalla tiene su cubit, creado por la pantalla contra la interfaz del repositorio. Las pantallas no llevan lógica: ni reloj, ni claves, ni reintentos. Los cubits de la negociación conservan la clave de idempotencia de cada intento hasta que el servidor responde (ADR 0018).

### Dominio

`Proveedor`, `Dron` y `AuxiliarAsociado` llevan su `EstadoAprobacion` (`pendiente`, `aprobado`, `suspendido`, `rechazado`), que solo cambia un administrador. `Dron` suma sus fotos con su estado de revisión. `DocumentoProveedor` suma el estado `vencido` y el motivo de rechazo. `MetricasProveedor` trae servicios, hectáreas (decimal exacto) y la tasa de cancelación como entero de 0 a 100 calculado por el servidor.

### Interfaz

- `ChipEstadoMarketplace` muestra cualquier estado (aprobación, oferta, servicio, dron) con ícono, texto y un tono semántico. `EstadoErrorMarketplace` es el error de carga con botón de reintento.
- Toda la superficie se dibuja en modo campo: contraste AAA del texto, objetivos de 56 px, texto escalable al 200 % sin recortes. La acción principal de un servicio queda anclada abajo, visible sin desplazarse.
- El perfil admite filas propias del flavor (avisos, cerrar sesión) sin copiar la pantalla.

## Consecuencias

- Un cambio en el perfil, los drones o la ejecución llega a los dos flavors a la vez, y las pruebas se escriben una sola vez.
- `lib/piloto/` y `lib/auxiliar/` quedan con la navegación y las dependencias de cada rol.
- Si un rol necesitara una variante propia de alguna de estas pantallas, se resuelve con un parámetro de la pantalla (como `onVerDrones` o `extras` en el perfil), no con una copia en el flavor.
