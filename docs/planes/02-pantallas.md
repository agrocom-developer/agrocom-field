# Plan 02 · Pantallas del handoff

**Objetivo.** Llevar las 21 pantallas del handoff a Flutter, integradas con lo que ya existe, y diseñar las que faltan. Cada fase pide revisión con capturas del simulador.

**Auditoría pendiente.** El handoff exige auditar antes de editar: clasificar cada pantalla como «existe y se re-estiliza», «existe con otra estructura» o «no existe». El primer entregable de este plan es esa tabla; no se escribe una pantalla antes.

## Fases

| Fase | Pantallas | Notas |
|---|---|---|
| 1 · Acceso y registro | 01 portadas, 02 login por celular, 03 elegir rol, 04 datos personales, 05 equipo (dron) | Con el retiro del auxiliar (plan 03), «Elige tu rol» queda en Cliente y Piloto; «tu equipo» pierde la lista de auxiliares |
| 2 · Cliente | 06 inicio, 07 publicar lote, 08 detalle de solicitud, 09 comparar ofertas (ticket y post-its), 10 seguimiento, 11 chat, 12 precio final, 13 calificar | Máximo 5 rondas; el precio final es ha ejecutadas × precio acordado |
| 3 · Piloto | 14 mapa de solicitudes, 15 negociación, 16 mis ofertas | Aceptar y negociar requieren red |
| 4 · Perfiles | 17 cliente, 18 proveedor (ajustes), 19 perfil público | Selector de tema Claro, Oscuro y Campo AAA |
| 5 · Estados | 20 vacío, 21 error de envío | El mismo patrón en todas las listas y envíos |

## Pantallas que faltan por diseñar

Revisión y publicación (paso 3), dibujo del polígono, detalle de la oferta antes de aceptar, ejecución del piloto en modo campo (marcar avance y finalizar), disputa, notificaciones, historial de servicios, verificación del proveedor (en revisión o rechazado), permisos de ubicación y cámara. La pantalla «App del auxiliar» del handoff se descarta (plan 03).

## Criterio común

Los estados de cada pantalla (carga, vacío, error, sin red, éxito), textos en español con acentos, goldens y captura del simulador antes del PR.
