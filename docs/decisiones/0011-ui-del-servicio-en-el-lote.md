# ADR 0011 — Interfaz del servicio en el lote: acciones ancladas, sync visible y pausa como cierre

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

El piloto y el auxiliar usan la app en el lote: a pleno sol, con guantes, sin señal y con el dron en el aire. Las pantallas de servicio asignado y de sesión de vuelo (apertura con condiciones, en curso, cierre, cierre de trabajo, incidencias con foto, emergencia) son las que más se usan en esas condiciones. El sistema visual (`docs/diseno/sistema-visual.md`) fija los principios; este ADR fija cómo se aplican a esas pantallas y qué decisiones de presentación quedan tomadas.

## Decisión

### Acciones ancladas abajo

- Cada pantalla del lote separa contenido y acciones. El contenido se desplaza; las acciones viven en una `BarraAccionesCampo` anclada al borde inferior, sobre el área segura: la principal (lima) es la de más abajo, al alcance del pulgar, y la secundaria va encima. Ninguna acción principal queda detrás de un scroll.
- Los botones del catálogo (`BotonPrimarioCampo`, `BotonSecundarioCampo`) tienen 56 px de alto **mínimo**, no fijo: con el texto escalado al 200 % crecen. Aceptan un ícono que acompaña a la etiqueta, nunca la reemplaza.
- Los formularios (condiciones de apertura, cierre de sesión, cierre de trabajo) son hojas a casi todo el ancho de la pantalla, con los campos en scroll y las dos acciones fuera del scroll. Con el texto escalado las acciones se apilan, la principal arriba.

### Datos que no se cortan

- `GrupoStatsCampo` reparte los `StatChipCampo` en fila y los apila cuando el ancho por dato no alcanza para el texto escalado. `EncabezadoCampo` crece hacia abajo en vez de fijar su alto.
- El dato protagonista de un servicio (hectáreas cubiertas, caldo a preparar) se achica con `FittedBox` antes que cortarse.
- El dato técnico del catálogo (`StatChipCampo`, `NotaTecnicaCampo`, `BannerAlertaCampo`, `BadgeEstadoCampo`, `GridEvidenciasCampo`) usa la familia empaquetada JetBrains Mono.

### Estado de sincronización visible

- `EstadoSyncCampo` es una pastilla con ícono y texto en mono; `IndicadorSync` la alimenta con el `SyncCubit`, que `AgrocomApp` provee por encima del `Navigator`. Va bajo el encabezado de inicio, servicio, sesión e incidencia.
- La pantalla afirma solo lo que sabe. Con el motor ocioso o sin motor en el árbol muestra «En el dispositivo»: el registro está guardado localmente. Con un ciclo corriendo, «Sincronizando». Con el último ciclo fallido, «Sin sincronizar». No muestra «Sincronizado» ni un conteo de pendientes porque ninguna fuente reactiva de la interfaz lo garantiza; el conteo del outbox queda como deuda (ver Consecuencias).
- Cada pantalla que escribe lleva además una `NotaTecnicaCampo` que dice en una frase que el registro quedó en el dispositivo y se envía al haber señal.

### Háptica

- `seleccion` al elegir un tipo, tomar una foto o cambiar de estado la sesión; `confirmacion` al confirmar apertura, cierre, cierre de trabajo o una incidencia; `alerta` en un error y al abrir el modo emergencia. Siempre acompaña un cambio visible.

### La pausa de un vuelo es el cierre de la sesión

- El dominio no tiene un estado «en pausa»: un trabajo tiene varias sesiones y cada una se cierra con un motivo (clima, fin de jornada, relevo de piloto, cambio de dron, falla de equipo). Pausar es cerrar la sesión con ese motivo; retomar es abrir la siguiente sobre el mismo trabajo, con su propio `uuid_cliente` y su secuencia.
- La interfaz lo expresa sin lógica nueva: el formulario de cierre lo explica, y la pantalla de sesión cerrada ofrece «Abrir otra sesión» (secundaria) cuando el motivo no es «completado» y el trabajo sigue abierto. «Cerrar trabajo» se mantiene como acción principal de esa pantalla.
- No se agrega un estado de pausa local: sería un dato que el servidor no conoce y que dos dispositivos podrían leer distinto.

### Servicios asignados del piloto

- El destino «Servicio» del piloto es la lista de sus servicios asignados: el vigente arriba y grande (lote, estado, hectáreas cubiertas, acción principal), los próximos y los terminados como filas tocables. Cada servicio abre su detalle (lote en el mapa, superficie, dosis, caldo, producto, cliente, dron, fecha, pago) con la acción principal anclada.
- Abrir la sesión de vuelo desde un servicio usa `FabricasSesionVuelo`, provista por `DependenciasPiloto`: la pantalla de servicio no conoce los repositorios. La pantalla y los blocs de sesión, incidencia y cierre de trabajo son los de `lib/features/`.
- En el perfil demo (ADR 0010) esas factories apuntan a repositorios en memoria (`lib/piloto/demo/sesion_vuelo_demo.dart`) que aplican las mismas reglas de dominio y reflejan el avance en el almacén demo. No abren `drift` ni encolan en el outbox.

## Consecuencias

- Las pantallas del lote se verifican en 360x640 y 412x915, con el texto al 100 % y al 200 %: `test/ui/ui_servicio_lote/` exige en toda plataforma que no haya desbordes y compara goldens en macOS.
- El outbox, el esquema `drift` y los blocs no cambian. El `SyncCubit` se lee; nadie lo dispara desde la interfaz.
- Deuda: un conteo reactivo de registros pendientes del outbox y de evidencias sin subir permitiría mostrar «N pendientes» y «Sincronizado» con certeza. Requiere una lectura nueva en `nucleo/sync`, que se revisa línea por línea.
- Deuda: el flujo real de `piloto` (login, órdenes, inicio) y la superficie del marketplace (ofertas, servicios, drones, perfil) conviven como dos árboles hasta que existan los repositorios reales de servicios asignados; `FabricasSesionVuelo` es el punto donde se unen.
