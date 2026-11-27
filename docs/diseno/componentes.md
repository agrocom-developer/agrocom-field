# Componentes nuevos de `nucleo/ui` — API y ejemplos de uso

Complementa `docs/diseno/sistema-visual.md` (tokens, paleta, tipografía, motion) con la API concreta y un ejemplo de uso de cada componente agregado en la ola de sistema de diseño / íconos / motion. Todo vive en `lib/nucleo/ui/` (o `lib/nucleo/marketplace/ui/` para el mapa) y se importa con el barril `componentes_campo.dart`, salvo donde se indique. Ningún ejemplo usa un color o una medida literal: todos leen de `context.paleta` y de los tokens de `tokens_campo.dart`.

## 1. Esqueletos con forma (`esqueleto_variantes_campo.dart`)

Cuatro recortes de `EsqueletoCampo` con la silueta exacta del componente que van a reemplazar — la lista no "salta" cuando llegan los datos.

```dart
// Tarjeta de oferta entrante mientras se decide si ya hay datos.
if (cargando) const EsqueletoTarjetaOfertaCampo() else OfertaServicioCampo(...);

// Fila de una lista (perfil de proveedor, registro de la cola de sync).
ListView.separated(
  itemCount: 6,
  itemBuilder: (_, __) => const EsqueletoFilaListaCampo(),
  separatorBuilder: (_, __) => const SizedBox(height: EspaciadoCampo.m),
);

// Encabezado de perfil (proveedor, piloto elegido).
const EsqueletoPerfilCampo();

// Rectángulo a sangre del mapa mientras no hay lotes ni posición.
const EsqueletoMapaCampo(alto: 220);
```

Úsalas solo en superficies online (flavor `cliente` y superficie del proveedor) — en `piloto` el lote se lee de `drift` y ya hay contenido, nunca esqueleto.

## 2. `ListaPaginadaCampo<T>` (`lista_paginada_campo.dart`)

Lista con paginación por páginas y `pull-to-refresh`, lista para un bloc. El widget no pide datos: recibe el estado y avisa cuándo refrescar o pedir la página siguiente.

```dart
BlocBuilder<OfertasBloc, OfertasEstado>(
  builder: (context, estado) => ListaPaginadaCampo<Oferta>(
    estado: EstadoListaPaginadaCampo(
      items: estado.ofertas,
      cargandoInicial: estado.cargandoInicial,
      cargandoMas: estado.cargandoMas,
      hayMasPaginas: estado.hayMasPaginas,
      errorInicial: estado.errorInicial,
      errorPagina: estado.errorPagina,
      sinRed: estado.sinRed,
    ),
    constructorItem: (context, oferta, indice) => TarjetaOfertaResumen(oferta: oferta),
    onRefrescar: () async => context.read<OfertasBloc>().add(RefrescarOfertas()),
    onCargarMas: () => context.read<OfertasBloc>().add(PedirSiguientePagina()),
  ),
);
```

Estados cubiertos de una sola vez: carga inicial (tres `EsqueletoFilaListaCampo`), vacío, error inicial con reintentar, sin red, página siguiente (esqueleto al pie), error de página (reintentar sin perder lo ya cargado) y fin real ("no hay más resultados"). `esqueletoFila` acepta cualquiera de las variantes de la sección 1 si la fila no es un `ItemListaCampo` genérico.

## 3. Gestor de acciones

### `BotonEnvioCampo` (`boton_envio_campo.dart`)

Botón primario con el ciclo de un envío al servidor: `inactivo → enviando → éxito | error`. Nunca dos toques disparan el mismo envío (se bloquea en `enviando`/`éxito`); en `error` vuelve a un botón de contorno para reintentar, con háptica (`confirmacion`/`alerta`) en cada transición.

```dart
BlocBuilder<AceptarOfertaCubit, EstadoEnvioCampo>(
  builder: (context, estado) => BotonEnvioCampo(
    texto: 'Aceptar oferta',
    estado: estado,
    onPressed: () => context.read<AceptarOfertaCubit>().enviar(),
  ),
);
```

### `MenuAccionesCampo` (`menu_acciones_campo.dart`)

Menú ⋯ para el encabezado — agrupa lo secundario en vez de sumar botones sueltos junto al título.

