# ADR 0019 — Sistema visual del marketplace y librerías de interfaz

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

La interfaz móvil es la fortaleza del producto: un marketplace de fumigación con drones en tres flavors (`cliente`, `piloto`, `auxiliar`) sobre Android, iOS y iPad. El sistema visual (`docs/diseno/sistema-visual.md`) necesita un conjunto de tokens, un tema por modo y una decisión explícita sobre qué librerías de terceros se adoptan. Criterio: la mejor interfaz con la menor carga; cada dependencia paga su peso, sus riesgos de mantenimiento y su superficie de actualización, y el lote no tiene señal, así que nada depende de la red para renderizar.

## Decisión

### Tokens y tema (sin dependencias nuevas)

- `PaletaCampo` (`ThemeExtension`) con roles semánticos en tres modos: claro, oscuro y campo. Contraste WCAG verificado por test.
- `AgrocomThemeCampo.construir({modo})` genera `ColorScheme`, `TextTheme`, botones, navegación y extensiones (`TemaCampo`, `PaletaCampo`). Sin argumentos devuelve el modo campo.
- `EspaciadoCampo`, `ObjetivoTactilCampo`, `ElevacionCampo`, `MovimientoCampo` (duraciones, curvas, reducción de movimiento), `HapticaCampo` (sobre `HapticFeedback` del SDK) y `ClasePantallaCampo` (adaptativo).
- Componentes propios: esqueleto, calificación, oferta entrante, navegación adaptativa.

### Librerías evaluadas

Datos de pub.dev al 23/11/2026 (versión, publicación, puntos pub, licencia); compatibilidad con Flutter 3.47.

| Necesidad | Candidata | Datos | Decisión |
|---|---|---|---|
| Animación | `flutter_animate` 4.5.2 | Publicada 25/11/2024, 150/160, BSD-3, Flutter Favorite | **Descartada.** Sin publicación en casi dos años; las animaciones implícitas del SDK y `MovimientoCampo` cubren todos los casos del sistema. |
| Animación | `lottie` 3.8.2 | Publicada 02/11/2026, 160/160, MIT, exige Flutter >= 3.47 | **Aprobada para su uso futuro**: animaciones de estado vacío o éxito exportadas desde After Effects. No se agrega hasta que haya un asset real. |
| Animación | `rive` 0.14.11 | Publicada 03/08/2026, 140/160, MIT | **Descartada.** Runtime nativo más pesado y API aún en 0.x; Lottie cubre el caso con menos riesgo. |
| Gráficos | `fl_chart` 1.3.1 | Publicada 09/11/2026, 150/160, MIT | **Elegida** para estadísticas de proveedor y panel de cliente. Se agrega con la primera pantalla que grafique. |
| Mapas | `flutter_map` 8.3.2 | Publicada 27/08/2026, 150/160, BSD-3, solo Dart | **Elegida.** Sin llave de API ni facturación por carga de mapa, teselas intercambiables (OSM o un proveedor propio), compatible con teselas offline para el lote. Se agrega con la pantalla de seguimiento. |
| Mapas | `google_maps_flutter` 2.19.0 | Publicada 14/10/2026, 140/160, BSD-3 | **Descartada por ahora.** Exige llave y facturación por uso, y no admite teselas propias; se reevalúa si el seguimiento requiere tráfico o Street View. |
| Mapas | `mapbox_maps_flutter` 3.35.2 | Publicada 20/11/2026, 160/160 | **Descartada por ahora.** SDK nativo pesado, cuenta y token por uso, 386 likes (adopción baja). Es la alternativa si `flutter_map` no alcanza en rendimiento con muchos marcadores. |
| Hojas modales | `wolt_modal_sheet` 0.12.0 | Publicada 27/10/2026, 160/160, MIT, API 0.x | **Descartada.** `showModalBottomSheet` y `DraggableScrollableSheet` del SDK cubren la oferta entrante y el seguimiento; la API 0.x no justifica la dependencia. |
| Esqueletos | `skeletonizer` 3.0.0 | Publicada 11/09/2026, 160/160, MIT | **Descartada.** `EsqueletoCampo` (unas 100 líneas) respeta movimiento reducido y la paleta sin dependencia. |
| Esqueletos | `shimmer` 4.0.0 | Publicada 21/08/2026, 160/160 | **Descartada** por la misma razón. |
| Adaptativo | `flutter_adaptive_scaffold` 0.3.3+1 | Última publicación 06/05/2025, 140/160 | **Descartada.** Sin publicación en más de un año; `NavigationBar`, `NavigationRail` y `ClasePantallaCampo` lo resuelven. |
| Tipografía | `google_fonts` 9.0.0 | Publicada 28/09/2026, 160/160 | **Descartada.** Descarga fuentes por red; en el lote no hay red. Manrope y JetBrains Mono se empaquetan. |
| Háptica | paquetes de háptica | — | **Descartados.** `HapticFeedback` del SDK cubre selección, impacto medio y pesado en iOS y Android. |

### Política

Una librería entra cuando existe la pantalla que la usa, con su versión fijada por `pubspec.lock`. Las tres aprobadas están en `pubspec.yaml`:

| Librería | Dónde se usa |
|---|---|
| `flutter_map` (con `latlong2`) | `MapaLote` (`lib/nucleo/marketplace/ui/`): contorno del lote, estela y posición del dron |
| `fl_chart` | Hectáreas por mes en el perfil del proveedor |
| `lottie` | Reservada para animaciones de estado vacío o éxito; se usa cuando exista el primer asset exportado |

`flutter_animate` queda descartada.

## Consecuencias

- Peso: tres dependencias de interfaz (`flutter_map` con `latlong2`, `fl_chart`, `lottie`); el resto del sistema es código propio.
- Los golden tests se generan y comparan en macOS y se omiten en Linux (el render de texto difiere); la compuerta de CI sigue cubriendo los tests de comportamiento y de contraste.
- Los widgets del catálogo `*Campo` anteriores leen `ColoresCampo` (modo campo); los componentes nuevos leen `PaletaCampo` y funcionan en los tres modos. La migración del resto del catálogo a `PaletaCampo` es incremental, pantalla por pantalla.
- El proyecto `ios/` define un esquema Xcode por flavor (`piloto`, `auxiliar`, `cliente`), con identificador de paquete `com.agrocom.dronagro.<flavor>` y soporte de iPad. Las capturas de `docs/diseno/capturas/` se generan con el motor de Flutter a tamaño de iPhone 17 Pro y de iPad Pro 11 (`test/nucleo/ui/vitrina_campo/capturas_sistema_visual_test.dart`), no desde el simulador.
