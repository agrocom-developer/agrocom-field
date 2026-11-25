# Planes de `agrocom-field`

Los planes ordenan el trabajo que sigue sobre el sistema de negociación: el cliente publica con un precio por hectárea, los pilotos aceptan o contraofertan (hasta 5 rondas), el cliente elige, el piloto ejecuta y ambos califican. Cada plan tiene objetivo, alcance, fases con criterio de aceptación y riesgos. La cola ejecutable vive en [`../gestion/cola_tareas.md`](../gestion/cola_tareas.md); el panorama del producto, en [`../vision.md`](../vision.md).

| Plan | Qué resuelve | Depende de |
|---|---|---|
| [01 · Identidad visual Industrial AgTech](01-identidad-visual.md) | Tokens, temas y componentes del handoff de diseño | — |
| [02 · Pantallas del handoff](02-pantallas.md) | Las 21 pantallas y las 10 que faltan diseñar | 01 |
| [03 · Retiro del flavor `auxiliar`](03-retiro-auxiliar.md) | Dos flavors (`cliente`, `piloto`) en vez de tres | Decisión del dueño |
| [04 · Panel web admin](04-panel-admin.md) | Mismos tokens de color y fuentes en el panel | 01 |
| [05 · Imágenes de referencia](05-imagenes-referencia.md) | Fotos y capturas con licencia clara | — |
| [06 · Backend pendiente](06-backend-pendiente.md) | Lógica a la base de datos, brecha de `/api/ofertas`, división de controladores | — |

## Orden recomendado

1. **06 (bloques A y B)** corre en paralelo: solo toca `agrocom-api`.
2. **01** primero en la app: sin tokens nuevos, las pantallas se hacen dos veces.
3. **03** antes de **02** para no construir pantallas del auxiliar que luego se borran.
4. **02**, por fases (acceso, cliente, piloto, perfiles, estados).
5. **04** al terminar 01: el panel adopta los mismos valores.
6. **05** acompaña a 02: cada fase de pantallas pide sus fotos.

## Reglas comunes

- Una tarea es un PR contra `develop`; pruebas solo de lo afectado; `bin/verify` antes de commitear.
- Una pantalla no está terminada sin goldens en claro y oscuro (y campo en `piloto`) ni sin verla corriendo en un simulador.
- Lo crítico (esquema `drift`, motor de sync, tokens de sesión) se avisa en el PR y lo revisa el dueño.
