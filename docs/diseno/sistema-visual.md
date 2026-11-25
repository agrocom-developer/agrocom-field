# Sistema visual de Agrocom

Agrocom es un marketplace de fumigación con drones: el cliente solicita un servicio, los proveedores (pilotos y dueños de drones) ofertan y lo ejecutan. La interfaz móvil es la fortaleza del producto y se publica en Android, iOS y iPad con dos flavors: `cliente` (online-first) y `piloto` (offline en el lote).

Este documento fija el lenguaje visual común. El código vive en `lib/nucleo/ui/`; la vitrina (`lib/nucleo/ui/vitrina_campo/`, pestaña **Sistema**) lo muestra corriendo; las capturas están en `docs/diseno/capturas/`. Las decisiones de librerías están en `docs/decisiones/0009-sistema-visual-y-librerias-ui.md`.

## 1. Principios

1. **Una acción principal por pantalla.** El botón verde ocupa el ancho completo y es el elemento de mayor peso. Todo lo demás es secundario.
2. **Sin sobrecarga.** Un dato protagonista, un apoyo, una acción. Cada elemento adicional debe justificar el espacio que ocupa.
3. **El contraste es una función, no un gusto.** Cada par de color tiene un ratio medido y un test que lo vigila.
4. **El lote no tiene señal; la interfaz tampoco espera.** En piloto la pantalla cambia antes de que exista respuesta (datos desde `drift`, sin esqueletos). Solo el flavor cliente muestra esqueletos de carga.
5. **Movimiento con propósito.** Se anima lo que explica un cambio de estado; no se anima lo que se repite cien veces al día.
6. **Una sola voz visual.** Los dos flavors comparten tokens y componentes. El flavor cambia el modo por defecto y el tamaño táctil, no el lenguaje.

## 2. Modos y paleta

Paleta Industrial AgTech: verde agrícola `#347A36` para la acción, grafito `#29343A` para la estructura y ámbar `#F5A623` solo para lo que pide atención (regla 60 / 30 / 10). La fuente de los valores es `docs/diseno/tokens/tokens.json`; el código los lleva a `PaletaCampo` y `ColoresCampo`. Tres modos (`ModoVisualCampo`): **claro**, **oscuro** y **campo** (alto contraste AAA para sol directo y guantes, modo por defecto del flavor piloto). Cada pantalla lee roles de `PaletaCampo` (`context.paleta.texto`), nunca valores hexadecimales.

Ratios medidos con la fórmula WCAG 2.x de luminancia relativa (`ContrasteWcag`, vigilados en `test/nucleo/ui/paleta_campo_test.dart`).

### Roles

