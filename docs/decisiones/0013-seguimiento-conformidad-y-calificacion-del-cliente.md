# ADR 0013 — Seguimiento, conformidad, calificación y reporte de problemas en el flavor cliente

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

El cliente del marketplace necesita ver su servicio de punta a punta: en qué etapa está, quién lo hace, cuánto avanzó el dron, qué evidencias dejó el equipo, firmar el acta de conformidad, calificar al proveedor y, si algo salió mal, reportarlo. La fuente de verdad es `agrocom-api/docs/especificacion/marketplace.md` (§3, §4.6 a §4.8, §5.1, §8.3, §8.4, §10.1) y las políticas de calificación y de disputas. El flavor `cliente` es online-first y no tiene outbox (ADR 0009 de arquitectura).

## Decisión

### Dominio compartido (`lib/nucleo/marketplace/dominio/`)

- `HitoServicio` y `lineaDeTiempo(...)`: función pura que arma las cinco etapas que ve el cliente (solicitud, asignación, fumigación, conformidad, completado) a partir del `Servicio`, del estado en vivo y del acta. Vive en el dominio para que la misma línea de tiempo se pruebe sin widgets y la puedan usar otras superficies.
- `ActaConformidad`, `EvidenciaServicio` y `ExpedienteServicio`: espejo de `ope_actas` y `ope_evidencias`. El acta tiene tres estados (`pendiente`, `firmada`, `observada`); hectáreas y litros son `Decimal`.
- `EtiquetaCalificacion` y `CalificacionEmitida`: el catálogo cerrado de etiquetas que el cliente aplica al proveedor (puntualidad, cobertura pareja, comunicación, cuidado del entorno, orden en el lote).
- `MotivoProblema`, `ReporteProblema` y `ProblemaReportado`: los motivos son los de la política de disputas. En la interfaz se llama «reportar un problema»; del lado servidor es una disputa.
- `FallaMarketplace` (`SinConexion`, `OperacionRechazada`): lo que un repositorio online-first lanza. Las pantallas distinguen la falta de red de cualquier otro error.
- `Proveedor.fotoRef`: referencia opcional del retrato. `AvatarProveedor` la muestra y cae a las iniciales si falta o no carga.

`EstadoServicio` conserva sus cinco valores. Los estados `en_camino`, `ejecutada` y `en_disputa` de la especificación §5.1 se representan en el cliente con el estado del acta y con el problema reportado; alinear el enum es un cambio que alcanza a los tres flavors y se decide aparte.

### Repositorios del cliente

| Interfaz | Lee | Escribe |
|---|---|---|
| `SeguimientoRepositorio` | Fotogramas del dron (`Stream`) | — |
| `ConformidadRepositorio` | Acta y evidencias | La firma del acta |
| `CalificacionRepositorio` | Calificación emitida y recibidas | La calificación al proveedor, con etiquetas y comentario |
| `ProblemaRepositorio` | El problema del servicio | El reporte |

- Cada escritura es de un solo actor (el cliente) sobre un registro propio y lleva una clave de idempotencia que nace en el dispositivo al abrir la pantalla y se reutiliza en cada reintento. Hay una calificación y un problema por servicio; repetir la llamada devuelve el registro existente.
- Todas requieren red. Sin conexión lanzan `SinConexion`, la pantalla conserva lo que el cliente ya eligió y ofrece reintentar; nada queda a medias ni se encola.
- Los repositorios demo comparten `AlmacenDemoCliente`. `AlmacenDemoCliente.sinRed` simula la falta de red para ver y probar esos estados.

### Estado de pantalla

Cada pantalla tiene su `Cubit` (`SeguimientoCubit`, `HistorialCubit`, `ServicioDetalleCubit`, `ActaCubit`, `CalificarCubit`, `ReportarProblemaCubit`) con fases explícitas de carga, contenido, error y sin conexión. Cuando ya hay datos en pantalla y la red se corta, el cubit conserva lo último conocido y lo marca como desactualizado en lugar de vaciar la vista.

### Interfaz

- **Seguimiento.** Mapa a pantalla completa y hoja arrastrable. El dato protagonista son las hectáreas cubiertas; debajo, el tiempo restante y la línea de tiempo. El marcador del dron se desliza entre fotogramas durante 1,2 s (es un desplazamiento sobre el mapa, no una transición de interfaz) y con «reducir movimiento» salta.
- **Detalle.** Una sola acción principal según el estado: seguir en vivo, revisar y dar conformidad, o calificar. Reportar un problema es siempre una acción secundaria en texto, disponible mientras el servicio está en marcha o espera la conformidad.
- **Acta.** La firma pide una confirmación en una hoja porque no se puede deshacer. Las evidencias llevan su leyenda debajo de la foto, nunca encima.
- **Calificación.** Hoja inferior de dos toques (estrella y enviar); las etiquetas y el comentario aparecen después de elegir la estrella y son opcionales.
- **Historial.** Resumen de hectáreas fumigadas con un gráfico de barras de los últimos seis meses (`fl_chart`, ya adoptada en ADR 0009 de sistema visual). Las sumas son `Decimal`; se convierten a `double` solo para dibujar.
- Los botones de texto usan `PaletaCampo.acentoTexto`: el lima de marca no alcanza el contraste AA como color de texto sobre fondo claro.
- Con el texto ampliado por encima de 130 % las filas «etiqueta … valor», la grilla de evidencias y el filtro del historial pasan a una columna.

### Pruebas

- `test/nucleo/marketplace/linea_de_tiempo_test.dart`: la línea de tiempo en cada estado.
- `test/cliente/repositorios_seguimiento_calificacion_test.dart` y `test/cliente/cubits_seguimiento_calificacion_test.dart`: idempotencia, decimales exactos, falta de red y reintentos.
- `test/ui/ui_seguimiento_calificacion/flujos_test.dart`: recorridos completos contra los repositorios demo.
- `test/ui/ui_seguimiento_calificacion/goldens_test.dart`: cada pantalla principal en claro y oscuro, 360x640 y 412x915, texto al 100 % y al 200 %; los estados de carga, vacío, error, sin señal y éxito, una vez. Corren en macOS, como el resto de los goldens del repo.

## Consecuencias

- Cuando existan los repositorios de red, solo cambia `DependenciasCliente`; las pantallas y los cubits no se tocan.
- Los proveedores de la demo no tienen retrato: `fotoRef` queda en nulo y se ven las iniciales hasta que la API entregue la foto.
- Las fotos de evidencia de la demo son las imágenes de marca empaquetadas en `assets/imagenes/`.
- La demo trata como «por confirmar» al servicio completado que todavía no tiene calificación del cliente.
