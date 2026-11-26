# DESIGN.md · Agrocom Móvil

Guía de diseño viva del proyecto. Cualquier cambio de UI la consulta antes y la actualiza después. Los valores exactos están en `docs/diseno/tokens/tokens.json`, y la especificación por pantalla está en `docs/diseno/especificacion-pantallas.md`.

## 1. Producto
- Marketplace de fumigación con drones por negociación, con tres apps: cliente, piloto y auxiliar.
- Flujo: publicar lote → ofertas → hasta 5 rondas → elegir piloto → ejecución con fotos → precio final (ha ejecutadas × precio acordado) → calificación o reclamo.
- Sin cobro dentro de la app: el pago es directo entre cliente y piloto. Todos los textos van en español (Bolivia, moneda Bs) y neutro; la redacción sigue [`docs/diseno/guia-de-textos.md`](docs/diseno/guia-de-textos.md).
- Contexto de uso: en el lote, a pleno sol, muchas veces sin señal y con una mano.

## 2. Principios
1. **El número manda.** Hectáreas, Bs/ha, totales y rondas van en JetBrains Mono, grandes y alineados. Siempre que haya un precio por ha, se muestra también el total.
2. **Acciones al alcance del pulgar.** El CTA principal va abajo, con 56 de alto. La información arriba y las decisiones abajo.
3. **Un solo primario por pantalla.** Verde para la acción principal, grafito para estructura y ámbar solo para lo que pide atención.
4. **Negociar es conversar.** Las rondas se muestran como burbujas, no como tablas.
5. **Funciona sin red.** El estado de conexión es visible, y lo que se puede guardar en cola se guarda y se dice.
6. **Accesible por defecto.** Contraste AA en claro y oscuro, AAA en modo campo. Áreas táctiles de 48 como mínimo (72 en modo campo).

## 3. Color · Industrial AgTech
Regla 60 / 30 / 10:
- 60 %: fondo y superficies neutras.
- 30 %: grafito para estructura (cabeceras de ticket, filtros activos, FAB secundario).
- 10 %: verde para acciones y ámbar para alertas.

No uses fondos completamente verdes, neón ni degradados decorativos.

| Rol | Claro | Oscuro | Campo AAA |
|---|---|---|---|
| bg | #F3F5F1 | #17251C | #000000 |
| surface / surface2 | #FFFFFF / #E9EEE7 | #293832 / #34443B | #0F1A13 / #1B2A20 |
| primary (correcto) | #347A36 | #62B66A | #8EE08F |
| graphite | #29343A | #34443B | #1B2A20 |
| amber (advertencia) | #F5A623 | #FFB52E | #FFC547 |
| info | #2785C7 | #50A5D8 | #8CCBF2 |
| error | #DC4545 | #FF6868 | #FF8A8A |
| text / text2 | #202A2E / #68756D | #EDF3EC / #AAB8AC | #FFFFFF / #D7E2D9 |
| border | #DDE4DC | #405247 | #6B8272 |

Cada color de acento tiene su `container` y `onContainer` (ver tokens) para chips y avisos.

Post-it: `paper` #FFE680 → `paper2` #FFDA55, esquina `fold` #E8C13E y texto `onPaper`.

Reglas:
- Nunca escribas un HEX en un widget: siempre usa tokens semánticos.
- El texto sobre un acento va en `on*` a opacidad completa. No apagues el texto con alpha.
- `text2` claro vale `#5F6C65` (el handoff traía `#68756D`, 4,4:1 sobre `bg`): AA sobre `bg`, `surface` y `surface2`.
- Los tonos vivos de error, info y ámbar son rellenos; como texto se usa la variante `on*Container` (`error`, `info`, `alerta` de la paleta).
- En mapas: verde = lote abierto o sano, ámbar = requiere atención o vence hoy. Aplica siempre el overlay `map-dim` para que se lean los pines.

### Nombres en el código

Los tokens viven en `lib/nucleo/ui/`; una pantalla lee `context.paleta` y nunca un HEX.

