# Recorrido visual contra la API real

Dos pruebas de `integration_test/` recorren el marketplace de punta a punta en un simulador de iOS, contra la API local (no la demo), y guardan una captura por paso:

| Prueba | Recorrido |
|---|---|
| `integration_test/recorrido_cliente_test.dart` | acceso, publicar solicitud (lote, aplicación, cuándo, precio), ofertas de dos proveedores, contraofertar, elegir piloto, seguimiento (avance, ubicación, fotos), chat, precio final, calificar |
| `integration_test/recorrido_piloto_test.dart` | acceso, mapa de solicitudes abiertas, detalle, contraoferta, oferta aceptada, servicio adjudicado, marcar en ejecución, foto de avance, marcar avance, finalizar, perfil |

Cada prueba es una sola app. La otra mitad del marketplace (los pilotos que ofertan y ejecutan, o el cliente que publica y elige) actúa por la API con las cuentas demo desde `integration_test/contraparte_api.dart`. En el piloto, la cámara se reemplaza por una foto de `assets/imagenes/`, porque el simulador no tiene cámara (`componerProveedor(selectorFoto:)`).

**No corren en `bin/verify` ni en CI.** `flutter test` solo recorre `test/`, y estas pruebas necesitan la API local y un simulador. No se agregan a ningún workflow.

## Requisitos

- La API de `agrocom-api` corriendo con los datos demo (contraseña `0000`; cuentas `agro.sanrafael`, `rodrigo.suarez`, `carlos.mamani`). Cada corrida crea solicitudes nuevas en esa base.
- `config/env.local.json` con `API_BASE_URL` apuntando a la API desde el simulador (`http://localhost:8000`). El archivo es local y no entra a git; `config/env.local.json.example` es la plantilla. El texto plano solo se permite en debug.
- Un simulador de iOS encendido y el código generado (`dart run build_runner build --delete-conflicting-outputs`).

## Correrlo

```bash
tool/recorrido_visual.sh cliente <id-simulador> [carpeta]
tool/recorrido_visual.sh piloto  <id-simulador> [carpeta]
```

El script corre `flutter drive` con el flavor correspondiente y, por cada pedido de captura de la prueba, toma la imagen con `xcrun simctl io <id> screenshot`. Las PNG quedan en `carpeta` (por defecto `~/Desktop/agrocom-demo`) con nombres ordenados: `cliente_01_acceso.png`, `piloto_01_acceso.png`, etc. Un paso que falla se imprime como `PASO FALLIDO` y la prueba termina en rojo, pero las capturas de los demás pasos se conservan.

Para guardarlas en el repositorio se comprimen a JPEG (`sips -s format jpeg -s formatOptions 78 --resampleWidth 560`) en `docs/diseno/capturas/recorrido/`.

## Cuándo correrlo

Antes de abrir el PR de un cambio que toque un flujo del cliente o del piloto, y después de cambiar el contrato con la API. Complementa a las pruebas golden: estas validan cada pantalla aislada; el recorrido valida que el flujo real funciona con datos reales.

## Capturas con datos ficticios

Para los tres flavors, sin API, `tool/capturar_pantallas.sh <cliente|piloto|auxiliar> <simulador> <dispositivo> <claro|oscuro|campo>` corre `integration_test/<flavor>_capturas_test.dart` en modo demo y deja JPEG (560 px, calidad 78) en `docs/diseno/capturas/<flavor>/<dispositivo>/`. Cubre una pantalla por destino de navegación: cliente (acceso, inicio, solicitar, solicitudes, cuenta), piloto (mapa, ofertas, servicio, drones, perfil) y auxiliar (servicio, perfil). Los flujos completos con datos reales los cubre el recorrido de arriba.
