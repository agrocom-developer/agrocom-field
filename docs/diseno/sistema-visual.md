# Sistema visual de Agrocom

Agrocom es un marketplace de fumigación con drones: el cliente solicita un servicio, los proveedores (pilotos propios, pilotos independientes y dueños de drones con sus auxiliares) lo ejecutan. La interfaz móvil es la fortaleza del producto y se publica en Android, iOS y iPad con tres flavors: `cliente` (online-first), `piloto` y `auxiliar` (offline en el lote).

Este documento fija el lenguaje visual común. El código vive en `lib/nucleo/ui/`; la vitrina (`lib/nucleo/ui/vitrina_campo/`, pestaña **Sistema**) lo muestra corriendo; las capturas están en `docs/diseno/capturas/`. Las decisiones de librerías están en `docs/decisiones/0009-sistema-visual-y-librerias-ui.md`.

## 1. Principios

1. **Una acción principal por pantalla.** El botón lima ocupa el ancho completo y es el elemento de mayor peso. Todo lo demás es secundario.
2. **Sin sobrecarga.** Un dato protagonista, un apoyo, una acción. Cada elemento adicional debe justificar el espacio que ocupa.
3. **El contraste es una función, no un gusto.** Cada par de color tiene un ratio medido y un test que lo vigila.
4. **El lote no tiene señal; la interfaz tampoco espera.** En piloto y auxiliar la pantalla cambia antes de que exista respuesta (datos desde `drift`, sin esqueletos). Solo el flavor cliente muestra esqueletos de carga.
5. **Movimiento con propósito.** Se anima lo que explica un cambio de estado; no se anima lo que se repite cien veces al día.
6. **Una sola voz visual.** Los tres flavors comparten tokens y componentes. El flavor cambia el modo por defecto y el tamaño táctil, no el lenguaje.

## 2. Modos y paleta

Tres modos (`ModoVisualCampo`): **claro**, **oscuro** y **campo** (alto contraste para sol directo y guantes, modo por defecto del flavor piloto). Cada pantalla lee roles de `PaletaCampo` (`context.paleta.texto`), nunca valores hexadecimales.

Ratios medidos con la fórmula WCAG 2.x de luminancia relativa (`ContrasteWcag`, vigilados en `test/nucleo/ui/paleta_campo_test.dart`).

### Modo claro

| Rol | Valor | Uso | Contraste |
|---|---|---|---|
| `fondo` | `#F5F7F2` | Fondo de pantalla | — |
| `superficie` | `#FFFFFF` | Tarjetas, hojas | — |
| `texto` | `#101A12` | Texto principal | 16,52:1 sobre fondo (AAA) |
| `textoSecundario` | `#4A5A4D` | Apoyo | 6,81:1 sobre fondo, 7,34:1 sobre superficie (AA) |
| `acento` | `#A3E635` | Relleno de la acción principal | — |
| `sobreAcento` | `#101A12` | Texto sobre el acento | 11,82:1 (AAA) |
| `acentoTexto` / `exito` | `#2B6A0A` | Acento y éxito como texto o ícono | 6,14:1 sobre fondo (AA) |
| `alerta` | `#8A5300` | Pendiente, advertencia | 5,87:1 (AA) |
| `error` | `#B42318` | Error | 6,09:1 (AA) |
| `info` | `#0B5E8A` | Información | 6,53:1 (AA) |
| `bordeFuerte` | `#7A8A7D` | Borde de campos y controles | 3,38:1 (componente, mínimo 3:1) |
| `borde` | `#DDE4D8` | Divisor decorativo | no porta información |

### Modo oscuro

| Rol | Valor | Contraste sobre `fondo` `#0E1511` |
|---|---|---|
| `texto` | `#EEF5EF` | 16,70:1 (AAA) |
| `textoSecundario` | `#A9B8AD` | 8,95:1 (AAA); 8,08:1 sobre superficie `#16201A` |
| `acentoTexto` / `exito` | `#A3E635` | 12,28:1 (AAA) |
| `sobreAcento` | `#0E1511` | 12,28:1 sobre el acento (AAA) |
| `alerta` | `#FBBF24` | 11,09:1 (AAA) |
| `error` | `#FF8A80` | 8,11:1 (AAA) |
| `info` | `#7DD3FC` | 11,11:1 (AAA) |
| `bordeFuerte` | `#7F9186` | 5,55:1 (componente) |

La elevación en oscuro se expresa subiendo la claridad de la superficie (`superficie` `#16201A` → `superficieElevada` `#1E2A22`), no con sombra.

### Modo campo (alto contraste, flavor piloto bajo sol)

Fondo `#07110A`, superficie `#0A1A0E`. Texto `#F0FDF4` (18,34:1, AAA), texto secundario `#C9D8CD` (12,97:1), lima `#A3E635` (12,74:1), alerta `#FDE68A` (15,42:1), error `#FF9A92` (9,41:1), info `#7DD3FC` (11,52:1). El texto secundario del modo campo es siempre más contrastado que el del modo oscuro (lo vigila un test). Las reglas de campo: objetivos táctiles de 56 px, sin texto por debajo de 12 px, sin información expresada solo por color y sin gris sobre gris.

### Reglas de color

- El lima es el único acento de marca. Un color semántico (éxito, alerta, error, info) nunca es el único portador del estado: lleva ícono o texto.
- Sobre fondo claro el lima solo se usa como relleno con texto oscuro; como texto se usa `acentoTexto`.
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
5. Háptica (`HapticaCampo`): `seleccion` al cambiar una selección o tomar una foto, `confirmacion` al aceptar un servicio o confirmar una apertura, un cierre o una incidencia, `alerta` en una oferta por vencer, en un error y al abrir el modo emergencia. Nunca es el único canal de feedback.
6. Ningún elemento anima en bucle salvo el esqueleto de carga y el indicador de sincronización activa.

