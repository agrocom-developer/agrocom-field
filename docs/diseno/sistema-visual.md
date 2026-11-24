# Sistema visual de Agrocom

Agrocom es un marketplace de fumigación con drones: el cliente solicita un servicio, los proveedores (pilotos, dueños de drones y sus auxiliares) ofertan y lo ejecutan. La interfaz móvil es la fortaleza del producto y se publica en Android, iOS y iPad con tres flavors: `cliente` (online-first), `piloto` y `auxiliar` (offline en el lote).

Este documento fija el lenguaje visual común. El código vive en `lib/nucleo/ui/`; la vitrina (`lib/nucleo/ui/vitrina_campo/`, pestaña **Sistema**) lo muestra corriendo; las capturas están en `docs/diseno/capturas/`. Las decisiones de librerías están en `docs/decisiones/0009-sistema-visual-y-librerias-ui.md`.

## 1. Principios

1. **Una acción principal por pantalla.** El botón verde ocupa el ancho completo y es el elemento de mayor peso. Todo lo demás es secundario.
2. **Sin sobrecarga.** Un dato protagonista, un apoyo, una acción. Cada elemento adicional debe justificar el espacio que ocupa.
3. **El contraste es una función, no un gusto.** Cada par de color tiene un ratio medido y un test que lo vigila.
4. **El lote no tiene señal; la interfaz tampoco espera.** En piloto y auxiliar la pantalla cambia antes de que exista respuesta (datos desde `drift`, sin esqueletos). Solo el flavor cliente muestra esqueletos de carga.
5. **Movimiento con propósito.** Se anima lo que explica un cambio de estado; no se anima lo que se repite cien veces al día.
6. **Una sola voz visual.** Los tres flavors comparten tokens y componentes. El flavor cambia el modo por defecto y el tamaño táctil, no el lenguaje.

## 2. Modos y paleta

Tres modos (`ModoVisualCampo`): **claro**, **oscuro** y **campo** (alto contraste para sol directo y guantes, modo por defecto del flavor piloto). Cada pantalla lee roles de `PaletaCampo` (`context.paleta.texto`), nunca valores hexadecimales.

Ratios medidos con la fórmula WCAG 2.x de luminancia relativa (`ContrasteWcag`, vigilados en `test/nucleo/ui/paleta_campo_test.dart`).

### Modo claro

Fondo crema, superficie casi blanca y un verde hoja profundo como primario.

| Rol | Valor | Uso | Contraste |
|---|---|---|---|
| `fondo` | `#F6F2E4` | Fondo de pantalla (crema) | — |
| `superficie` | `#FFFDF7` | Tarjetas, hojas | — |
| `texto` | `#15210F` | Texto principal | 14,92:1 sobre fondo, 16,43:1 sobre superficie (AAA) |
| `textoSecundario` | `#4A5240` | Apoyo | 7,29:1 sobre fondo, 8,03:1 sobre superficie (AAA) |
| `acento` (verde hoja) | `#1F5F2E` | Relleno de la acción principal | — |
| `sobreAcento` | `#FFFFFF` | Texto sobre el acento | 7,68:1 (AAA) |
| `acentoTexto` / `exito` | `#1F5F2E` | Acento y éxito como texto o ícono | 6,85:1 sobre fondo, 7,55:1 sobre superficie (AA) |
| `apoyo` (verde pasto) | `#4C8C3A` | Íconos, marcadores y gráficos; nunca texto | 3,66:1 sobre fondo, 4,03:1 sobre superficie (componente, mínimo 3:1) |
| `alerta` | `#8A5300` | Pendiente, advertencia | 5,65:1 (AA) |
| `error` | `#B42318` | Error | 5,87:1 (AA) |
| `info` | `#0B5E8A` | Información | 6,28:1 (AA) |
| `bordeFuerte` | `#7A7F68` | Borde de campos y controles | 3,70:1 sobre fondo, 4,08:1 sobre superficie (componente, mínimo 3:1) |
| `borde` | `#D9D3BC` | Divisor decorativo | no porta información |

### Modo oscuro

Verde casi negro; el primario es un verde hoja claro para que el relleno se lea.

| Rol | Valor | Contraste sobre `fondo` `#0A110B` |
|---|---|---|
| `superficie` / `superficieElevada` | `#111B13` / `#19261B` | — |
| `texto` | `#EEF5EA` | 17,20:1 (AAA); 15,87:1 sobre superficie |
| `textoSecundario` | `#A9B8A5` | 9,19:1 (AAA); 8,48:1 sobre superficie |
| `acento` / `acentoTexto` / `exito` | `#7DBE5A` | 8,55:1 (AAA) |
| `sobreAcento` | `#0A110B` | 8,55:1 sobre el acento (AAA) |
| `apoyo` (verde pasto) | `#4C8C3A` | 4,66:1 sobre fondo, 4,30:1 sobre superficie (componente) |
| `alerta` | `#FBBF24` | 11,46:1 (AAA) |
| `error` | `#FF8A80` | 8,38:1 (AAA); 7,73:1 sobre superficie |
| `info` | `#7DD3FC` | 11,47:1 (AAA) |
| `bordeFuerte` | `#7F9186` | 5,74:1 (componente) |

La elevación en oscuro se expresa subiendo la claridad de la superficie (`superficie` `#111B13` → `superficieElevada` `#19261B`), no con sombra.

### Modo campo (alto contraste AAA, flavors piloto y auxiliar bajo sol)

Fondo `#050A06`, superficie `#0A130B`, superficie elevada `#12220F`. Todo texto, acento y color semántico cumple AAA (7:1) sobre las tres superficies; lo vigila `test/nucleo/ui/paleta_campo_test.dart`.