| Rol | Claro | Oscuro | Campo | Uso |
|---|---|---|---|---|
| `fondo` | `#F3F5F1` | `#17251C` | `#000000` | Fondo de pantalla |
| `superficie` | `#FFFFFF` | `#293832` | `#0F1A13` | Tarjetas, hojas |
| `superficieElevada` | `#FFFFFF` | `#34443B` | `#1B2A20` | Modal, oferta entrante, menú |
| `superficie2` | `#E9EEE7` | `#34443B` | `#1B2A20` | Chips, filtros inactivos, bloques internos |
| `texto` | `#202A2E` | `#EDF3EC` | `#FFFFFF` | Texto principal (AAA) |
| `textoSecundario` | `#5F6C65` | `#AAB8AC` | `#D7E2D9` | Apoyo (AA en las tres superficies; AAA en campo) |
| `acento` | `#347A36` | `#62B66A` | `#8EE08F` | Relleno de la acción principal |
| `sobreAcento` | `#FFFFFF` | `#0F1F12` | `#000000` | Texto sobre el acento |
| `acentoTexto` / `exito` | `#347A36` | `#6BBE73` | `#8EE08F` | Acento y éxito como texto o ícono |
| `grafito` / `sobreGrafito` | `#29343A` / `#FFFFFF` | `#34443B` / `#EDF3EC` | `#1B2A20` / `#FFFFFF` | Cabecera de ticket, filtro activo, FAB secundario |
| `ambar` / `sobreAmbar` | `#F5A623` / `#29343A` | `#FFB52E` / `#17251C` | `#FFC547` / `#000000` | Relleno de atención (banner sin señal, turno); no es color de texto |
| `alerta` | `#7A4B00` | `#FFB52E` | `#FFC547` | Advertencia como texto o ícono |
| `error` | `#A12727` | `#FF8080` | `#FF9494` | Error como texto o ícono |
| `info` | `#14577F` | `#5BADDF` | `#8CCBF2` | Información como texto o ícono |
| `rellenoError`, `rellenoInfo` | `#DC4545`, `#2785C7` | `#FF6868`, `#50A5D8` | `#FF9494`, `#8CCBF2` | Relleno vivo (pin, botón destructivo); no es color de texto |
| `borde` | `#DDE4DC` | `#405247` | `#2C4034` | Divisor decorativo |
| `bordeFuerte` | `#7A877D` | `#8A9C90` | `#6B8272` | Borde de campos y controles (3:1) |
| `apoyo` | `#4C8C3A` | `#62B66A` | `#8EE08F` | Íconos, marcadores y gráficos; nunca texto |

Cada acento tiene su par tonal para chips y avisos (`acentoContenedor`, `ambarContenedor`, `infoContenedor`, `errorContenedor`, cada uno con su `sobre*Contenedor`); `PaletaCampo.contenedorDe(rol)` devuelve el par de un rol. El post-it de oferta usa `papel`, `papel2`, `papelDoblez` y `sobrePapel`.

Medidas que sostienen la tabla:

- `texto` sobre `fondo` claro: 13,37:1; `textoSecundario` claro: 5,01:1 sobre `fondo`, 5,50:1 sobre `superficie` y 4,67:1 sobre `superficie2`. El valor del handoff `#68756D` medía 4,40:1 sobre `#F3F5F1`; se oscureció a `#5F6C65` y no se limita a superficies blancas.
- En claro, el verde de acento mide 4,81:1 sobre `fondo` y 5,27:1 sobre `superficie`; el texto blanco sobre el acento, 5,27:1.
- Los colores de texto semánticos de claro son las variantes oscuras del handoff (`onErrorContainer`, `onInfoContainer`, `onAmberContainer`): 6,75:1 o más sobre `fondo`. Los tonos vivos del handoff miden menos de 4,5:1 como texto y solo se usan como relleno.
- En oscuro, el verde de texto (`#6BBE73`) llega a 4,54:1 incluso sobre `superficieElevada`; el relleno `#62B66A` no.
- En campo todo texto, acento y color semántico cumple AAA (7:1) sobre fondo, superficie, superficie elevada y `superficie2`.
- El modo campo supera el contraste del oscuro en texto secundario (lo vigila un test).

La elevación en oscuro y campo se expresa subiendo la claridad de la superficie. Los colores que no son de la paleta (sombra de marcadores, atribución y fondo del mapa sin teselas, visor de fotos) son tokens de `ColoresCampo`; una pantalla no declara colores propios (lo vigila `test/nucleo/ui/tokens_sin_sueltos_test.dart`).

### Reglas de color

- El verde agrícola es el único acento de marca; el verde pasto (`apoyo`) acompaña en íconos, marcadores y gráficos, nunca como texto. Un color semántico nunca es el único portador del estado: lleva ícono o texto.
- En claro el relleno de la acción es el verde con texto blanco; en oscuro y campo, un verde claro con texto casi negro.
- El texto sobre un acento usa su `sobre*` a opacidad completa; no se apaga con alpha.
- Sin fondos completamente verdes, neón ni degradados decorativos. En mapas: verde para lote abierto o sano, ámbar para lo que requiere atención.
- Un color nuevo no entra al sistema sin ratio medido y test.