```dart
AppBar(
  title: const Text('Servicio'),
  actions: [
    MenuAccionesCampo(
      acciones: [
        AccionMenuCampo(
          texto: 'Reportar un problema',
          icono: Icons.flag_outlined,
          onElegir: () => abrirReporte(context),
        ),
        AccionMenuCampo(
          texto: 'Cancelar solicitud',
          icono: Icons.cancel_outlined,
          destructiva: true,
          onElegir: puedeCancel ? () => cancelar(context) : null,
        ),
      ],
    ),
  ],
);
```

### `HojaInferiorCampo` / `mostrarHojaInferiorCampo` (`hoja_inferior_campo.dart`)

Sin cambios de API: se arrastra para cerrar (lo da `showModalBottomSheet`, `enableDrag` por defecto) y ahora el contenido va dentro de un scroll acotado al 90 % del alto de la pantalla — con el texto del sistema al 200 %, o un contenido con muchas líneas, la hoja se desplaza en vez de desbordar.

```dart
mostrarHojaInferiorCampo<void>(
  context: context,
  builder: (context) => ConfirmarCierreServicio(servicio: servicio),
);
```

### `mostrarSelectorOpcionesCampo` (`selector_opciones_hoja_campo.dart`)

Selector de una opción en una hoja — reemplaza un diálogo con radios o un menú desplegable largo.

```dart
final orden = await mostrarSelectorOpcionesCampo<OrdenOfertas>(
  context: context,
  titulo: 'Ordenar por',
  seleccionado: ordenActual,
  opciones: const [
    OpcionHojaCampo(valor: OrdenOfertas.recomendado, texto: 'Recomendado'),
    OpcionHojaCampo(valor: OrdenOfertas.precio, texto: 'Precio por hectárea'),
    OpcionHojaCampo(valor: OrdenOfertas.calificacion, texto: 'Calificación'),
  ],
);
if (orden != null) context.read<OfertasBloc>().add(CambiarOrden(orden));
```

## 4. Notas y avisos jerarquizados — `ChipNotaCampo` (`chip_nota_campo.dart`)

Cinco tonos (`informacion`, `exito`, `advertencia`, `error`, `soloLectura`), cada uno con su propio ícono — el color nunca es el único portador del estado. Dos formas: `chip` (pastilla compacta en una fila) o `banner` (franja completa, con una acción opcional a la derecha).

```dart
// Chip compacto junto a un dato.
const ChipNotaCampo(texto: 'Aprobado', tipo: TipoNotaCampo.exito);

// Banner con acción — p. ej. sin red al intentar sincronizar.
ChipNotaCampo(
  texto: 'Sin conexión. Los cambios se guardan y se envían solos.',
  tipo: TipoNotaCampo.advertencia,
  variante: VarianteNotaCampo.banner,
);

// Bloqueo de solo lectura — candado, no alarma.
const ChipNotaCampo(
  texto: 'Ya calificaste este servicio.',
  tipo: TipoNotaCampo.soloLectura,
  variante: VarianteNotaCampo.banner,
);
```

`BannerAlertaCampo` sigue existiendo para el caso puntual "sin señal" del encabezado de una pantalla del lote; `ChipNotaCampo` es la pieza general para cualquier otro aviso con jerarquía.

## 5. Transiciones de página (`transiciones_campo.dart`)

```dart
// Maestro → detalle (lista de ofertas → detalle de una oferta).
Navigator.of(context).push(TransicionesCampo.detalle<void>((context) => DetalleOfertaPantalla(oferta)));

// Pantalla completa que se apila (mapa expandido, confirmación de un paso).
Navigator.of(context).push(TransicionesCampo.modal<void>((context) => MapaCompletoPantalla()));
```

Ninguna pantalla construye su propia `PageRouteBuilder`. Las dos respetan "reducir movimiento": con la opción activada, el cambio es un fundido corto en vez de un desplazamiento.

## 6. Mapa con expansión a pantalla completa — `MapaExpandibleCampo` (`lib/nucleo/marketplace/ui/mapa_expandible_campo.dart`)

Envuelve una miniatura de `MapaLote` (no interactiva) con un toque que apila una página con el mapa completo, controles de zoom/recentrado de 48 px y un botón de cerrar. Usa `TransicionesCampo.modal`, no `Hero`: envolver un `FlutterMap` interactivo en `Hero` puede montarlo dos veces durante el vuelo (una para medir, otra para la posición final) y el `MapController` compartido dispara un `setState` en pleno build de la otra instancia — ver la nota del propio archivo.

