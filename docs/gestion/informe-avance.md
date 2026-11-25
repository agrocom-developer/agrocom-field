# Informe de avance de la app móvil

Estado de `agrocom-field` sobre `develop`: qué hay construido en cada flavor, qué falta, qué riesgos hay y qué debe revisar una persona. El estado fila por fila de las tareas está en [cola_tareas.md](cola_tareas.md); el alcance, en [plan_sprints.md](plan_sprints.md); las decisiones, en `docs/decisiones/`.

## Resumen

- El marketplace es por negociación: el cliente publica una solicitud con un precio por hectárea, los pilotos aceptan o contraofertan por rondas, el cliente elige y, una vez adjudicado, se ejecuta el servicio. La app no asigna ni calcula comisión; el precio final lo calcula el servidor y el pago ocurre fuera de ella.
- **Cliente** (online-first, sin outbox, ADR 0013 a 0017): arranque, presentación, ingreso, registro, inicio, solicitar (lote, aplicación, cuándo y precio), ofertas recibidas con aceptar, contraofertar y rechazar, seguimiento del servicio (avance con fotos, chat y última ubicación del piloto), precio final, calificación, reporte de un problema y cuenta.
- **Piloto** (modo campo, ADR 0012 y 0018): mapa de solicitudes abiertas con filtros, oferta y contraoferta, mis ofertas, chat y avisos de solicitudes nuevas, alta del piloto independiente, drones con fotos, perfil y la ejecución en el lote sobre `drift` (inicio, avance con fotos y cierre, con cola propia y prueba de replay).
- El sistema visual es común a los tres (`docs/diseno/sistema-visual.md`): claro y oscuro en el cliente, modo campo de alto contraste en piloto.
- Los dos flavors corren contra la API y también en modo demo con repositorios en memoria (ADR 0010).

## Auditoría de accesibilidad

`test/ui/ui_qa_accesibilidad` aplica las guías de accesibilidad de Flutter a las pestañas raíz de cada flavor, en 360x640 y 412x915, con texto al 100 % y al 200 %, en claro y oscuro (cliente) o modo campo (piloto).

| Aspecto | Criterio |
|---|---|
| Contraste | Los ratios de la paleta los vigila `test/nucleo/ui/paleta_campo_test.dart`; la guía `textContrastGuideline` pasa en las combinaciones auditadas. |
| Objetivos táctiles | `androidTapTargetGuideline` (48 dp), `iOSTapTargetGuideline` (44 pt) y `labeledTapTargetGuideline`. |
| Texto dinámico | Sin desbordes con escala 2,0. Con el tamaño máximo de accesibilidad del sistema (muy superior al 200 %) los títulos grandes parten palabras largas; conviene decidir un tope de 200 %. |
| Rendimiento | No medido: el simulador de iOS solo corre en modo depuración. Pendiente en un dispositivo real con `flutter run --profile`. |
| Animaciones | Los tokens de `MovimientoCampo` (100 a 320 ms) y la reducción de movimiento los cubren las pruebas; el esqueleto de carga y el indicador de sincronización son los únicos bucles. |
| Mapa | Las teselas abiertas de OpenStreetMap rechazan las peticiones del simulador (HTTP 400): en las capturas el mapa puede verse sin teselas. |

## Capturas

Las capturas del simulador de iOS (iPhone 17 Pro e iPad Pro 11 pulgadas) están en `docs/diseno/capturas/`. Las de piloto se retiraron porque mostraban pantallas que ya no existen; los recorridos de `integration_test/piloto_capturas_test.dart` y `auxiliar_capturas_test.dart` se reescriben para las pantallas vigentes antes de regenerarlas con `tool/capturar_pantallas.sh`. No hay emulador de Android en esta máquina.

```bash
xcrun simctl boot <id-del-simulador>
tool/capturar_pantallas.sh cliente  <id> iphone17pro claro
tool/capturar_pantallas.sh cliente  <id> iphone17pro oscuro
tool/capturar_pantallas.sh piloto   <id> iphone17pro campo
```

El script usa `flutter drive` con `integration_test/<flavor>_capturas_test.dart` y el perfil demo.

## Qué publica la API

`agrocom-api` publica el contrato de la negociación (`docs/especificacion/negociacion-contrato.md`): solicitudes, mapa de abiertas, ofertas por rondas, adjudicación, seguimiento con fotos, mensajes y ubicación, calificaciones, disputas y métricas. El catálogo de sincronización entrega los servicios adjudicados del piloto.

## Qué falta

1. **Perfil del proveedor**: documentos y hectáreas por mes; agregar un dron después del alta (ADR 0018).
2. **Android**: no hay emulador ni `adb` en esta máquina; las capturas y la auditoría visual de Android quedan pendientes.
3. **Rendimiento en dispositivo real**: fotogramas en perfil, en el control remoto del piloto y en un teléfono de gama baja.
4. **Suite `ui_pase_transversal`** de la tarea 47: goldens de estados y escalas de texto por pantalla de piloto.
5. **Canal en tiempo real del chat** (hoy consulta periódica) y proveedor de teselas propio para producción.
6. **Modo claro y oscuro en piloto**: la demo solo monta el modo campo; si el dueño quiere que sigan el sistema, es una decisión de producto.

## Riesgos

- **Negociar exige red** y compite contra otras ofertas: el flujo con red inestable (reintento, oferta no vigente, doble toque) se resuelve con `uuid_cliente` por intento y la respuesta del servidor; conviene probarlo en campo.
- **Teselas del mapa**: el servidor público de OpenStreetMap no es apto para producción.
- **La ubicación del piloto es un dato personal**: se publica solo con la pantalla del servicio abierta y se detiene al finalizar (ADR 0017 y 0018).
- **Dependencia de desarrollo**: `integration_test` (del SDK de Flutter) trae `flutter_driver`, `webdriver` y `sync_http` solo para desarrollo; no entran en la app.

## Qué debe revisar una persona

Según `CLAUDE.md`, la revisión es línea por línea y posterior a la integración:

1. **Esquema `drift` y migraciones locales** (`lib/nucleo/db/`): una migración mal escrita pierde datos de campo capturados sin señal. Las migraciones integradas están en `runs/revision-pendiente.txt`.
2. **Motor de sincronización** (`lib/nucleo/sync/`) y `EjecucionSyncEngine`: outbox, replay e idempotencia por `uuid_cliente`.
3. **Negociación con red** (`lib/nucleo/marketplace/proveedor/negociacion/`): es la excepción documentada a la regla de no esperar al servidor; su manejo de errores define si dos partes creen haber cerrado lo mismo.
4. **Decisiones de producto y de gusto**: tuteo en el cliente y voseo en el lote, modo campo sin claro y oscuro, y la estética en el emulador de Android.