## 3. Tipografía

Dos familias empaquetadas (SIL OFL 1.1, ver `assets/fonts/FUENTES.md`): **Manrope** para texto humano y **JetBrains Mono** para toda cifra (hectáreas, Bs/ha, totales, rondas, calificación) y para el dato técnico. Sin dependencia de red para fuentes: en el lote no hay conexión. Los estilos viven en `TipografiaCampo`.

| Rol Material | Estilo del dominio | Tamaño / peso |
|---|---|---|
| `displaySmall` | `tituloHero` | 38 / 800 |
| `headlineMedium` | `tituloPantalla` (h1) | 28 / 800, interlineado 1,1, −0,02 em |
| `headlineSmall` | `valorDestacado` (h2) | 24 / 800, −0,02 em |
| — | `tituloBloque` (h3) | 22 / 800 |
| `titleLarge` | `tituloSeccion` (título de barra) | 17 / 800 |
| `titleMedium` | `tituloTarjeta` | 14 / 700 |
| `bodyLarge` | `cuerpo` | 15 / 500, interlineado 1,5 |
| `bodyMedium` | `cuerpoSecundario` | 14 / 500, interlineado 1,45 |
| `titleSmall` | `etiqueta` | 12 / 700 |
| `labelSmall` | `etiquetaMono` (overline) | mono 11 / 700, +0,08 em, mayúscula |
| — | `cifraDisplay` | mono 56 / 700, −0,04 em |
| — | `cifraGrande`, `cifraMedia`, `cifraUnidad` | mono 26, 20 y 12 / 700 |

Formato numérico: miles con punto (Bs 7.680) y decimal con coma (4,9). El texto respeta el factor de escala del sistema operativo; ninguna pantalla fija alturas que corten texto escalado al 200 %.

## 4. Espaciado y forma

- Escala de 4 px: `xs` 4, `s` 8, `m` 12, `l` 16, `xl` 24, `xxl` 32, `xxxl` 48 (`EspaciadoCampo`).
- Margen lateral: 16 px en teléfono, 24 px en tableta.
- Radios (`RadioCampo`): `xs` 6, `chip` 12, `media` 14, `campo` 16, `tarjetaCompacta` 18, `tarjeta` 24, `pildora` 28 (botones), `hoja` 32 (hoja inferior), `capsula` 999 (insignias). Ninguna pantalla declara un radio propio.
- Objetivo táctil (`ObjetivoTactilCampo`): 48 px mínimo, 56 px de alto de botón en campo y 72 px para los controles propios del modo campo.

## 5. Elevación

Una sola sombra sutil (`ElevacionCampo`): en claro `0 1 2 / 6 %` más `0 4 14 / 7 %`; en oscuro la misma geometría con 30 % y 25 %; en campo ninguna, el borde de 1 px (`borde`) separa las superficies. Los niveles 2 (oferta, menú) y 3 (modal) escalan esa misma sombra. Un borde de 1 px acompaña a una tarjeta para que no dependa de la sombra.

## 6. Iconografía

Material Symbols redondeados (`Icons.*_rounded` y `_outlined` para el estado inactivo), 24 px por defecto, 28 px en barras de calificación. El estado activo cambia de contorno a relleno. Un ícono solo, sin texto, lleva `tooltip` o `Semantics.label`. El isotipo de Agrocom se usa únicamente como marca (launcher, encabezado de sesión).

## 7. Motion

Tokens en `MovimientoCampo`.

| Token | Duración | Uso |
|---|---|---|
| `toque` | 100 ms | Escala del botón presionado (0,97), ripple |
| `rapida` | 160 ms | Estrella que se llena, cambio de segmento, insignia |
| `media` | 240 ms | Cambio de tamaño, aparición de banner |
| `lenta` | 320 ms | Entrada de pantalla u hoja modal |
| `esqueleto` | 1400 ms | Ciclo del barrido del esqueleto |