| Handoff | Código |
|---|---|
| bg, surface, surface2, border | `fondo`, `superficie`, `superficie2`, `borde` (más `bordeFuerte` para controles y `superficieElevada` para modales) |
| text, text2 | `texto`, `textoSecundario` |
| primary, onPrimary, primaryContainer | `acento`, `sobreAcento`, `acentoContenedor` (`acentoTexto` y `exito` para texto o ícono) |
| graphite, onGraphite | `grafito`, `sobreGrafito` |
| amber, amberContainer | `ambar`, `ambarContenedor` (`alerta` como texto) |
| info, error | `rellenoInfo`, `rellenoError` como relleno; `info`, `error` como texto |
| paper, paper2, paperFold, onPaper | `papel`, `papel2`, `papelDoblez`, `sobrePapel` |

Archivos: `paleta_campo.dart` (roles por modo, `PaletaCampo`), `colores_campo.dart` (colores base y del modo campo), `tipografia_campo.dart` (`TipografiaCampo`), `tokens_campo.dart` (`EspaciadoCampo`, `RadioCampo`, `ObjetivoTactilCampo`, `ElevacionCampo`, `MovimientoCampo`), `tema_campo.dart` (`AgrocomThemeCampo.construir(modo:)`).

## 4. Tipografía
- **Manrope** para la UI y **JetBrains Mono** para las cifras, empaquetadas en `assets/fonts/`. Los estilos se llaman `tituloPantalla` (H1), `valorDestacado` (H2), `tituloBloque`, `tituloSeccion`, `cuerpo`, `cuerpoSecundario`, `etiqueta`, `etiquetaMono` (overline), `cifraDisplay`, `cifraGrande`, `cifraMedia` y `cifraUnidad` en `TipografiaCampo`.

| Estilo | Tamaño / peso | Extra |
|---|---|---|
| Display número (`cifraDisplay`) | Mono 56/700 | −0.04em |
| H1 | 28/800 | −0.02em, interlineado 1.1 |
| H2 | 24/800 | |
| Título de barra | 17/800 | |
| Cuerpo | 15/500 | interlineado 1.5 |
| Cuerpo chico | 14 | |
| Etiqueta | 12/700 | |
| Overline | Mono 11/700 | +0.08em, mayúsculas |
| Número en tarjeta | Mono 20–26/700 | unidad en 12–14 |

- Formato numérico: separador de miles con punto (Bs 7.680) y decimal con coma (★ 4,9).

## 5. Forma, espacio y elevación
- **Radios** (`RadioCampo`):
  - `pildora` 28 (botones);
  - `tarjeta` 24;
  - `tarjetaCompacta` 18;
  - `campo` 16 (inputs);
  - `chip` 12 (chips y filtros);
  - `hoja` 32 (hoja inferior);
  - 22–24 (avatar en cuadrado redondeado).
- **Espaciado:** 4, 8, 10, 12, 14, 16, 20, 24. Márgenes laterales de 16 y 20 para texto suelto.
- **Elevación:** una sola sombra sutil (`ElevacionCampo`), sin sombra en modo campo. Prefiere borde de 1 px más sombra suave antes que sombras grandes.

## 6. Componentes
- **Botones:** primario (primary), secundario (surface con borde), texto (primary), destructivo (texto en error), especial (FAB grafito con "+" en ámbar).
- **Chip de estado** (`ChipEstadoMarketplace`, par `contenedorDe`): ok, warn, info, err o neutro. Píldora 12/700.
- **Filtro:** activo en grafito, inactivo en surface.
- **Barra inferior:** 4 destinos por rol, con indicador tonal de 56×30 en el activo.
  - Cliente: Inicio, Lotes, Servicios, Perfil.
  - Piloto: Mapa, Ofertas, Servicios, Perfil.