## 8. Componentes

Catálogo `*Campo` en `lib/nucleo/ui/componentes/` (un solo import: `componentes_campo.dart`).

| Componente | Función |
|---|---|
| `OfertaServicioCampo` | Oferta entrante: pago, distancia, cuenta regresiva en anillo, aceptar y rechazar. Recibe `restante` y `total` desde el bloc; el monto llega ya formateado (nunca `double`). |
| `CalificacionCampo` | Estrellas de 1 a 5; interactiva para el cliente, de solo lectura para el proveedor. Objetivo táctil de 48 px y etiqueta accesible por estrella. |
| `EsqueletoCampo` | Marcador de carga con la forma del contenido; estático con movimiento reducido. Solo flavor cliente. |
| `NavegacionAdaptativaCampo` | Barra inferior en teléfono; riel lateral en iPad y tabletas (extendido en horizontal); contenido acotado a 720 px. |
| `BarraAccionesCampo` | Acciones ancladas al borde inferior de una pantalla del lote: principal abajo, secundaria encima, nota de apoyo opcional. Respeta el área segura. |
| `EstadoSyncCampo` | Pastilla de estado de sincronización con ícono y texto en mono: «En el dispositivo», «Sincronizando», «Sincronizado», «Sin sincronizar». |
| `GrupoStatsCampo` | Fila de `StatChipCampo` que se apila cuando el ancho no alcanza para el texto escalado. |
| Botones, tarjetas, badges, campos, listas, banners | Catálogo base (ADR 0008), modo campo. |

Los botones principales y secundarios del tema (`FilledButton`, `OutlinedButton`) están configurados por modo con el alto táctil correspondiente. `BotonPrimarioCampo` y `BotonSecundarioCampo` tienen 56 px de alto mínimo y crecen con el texto escalado; aceptan un ícono que acompaña a la etiqueta.

## 9. Patrones por pantalla clave

**Solicitar servicio (cliente).** Un paso por pantalla: dónde (mapa con pin sobre el lote), qué (cultivo, hectáreas, producto), cuándo. Barra de progreso arriba, botón lima abajo anclado sobre el teclado. Resumen con precio estimado antes de confirmar. Estado de red explícito: la solicitud requiere conexión y lo dice antes de que el usuario complete el formulario.

**Mapa de seguimiento (cliente).** Mapa a pantalla completa con una hoja inferior arrastrable (peek 30 %, expandida 70 %): estado del servicio, proveedor, calificación, ETA. El marcador del dron se interpola entre posiciones; con movimiento reducido salta a la posición nueva. Ninguna decoración sobre el mapa salvo controles de zoom y recentrado a 48 px.

**Oferta entrante (proveedor).** Se presenta como hoja modal con `OfertaServicioCampo`. Jerarquía: pago y tiempo restante arriba, detalle en medio, aceptar abajo (56 px, ancho completo), rechazar como botón secundario. Háptica `alerta` a los 10 s. Aceptar y rechazar requieren red (excepción documentada): si no hay señal, el botón muestra el estado y no se queda a medias.

**Línea de tiempo del servicio (cliente).** Cinco etapas en vertical: solicitud, asignación, fumigación, conformidad y completado. Solo la etapa en curso lleva su explicación; las demás quedan en una línea. El nodo hecho lleva una tilde, el actual un punto sobre el acento y el pendiente un anillo vacío: el estado no depende solo del color.

**Evidencias y acta (cliente).** Superficie confirmada como dato protagonista, estado del acta con ícono y texto, datos de la aplicación y grilla de evidencias con la leyenda debajo de cada foto. La acción principal es dar la conformidad, con una confirmación en hoja; reportar un problema es la acción secundaria en texto.

**Calificación (cliente).** Hoja inferior de dos toques: una estrella y enviar. Las etiquetas y el comentario aparecen después de elegir la estrella y son opcionales. Al terminar, confirmación inmediata y salida. La escribe solo el cliente; el proveedor la ve en su perfil.

**Perfil de proveedor.** Encabezado con foto, nombre, calificación promedio y cantidad de servicios; debajo, drones (con sus ciclos de batería), zonas de cobertura y reseñas recientes. Sin métricas decorativas.

**Servicios asignados (piloto).** El servicio vigente arriba y grande: estado, lote, hectáreas cubiertas con su barra de avance y la acción principal. Debajo, próximos y terminados como filas tocables de al menos 56 px. El detalle muestra el lote en el mapa, tres datos (superficie, dosis, caldo) y la acción principal anclada abajo.

**Sesión de vuelo (piloto y auxiliar).** Modo campo. Encabezado con `EstadoSyncCampo` debajo; una tarjeta por estado (sin sesión, en vuelo, cerrada, error) con su dato protagonista en `valorDestacado`; acciones en `BarraAccionesCampo`, la principal de 56 px siempre visible. Los formularios de condiciones y de cierre son hojas a casi todo el ancho con las acciones fuera del scroll. Una pausa es el cierre de la sesión con su motivo; la pantalla de sesión cerrada ofrece abrir la siguiente. Todo viene de `drift`: sin esqueleto, sin espera. Cada pantalla que escribe dice en una `NotaTecnicaCampo` que el registro quedó en el dispositivo. Detalle en ADR 0011.

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