Curvas: `entrada` `cubic(0.23, 1, 0.32, 1)` para lo que aparece; `salida` `cubic(0.4, 0, 1, 1)` para lo que se va; `movimiento` `cubic(0.77, 0, 0.175, 1)` para lo que ya está en pantalla y se desplaza.

Reglas:

1. Una interacción de interfaz dura menos de 300 ms. Lo que el usuario dispara cien veces al día (pestañas, aceptar un registro del lote) no se anima o dura 100 ms.
2. Nada aparece desde escala 0: las entradas parten de 0,95 con opacidad.
3. Solo se animan `transform` y `opacity`; no se animan dimensiones de layout en listas largas.
4. **Reducción de movimiento.** Con "Reducir movimiento" (iOS) o "Quitar animaciones" (Android), `MovimientoCampo.duracion(context, d)` devuelve `Duration.zero`: los desplazamientos, escalas y el barrido del esqueleto se detienen. La opacidad y el color pueden seguir cambiando: reducir no es eliminar el feedback.
5. Háptica (`HapticaCampo`): `seleccion` al cambiar una selección o tomar una foto, `confirmacion` al aceptar una oferta o confirmar un cierre o una incidencia, `alerta` en una oferta por vencer y en un error. Nunca es el único canal de feedback.
6. Ningún elemento anima en bucle salvo el esqueleto de carga y el indicador de sincronización activa. Con movimiento reducido los dos quedan quietos.

## 8. Componentes

Catálogo `*Campo` en `lib/nucleo/ui/componentes/` (un solo import: `componentes_campo.dart`).

| Componente | Función |
|---|---|
| `OfertaServicioCampo` | Oferta entrante: cuenta regresiva en anillo, título, mapa del lote opcional, pago, distancia, aceptar y rechazar, con los estados «enviando» y «sin conexión». Recibe `restante` y `total` desde el bloc; el monto llega ya formateado (nunca `double`). |
| `ChipEstadoMarketplace` | Estado en una píldora (aprobación, documento, dron): ícono, texto y tono semántico. En `lib/nucleo/marketplace/ui/`. |
| `EstadoErrorMarketplace` | Error de carga con botón de reintento. En `lib/nucleo/marketplace/ui/`. |
| `CalificacionCampo` | Estrellas de 1 a 5; interactiva para el cliente, de solo lectura para el proveedor. Objetivo táctil de 48 px y etiqueta accesible por estrella. |
| `EsqueletoCampo` | Marcador de carga con la forma del contenido; estático con movimiento reducido. Solo en lecturas en línea: flavor cliente y superficie del proveedor (ofertas, perfil, drones). |
| `NavegacionAdaptativaCampo` | Barra inferior en teléfono; riel lateral en iPad y tabletas (extendido en horizontal); contenido acotado a 720 px. |
| `BarraAccionesCampo` | Acciones ancladas al borde inferior de una pantalla del lote: principal abajo, secundaria encima, nota de apoyo opcional. Respeta el área segura. |
| `EstadoSyncCampo` | Pastilla de estado de sincronización con ícono y texto en mono: «En el dispositivo», «Sincronizando», «Sincronizado», «Sin sincronizar». |
| `GrupoStatsCampo` | Fila de `StatChipCampo` que se apila cuando el ancho no alcanza para el texto escalado. |
| Botones, tarjetas, badges, campos, listas, banners | Catálogo base (ADR 0008), modo campo. |

Los botones principales y secundarios del tema (`FilledButton`, `OutlinedButton`) están configurados por modo con el alto táctil correspondiente. `BotonPrimarioCampo` y `BotonSecundarioCampo` tienen 56 px de alto mínimo y crecen con el texto escalado; aceptan un ícono que acompaña a la etiqueta.

## 9. Patrones por pantalla clave