- **Hoja inferior** (`HojaInferiorCampo`, `mostrarHojaInferiorCampo`): radio 32, manija de 36×4, se arrastra. Es el patrón para todo lo que va sobre el mapa.
- **Stepper ±1** (`StepperCampo`): número en mono en el centro y botones de 56.
- **Burbuja de negociación** (`BurbujaNegociacionCampo`): cliente a la izquierda (surface) y piloto a la derecha (primary). Etiqueta "R# · QUIÉN", Bs/ha y total. Barra de 5 segmentos: hecho, turno (ámbar) y pendiente.
- **Ticket de pedido** (`TicketPedidoCampo`, filas `FilaTicketCampo`): cabecera grafito con el número de pedido y el estado en ámbar, filas clave/valor y separador punteado. Se usa en comparar ofertas y en precio final.
- **Post-it de oferta** (`PostItOfertaCampo`): amarillo, esquina doblada, rotación de ±1° y badge "ELEGIDO". Recrearlo en código, nunca como imagen.
- **Collage de fotos** (`CollageFotosCampo`, fotos `FotoCollageCampo`): grid 2fr/1fr, gap 4, radio 18: foto grande, foto y bloque ámbar con dato. Las fotos llevan la hora en una etiqueta mono.
- **Hoja arrastrable** (`HojaArrastrableCampo`): la hoja inferior no modal que vive sobre el mapa; se arrastra entre el encabezado y la lista completa y se controla con un `DraggableScrollableController`.
- **Pestañas** (`PestanasCampo`): carril de superficie 2 con la opción elegida elevada y una cifra mono opcional («Activas 3»). Alto 56, 72 en campo.
- **Banner de red** (`BannerSinSenalCampo`): fondo ámbar y texto "Sin señal · …" en la parte superior.

## 7. Patrones
- **Formularios:** pasos visibles (barra de 3 segmentos), etiqueta encima del campo, campo activo con borde primary de 2 px y el total calculado justo encima del CTA.
- **Estados vacíos:** icono en contenedor de 88, título, una frase con un dato útil y un CTA.
- **Errores:** dicen qué pasó, qué se guardó y qué hacer. Distingue lo que funciona sin red de lo que necesita red.
- **Carrusel de portadas:** 3 slides con avance automático cada 3,5 s, deslizables, con puntos que se pueden tocar. Pausa al interactuar y respeta "reducir movimiento".
- **Temas:** Claro, Oscuro o Campo AAA, elegido en Ajustes y persistido. El oscuro no es una inversión: usa fondo verde noche con superficies grafito.

## 8. Iconografía e imágenes
- Una sola familia de iconos: hoy Material Icons redondeados (`Icons.*_rounded`), sin mezclar con otras. Pasar a Material Symbols Rounded de peso 500 requiere sumar la fuente variable; queda como deuda.
- Fotos reales del servicio (avance, dron, lote). En la demo se usan fotos de Unsplash, y en producción vienen del backend.
- Los mapas usan el SDK del proyecto; la captura satelital del handoff es solo de demo.

## 9. Evitar
- Aspecto de app de jardinería o infantil, exceso de amarillo, fondos verdes completos.
- Tablas para negociar, varios CTA primarios, cifras en fuente proporcional.
- HEX sueltos, sombras exageradas, iconos de estilos mezclados.

## 10. Mantenimiento
- Las cifras de negocio se escriben con `CifraCampo` o los estilos `cifra*`.
- La vitrina (pestaña **Negociar** de `VitrinaCampoPantalla`, `negociacion_campo_vitrina.dart`) muestra los componentes nuevos; sus goldens están en `test/nucleo/ui/goldens/negociacion_*.png`.
- Cada componente nuevo se agrega aquí con su nombre en código.
- Si cambia un token, se actualizan `tokens.json`, `PaletaCampo` (o el archivo de `nucleo/ui` que lo lleve), el test de contraste y esta guía en el mismo cambio.
- Registro de decisiones:
  - 2026-11-25: se adopta Industrial AgTech, que reemplaza el verde hoja #1F5F2E.