| Rol | Valor | Sobre fondo | Sobre superficie | Sobre elevada |
|---|---|---|---|---|
| `texto` | `#F4FBF0` | 18,91:1 | 17,92:1 | 15,78:1 |
| `textoSecundario` | `#C9D8CD` | 13,48:1 | 12,77:1 | 11,25:1 |
| `acento` / `acentoTexto` / `exito` (verde hoja claro) | `#9AE06E` | 12,60:1 | 11,94:1 | — |
| `sobreAcento` | `#050A06` | 12,60:1 sobre el acento | | |
| `alerta` | `#FDE68A` | 16,02:1 | 15,18:1 | 13,37:1 |
| `error` | `#FF9A92` | 9,78:1 | 9,26:1 | 8,16:1 |
| `info` | `#7DD3FC` | 11,97:1 | 11,34:1 | 9,98:1 |
| `bordeFuerte` | `#8FA68F` | 7,62:1 | 7,22:1 | — |
| `apoyo` (verde pasto) | `#4C8C3A` | 4,86:1 | 4,61:1 | — |

El rojo de insignias (`acentoRojo` `#F87171`) mide 7,21:1 sobre el fondo. El texto secundario del modo campo es siempre más contrastado que el del modo oscuro (lo vigila un test). Las reglas de campo: objetivos táctiles de 56 px, sin texto por debajo de 12 px, sin información expresada solo por color y sin gris sobre gris.

Los colores que no son de la paleta (sombra de marcadores, atribución y fondo del mapa sin teselas, visor de fotos) son tokens de `ColoresCampo`; una pantalla no declara colores propios.

### Reglas de color

- El verde hoja es el único acento de marca; el verde pasto (`apoyo`) acompaña en íconos, marcadores y gráficos, nunca como texto. Un color semántico (éxito, alerta, error, info) nunca es el único portador del estado: lleva ícono o texto.
- En claro el relleno de la acción es el verde hoja con texto blanco; en oscuro y campo es un verde hoja claro con texto casi negro.
- Un color nuevo no entra al sistema sin ratio medido y test.

## 3. Tipografía

Dos familias empaquetadas (SIL OFL 1.1, ver `assets/fonts/FUENTES.md`): **Manrope** para texto humano y **JetBrains Mono** para dato técnico (etiquetas, cronómetros, estados de sincronización). Sin dependencia de red para fuentes: en el lote no hay conexión.

| Rol Material | Estilo del dominio | Tamaño / peso |
|---|---|---|
| `displaySmall` | `tituloHero` | 38 / 800 |
| `headlineMedium` | `tituloPantalla` | 28 / 800 |
| `headlineSmall` | `valorDestacado` | 24 / 800 |
| `titleLarge` | `tituloSeccion` | 18 / 700 |
| `titleMedium` | `tituloTarjeta` | 14 / 700 |
| `bodyLarge` | `cuerpo` | 16 / 400 |
| `bodyMedium` | `cuerpoSecundario` | 14 / 400 |
| `labelSmall` | `etiquetaMono` | 10 / 500, en mayúscula, espaciado 1,2 |

El texto respeta el factor de escala del sistema operativo. Ninguna pantalla fija alturas que corten texto escalado al 200 %.

## 4. Espaciado y forma

- Escala de 4 px: `xs` 4, `s` 8, `m` 12, `l` 16, `xl` 24, `xxl` 32, `xxxl` 48 (`EspaciadoCampo`).
- Margen lateral: 16 px en teléfono, 24 px en tableta.
- Radios: botón 14 (16 en modo campo), tarjeta chica 18, tarjeta grande 24, oferta entrante 28, pill 999.
- Objetivo táctil mínimo: 48 px; 56 px en flavors de campo (`ObjetivoTactilCampo`).

## 5. Elevación

Cuatro niveles (`ElevacionCampo`): 0 plano, 1 tarjeta, 2 oferta y menú, 3 modal. En claro, sombra suave de baja opacidad (6 %, 10 %, 16 %); en oscuro y campo, superficie más clara. Un borde de 1 px (`borde`) acompaña siempre a una tarjeta para que no dependa de la sombra.

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

**Perfil de proveedor.** Encabezado con nombre, tipo, calificación promedio y cantidad de servicios; estado de aprobación con chip semántico y lo que significa para operar; aviso si un documento pide atención. Debajo, cuatro métricas operativas (servicios, hectáreas, aceptación y cancelación), hectáreas por mes, documentos con su estado, el equipo (auxiliares asociados), zonas de cobertura y calificaciones recibidas con su distribución. Sin métricas decorativas.

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
- [ ] Objetivos táctiles de 48 px (56 px en piloto y auxiliar).
- [ ] Verificada en claro, oscuro y campo.
- [ ] Verificada con texto al 200 % sin cortes ni desbordes.
- [ ] Verificada en iPhone, Android compacto e iPad vertical y horizontal.
- [ ] Con movimiento reducido no hay desplazamientos ni bucles.
- [ ] Ninguna animación supera 300 ms salvo entrada de pantalla u hoja.
- [ ] Cada ícono sin texto tiene etiqueta accesible; el estado nunca depende solo del color.
- [ ] Estados cubiertos: cargando (esqueleto en cliente), vacío, error, sin conexión.
- [ ] En piloto y auxiliar lee de `drift` y escribe en el outbox; no espera a la red.
- [ ] Dinero y hectáreas en tipo decimal exacto; nunca `double`.
- [ ] Tiene test de widget y, si es un componente, golden test.
