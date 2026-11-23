# ADR 0011 — La superficie del proveedor es una sola para `piloto` y `auxiliar`

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

En el marketplace quien recibe ofertas, tiene drones, documentos, auxiliares y calificaciones es el **proveedor**, no un rol dentro del lote. Todo proveedor opera con los dos roles: vuela como piloto y prepara la mezcla como auxiliar según el servicio. La app tiene un flavor por rol de campo (`piloto` y `auxiliar`), y los dos necesitan la misma bandeja de ofertas, el mismo perfil y la misma lista de drones. La regla 2 de ADR 0009 dice que lo que dos flavors necesitan va a `nucleo/` y no se duplica ni se importa cruzado.

## Decisión

### Dónde vive

La bandeja de ofertas, el perfil y los drones del proveedor viven en `lib/nucleo/marketplace/proveedor/`, con las tres capas de siempre por feature:

```
lib/nucleo/marketplace/proveedor/
  ofertas/   domain (OfertasRepositorio, EstadoRed) · data (demo) · presentation (OfertasCubit, bandeja, detalle)
  perfil/    domain (PerfilRepositorio) · data (demo) · presentation (PerfilCubit, perfil)
  dron/      domain (DronesRepositorio) · data (demo) · presentation (DronesCubit, lista)
  demo/      AlmacenDemoProveedor (estado en memoria del modo demo)
  di/        DependenciasProveedor (los repositorios que monta cada flavor)
```

`DependenciasPiloto` y `DependenciasAuxiliar` componen un `DependenciasProveedor` y suman lo propio de su rol (servicio asignado, mezcla). Las pruebas están en `test/nucleo/marketplace/proveedor/`.

### Navegación

- `piloto`: Ofertas, Servicio, Drones, Perfil.
- `auxiliar`: Servicio, Mezcla, Ofertas, Perfil. El trabajo del lote va primero; los drones se abren desde el perfil.

### Estado en cubits

Cada pantalla tiene su cubit (`OfertasCubit`, `PerfilCubit`, `DronesCubit`), creado por la pantalla contra la interfaz del repositorio. Las pantallas no llevan lógica: ni reloj, ni claves, ni reintentos.

`OfertasCubit` concentra lo delicado de la bandeja:

- **Cuenta regresiva** con un reloj inyectado y un pulso de un segundo. El tiempo restante se calcula contra el vencimiento que fija el servidor; el dispositivo solo lo muestra.
- **Estado de red** por la interfaz `EstadoRed`. Sin red la bandeja se sigue viendo, los botones se apagan y la tarjeta dice por qué; no se intenta la respuesta.
- **Clave de idempotencia por oferta**, generada en el dispositivo y conservada entre reintentos hasta que el servidor resuelve. Una respuesta que no llega deja la oferta en la bandeja y el reintento usa la misma clave.
- **Ofertas cerradas**: la que tomó otro proveedor y la que venció quedan a la vista como «ya la tomó otro proveedor» y «oferta vencida», sin tono de error, hasta que el proveedor las quita.

Aceptar y rechazar siguen sin pasar por el outbox (ADR 0009).

### Dominio

`Proveedor`, `Dron` y `AuxiliarAsociado` llevan su `EstadoAprobacion` (`pendiente`, `aprobado`, `suspendido`, `rechazado`), que solo cambia un administrador. `DocumentoProveedor` suma el estado `vencido` y el motivo de rechazo. `MetricasProveedor` trae servicios, hectáreas (decimal exacto) y las tasas de aceptación y cancelación como enteros de 0 a 100 calculados por el servidor. `ResumenCalificaciones` suma la cantidad por puntaje.

### Interfaz

- `OfertaServicioCampo` acepta un mapa del lote, un acceso al detalle y los estados «enviando» y «sin conexión». El título de cada oferta son las hectáreas y el cultivo; debajo, lote, zona, producto y fecha; después pago estimado y distancia.
- `ChipEstadoMarketplace` muestra cualquier estado (aprobación, documento, dron) con ícono, texto y un tono semántico. `EstadoErrorMarketplace` es el error de carga con botón de reintento.
- Toda la superficie se dibuja en modo campo: contraste AAA del texto, objetivos de 56 px, texto escalable al 200 % sin recortes.

## Consecuencias

- Un cambio en la bandeja, el perfil o los drones llega a los dos flavors a la vez, y las pruebas se escriben una sola vez.
- `lib/piloto/` y `lib/auxiliar/` quedan con lo que es propio de cada rol dentro del lote.
- Los repositorios reales del proveedor (tareas 35, 36 y 37 de la cola) se implementan en `lib/nucleo/marketplace/proveedor/<feature>/data/` y se eligen en `DependenciasProveedor`. La implementación de `EstadoRed` sobre `connectivity_plus` llega con la tarea 37.
- Si un rol necesitara una variante propia de alguna de estas pantallas, se resuelve con un parámetro de la pantalla (como `onVerDrones` en el perfil), no con una copia en el flavor.
