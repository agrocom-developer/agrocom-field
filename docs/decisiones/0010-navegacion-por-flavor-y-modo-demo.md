# ADR 0010 — Navegación por flavor, capa de datos por interfaces y modo demo

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

La interfaz es la parte del producto que más hay que ver y probar, y el backend del marketplace avanza por separado. Las tres superficies (`cliente`, `piloto`, `auxiliar`) necesitan correr completas, con datos creíbles, sin servidor, sin red y sin base local, para poder revisar el diseño en un emulador, un simulador o un iPad. Al mismo tiempo, las pantallas no pueden acoplarse a datos de ejemplo: cuando existan los repositorios reales, deben reemplazar a los de demostración sin tocar la interfaz.

## Decisión

### Navegación

- Cada flavor tiene un *shell* raíz que usa `NavegacionAdaptativaCampo` (barra inferior en teléfono, riel lateral en iPad y tabletas) y cambia de destino con estado local. Las pantallas secundarias (detalle, seguimiento, calificar) se apilan con `Navigator`.
- Destinos por flavor: `cliente` (Inicio, Solicitar, Servicios, Cuenta), `piloto` (Mapa, Ofertas, Servicio, Drones, Perfil) y `auxiliar` (Servicio, Perfil). La negociación, la ejecución del servicio, el perfil y los drones son la misma superficie del proveedor en los dos flavors (ADR 0012 y 0018).
- No se agrega `go_router`: la app no tiene enlaces profundos ni rutas por URL, y un `Navigator` con un shell cubre todos los recorridos. Se reevalúa cuando haya notificaciones que abran una pantalla concreta.

### Capa de datos

- Cada feature declara una interfaz de repositorio en `domain/` (`ServiciosClienteRepositorio`, `SolicitudRepositorio`, `SeguimientoRepositorio`, `CalificacionRepositorio`, `ConformidadRepositorio`, `ProblemaRepositorio`, `CuentaRepositorio`, `AccesoRepositorio`, `InicioClienteRepositorio`, `MercadoRepositorio`, `NegociacionRepositorio`, `MensajesRepositorio`, `AvisosRepositorio`, `EjecucionRepositorio`, `PerfilRepositorio`, `DronesRepositorio`). Las del proveedor viven en `lib/nucleo/marketplace/proveedor/` y las agrupa `DependenciasProveedor`.
- Las entidades compartidas (`Lote`, `Servicio`, `Proveedor`, `Dron`, `Oferta`, `SeguimientoVivo`, `Calificacion`) viven en `lib/nucleo/marketplace/dominio/`. Hectáreas, litros y dinero son `Decimal`; las coordenadas son `double`.
- Cada flavor agrupa sus repositorios en una clase `Dependencias<Flavor>` que los expone con `RepositoryProvider` por encima del `Navigator`. Las pantallas leen la interfaz con `context.read<…>()` y nunca conocen la implementación.
- Los repositorios demo (`*_demo.dart`) viven en `data/` de cada feature y comparten un almacén en memoria por flavor (`AlmacenDemo<Flavor>`; `AlmacenDemoProveedor`, `AlmacenNegociacionDemo` y `EjecucionDemo` para la superficie del proveedor). Los datos base (lotes con polígonos en Cuatro Cañadas, San Julián, Pailón y Colonia Okinawa, proveedores con calificaciones, ofertas, historial) están en `lib/nucleo/marketplace/demo/datos_demo.dart` y las fechas se calculan respecto del reloj para que la demo siempre se vea reciente.
- Las pantallas del proveedor leen por un cubit propio (ADR 0012). Las demás leen por `StreamEstable` / `FuturoEstable`, que crean el `Stream` o el `Future` una sola vez: un `StreamBuilder` con el `stream` armado dentro de `build` se resuscribe en cada reconstrucción.

### Modo demo

- `MODO_DEMO=true` (`--dart-define-from-file=config/env.demo.json`, archivo versionado porque no contiene secretos) hace que `main_cliente.dart`, `main_piloto.dart` y `main_auxiliar.dart` arranquen la superficie del marketplace con los repositorios demo. En `piloto` y `auxiliar` el modo demo no abre `drift`, no registra el motor de sync ni toca la red; el flujo real de campo (login, órdenes, sesión de vuelo) sigue intacto cuando el flag no está.
- Sin el flag, `cliente` abre una pantalla mínima con el pie de entorno hasta que existan los repositorios de red.
- Aceptar o rechazar una oferta sigue exigiendo red (ADR 0009): la demo lo modela con una respuesta asíncrona, clave de idempotencia por oferta y un resultado `perdida` fijo para una oferta, de modo que ese estado se pueda ver.

### Cómo correr cada flavor en demo

```
flutter run --flavor cliente  -t lib/main_cliente.dart  --dart-define-from-file=config/env.demo.json
flutter run --flavor piloto   -t lib/main_piloto.dart   --dart-define-from-file=config/env.demo.json
flutter run --flavor auxiliar -t lib/main_auxiliar.dart --dart-define-from-file=config/env.demo.json
```

## Consecuencias

- Una pantalla nueva nace contra una interfaz y su fake; cuando llega el repositorio real, solo cambia la clase `Dependencias<Flavor>`.
- `lib/features/` (anterior al marketplace) convive con las carpetas `cliente/`, `piloto/` y `auxiliar/` hasta que cada feature se migre; `test/arquitectura/importaciones_test.dart` vigila las reglas de ADR 0009 para lo que ya vive en los flavors y que `cliente` no alcance `nucleo/sync` ni `nucleo/db`, ni siquiera de forma transitiva.
- Los mapas usan teselas abiertas de OpenStreetMap por red; sin red el mapa muestra los polígonos sobre el fondo. `ConfiguracionMapa.teselas` las apaga en los tests.
- Los datos demo son ficticios. Ningún nombre ni documento corresponde a una persona real.