```dart
MapaExpandibleCampo(
  lotes: [lote],
  seleccionado: lote,
  posicionDron: ultimaPosicionDelPiloto, // solo durante en_ejecucion; nunca se guarda
  altoMiniatura: 180,
);
```

No guarda ninguna posición: solo pinta lo que ya recibió (invariante de privacidad de ubicación de `CLAUDE.md`).

## 7. Íconos dedicados — `IconoAgrocom` (`icono_agrocom.dart`, ADR 0028)

Misma API que `Icon`: `color`, tamaño (`TamanoIconoCampo.chico|estandar|grande|destacado`) y `semanticLabel`. El SVG se retiñe entero con `ColorFilter` (`BlendMode.srcIn`), así que nunca hace falta declarar un segundo color dentro del archivo.

```dart
IconoAgrocom(
  IconoAgrocomId.deModeloDron(dron.modelo), // "DJI Agras T30" → dronT30
  tamano: TamanoIconoCampo.grande,
  color: context.paleta.texto,
);

const IconoAgrocom(IconoAgrocomId.hectarea, semanticLabel: '42,5 hectáreas');
```

Catálogo completo: `dronT10` … `dronT50`, `pulverizadorTanque`, `lote`, `cultivo`, `bateria`, `mandoRc`, `hectarea`, `checkEquipo`, `piloto` (distintivo de la app del piloto). Vitrina en la pestaña **Íconos** de `VitrinaCampoPantalla`. Un ícono nuevo se agrega en `assets/iconos/`, se registra en `IconoAgrocomId` y se documenta aquí.

## 8. Plantilla de notificación — `TarjetaNotificacionCampo` (`tarjeta_notificacion_campo.dart`)

Tarjeta de una notificación en la bandeja dentro de la app, y el vocabulario de estilo (ícono + color) que un canal nativo de `flutter_local_notifications` debería compartir cuando `NotificacionesRemotas` deje de ser un puerto nulo.

```dart
TarjetaNotificacionCampo(
  canal: CanalNotificacionCampo.ofertas,
  titulo: 'Nueva oferta por tu solicitud',
  cuerpo: 'Un piloto ofertó Bs 120 por hectárea',
  cuando: formatoRelativo(notificacion.creadaEn),
  leida: notificacion.leida,
  onTap: () => abrirNotificacion(notificacion),
);

// Nombre del canal nativo (Android crea un canal por tipo) — mismo texto
// que ve el usuario dentro de la app:
final nombreCanal = CanalNotificacionCampo.ofertas.nombre(AppLocalizations.of(context));
```

Canales: `ofertas`, `servicio`, `sincronizacion`, `sistema`. `EstiloCanalNotificacionCampo.de(canal)` da el ícono y el color semántico (`PaletaCampo`) de cada uno, para que la bandeja dentro de la app y el canal nativo se vean igual.

## 9. Identidad por app — `EncabezadoDeMarca`, `DistintivoRol`, `ListaDeCapacidades`

`encabezado_de_marca.dart` y `lista_de_capacidades.dart`. Una misma pieza parametrizada por `RolApp` (`piloto` o `cliente`) rotula cada app sin selector de rol (ADR 0021).

- `EncabezadoDeMarca(rol:, compacto:, sobreFoto:)`: ícono del rol, wordmark «DronAgro» y debajo el distintivo («Piloto» o «Cliente»). Encabeza la portada, el ingreso y el registro del piloto. Un lector de pantalla lo anuncia como «DronAgro, app para pilotos / clientes».
- `DistintivoRol(rol:, sobreFoto:)`: la píldora con ícono y texto; en el cliente va bajo el logo en la portada, el ingreso y el registro. Nunca depende solo del color.
- `ListaDeCapacidades(rol:, sobreFoto:)`: «Qué puedes hacer como piloto / cliente», cinco renglones con ícono; solo lo que la app hace. En el piloto va dentro de la portada (`PortadaPilotoPantalla`); en el cliente se abre desde «Qué puedes hacer» en la portada, en una hoja inferior.

## Dependencia nueva

`flutter_svg: ^2.5.1` — solo la usa `lib/nucleo/ui/componentes/icono_agrocom.dart`. Motivo y alternativas descartadas en `docs/decisiones/0028-iconos-dedicados-en-svg.md`.

## Pruebas

Cada componente de este documento tiene su prueba de widget (sin golden) en `test/nucleo/ui/`, junto al resto del catálogo.