**Solicitar fumigación (cliente).** Cuatro pasos, uno por pantalla: lote, aplicación, cuándo y precio. Barra de progreso de cuatro segmentos arriba y un único botón verde abajo, anclado sobre el teclado. El paso nuevo entra desde el lado hacia el que se avanza (`media`, 240 ms).

- *Lote.* El mapa ocupa la mitad superior y es el protagonista: un toque elige un lote guardado o marca una esquina del contorno; cada esquina se arrastra (objetivo de 56 px) y la superficie se lee en grande sobre el mapa. Sin doble toque para acercar: el toque responde al instante y el zoom es por pellizco. Debajo, un selector «Mis lotes / Dibujar» y la lista o la guía de dibujo.
- *Aplicación.* Hectáreas editables (propuestas desde el lote o el contorno), cultivo, producto y dosis. Las opciones son pastillas con tilde y borde de acento cuando están elegidas.
- *Cuándo.* Tira horizontal de fechas a partir de mañana y tres franjas horarias. Una fecha cercana se marca como urgente para los pilotos; no lleva recargo.
- *Precio.* El cliente propone el precio por hectárea; la superficie total es el dato protagonista (`tituloHero`) y debajo van el total estimado y el resumen de lo que se publica. El precio no es una tarifa: los pilotos lo aceptan o contraofertan. La app no cobra: el texto dice que el pago se hace fuera de ella. Un solo botón publica.
- *Estados.* Esqueleto al cargar, vacío que lleva a dibujar, error con reintento, y sin conexión al enviar: el aviso aparece arriba del resumen, el formulario queda intacto y el botón pasa a «Reintentar envío».
- *iPad horizontal.* Panel dividido: el mapa fijo a la izquierda en los cuatro pasos y el formulario en una columna de 420 px a la derecha (`NavegacionAdaptativaCampo.anchoCompleto`).

**Ofertas recibidas (cliente).** Lista de las ofertas de una solicitud, cada una con el nombre del piloto, su calificación, el precio por hectárea, el dron, la distancia y el vencimiento. Aceptar es la acción principal de la oferta vigente; contraofertar y rechazar son secundarias. Solo se habilita lo que el servidor permite según el autor y el estado de la oferta. Sin ofertas, el estado vacío explica que los pilotos las verán en el mapa y que el cliente recibirá un aviso.

**Mapa de seguimiento (cliente).** Mapa a pantalla completa con una hoja inferior arrastrable (peek 30 %, expandida 70 %): estado del servicio, piloto, calificación y avance. Un punto marca la última ubicación del piloto, sin estela; con movimiento reducido salta a la posición nueva. Ninguna decoración sobre el mapa salvo controles de zoom y recentrado a 48 px.

**Oferta en el mapa (proveedor).** Cada solicitud abierta es un marcador con el precio por hectárea escrito; el detalle muestra hectáreas, cultivo, producto, fecha y distancia. Jerarquía: precio propuesto como título; aceptarlo o contraofertar abajo (56 px, ancho completo). En «Mis ofertas» se ordena por quién tiene el turno. La oferta que ya no está vigente y la solicitud ya adjudicada quedan a la vista con un texto neutro, sin color de error. Ofertar y responder requieren red: si no hay señal, el botón muestra el estado y no se queda a medias.

**Línea de tiempo del servicio (cliente).** Seis puntos en vertical: publicada, ofertas, piloto elegido, fumigación, precio final y calificación. Solo el punto en curso lleva su explicación; los demás quedan en una línea. El nodo hecho lleva una tilde, el actual un punto sobre el acento y el pendiente un anillo vacío: el estado no depende solo del color.

**Evidencias y acta (cliente).** Superficie confirmada como dato protagonista, estado del acta con ícono y texto, datos de la aplicación y grilla de evidencias con la leyenda debajo de cada foto. La acción principal es dar la conformidad, con una confirmación en hoja; reportar un problema es la acción secundaria en texto.

**Calificación (cliente).** Hoja inferior de dos toques: una estrella y enviar. Las etiquetas y el comentario aparecen después de elegir la estrella y son opcionales. Al terminar, confirmación inmediata y salida. La escribe solo el cliente; el proveedor la ve en su perfil.

**Perfil de proveedor.** Encabezado con nombre, tipo, calificación promedio y cantidad de servicios; estado de aprobación con chip semántico y lo que significa para operar; aviso si un documento pide atención. Debajo, cuatro métricas operativas (servicios, hectáreas, aceptación y cancelación), hectáreas por mes, documentos con su estado, zonas de cobertura y calificaciones recibidas con su distribución. Sin métricas decorativas.

**Mis drones (proveedor).** Una tarjeta por dron: modelo, matrícula, propiedad y tanque; estado con chip; ciclos de batería con barra y los ciclos que quedan. Desde tres cuartos de vida útil la barra pasa a ámbar y el texto pide planificar el recambio. Primero se listan los drones que piden atención.

**Servicio adjudicado (piloto).** El servicio vigente arriba y grande: estado, lote, hectáreas y precio acordado, con la acción principal anclada abajo. Debajo, los próximos y los terminados como filas tocables de al menos 56 px. Lo que se hace en el lote es subir fotos de avance, marcar el progreso y cerrar; todo se lee de `drift` y el registro queda en el dispositivo hasta que hay señal (ADR 0018).


**Incidencia con foto.** Tipo en un selector segmentado, descripción opcional y la foto obligatoria con el hueco en ámbar mientras falte. «Guardar incidencia» anclado abajo, habilitado recién con tipo y foto.

## 10. Reglas por plataforma

**Android.** Material 3, transiciones de página por defecto del SDK, gesto de atrás predictivo, ripple. Barra de navegación inferior de 80 px. Notificaciones con canal propio por tipo (ofertas, estado de servicio).

**iOS.** Scroll con rebote, retroceso por borde, hojas modales con grabber y esquinas de 28 px, texto dinámico respetado. Háptica de selección en los cambios de segmento. Áreas seguras (isla dinámica, indicador de inicio) respetadas con `SafeArea`; ningún control primario debajo de 34 px del borde inferior.

**iPad.** Navegación en riel lateral (`NavigationRail`), extendido con etiquetas en horizontal (>= 840 px). Contenido de lectura acotado a 720 px y centrado. Maestro-detalle en dos paneles para servicios y perfil en horizontal. Soporte de Split View: el layout responde al ancho real de la ventana, no al del dispositivo. Clases de ancho: compacto < 600, medio < 840, expandido >= 840 (`ClasePantallaCampo`).

## 11. Checklist de "pantalla excelente"

- [ ] Tiene una sola acción principal, visible sin scroll.
- [ ] Lee roles de `PaletaCampo`; no hay hexadecimales ni `Colors.*` sueltos.
- [ ] Todo texto cumple AA (4,5:1); el texto de apoyo no baja de ese umbral.
- [ ] Bordes e íconos funcionales cumplen 3:1.
- [ ] Objetivos táctiles de 48 px (56 px de alto de botón en piloto y auxiliar; 72 px en controles de campo).
- [ ] Verificada en claro, oscuro y campo.
- [ ] Verificada con texto al 200 % sin cortes ni desbordes.
- [ ] Verificada en iPhone, Android compacto e iPad vertical y horizontal.
- [ ] Con movimiento reducido no hay desplazamientos ni bucles.
- [ ] Ninguna animación supera 300 ms salvo entrada de pantalla u hoja.
- [ ] Cada ícono sin texto tiene etiqueta accesible; el estado nunca depende solo del color.
- [ ] Estados cubiertos: cargando (esqueleto en cliente), vacío, error, sin conexión.
- [ ] En piloto lee de `drift` y escribe en el outbox; no espera a la red.
- [ ] Dinero y hectáreas en tipo decimal exacto; nunca `double`.
- [ ] Tiene test de widget y, si es un componente, golden test.
