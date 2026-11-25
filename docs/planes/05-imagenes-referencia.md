# Plan 05 · Imágenes de referencia

**Objetivo.** Tener fotos del servicio (dron fumigando, lotes, boquillas, pilotos) para portadas, estados vacíos y ejemplos, sin riesgo de licencia.

**Ya disponible.** `docs/design_handoff_agrocom_movil/design/assets/fotos/` tiene seis fotos de Unsplash (licencia Unsplash) y una captura satelital de demo que **no** puede ir a producción.

## Criterios

- Solo fuentes con licencia que permita uso comercial y no exija atribución en la app (Unsplash, Pexels); se anota autor y URL de cada una en `docs/diseno/imagenes.md`.
- No se descargan capturas de apps de terceros (Uber, Yango, inDrive) para usarlas: sirven como referencia de flujo, no como activo del producto.
- Fotos comprimidas, con un tamaño razonable por pantalla; en producción las fotos del servicio vienen del backend.

## Fases

1. Inventario: qué pantalla necesita qué imagen (portadas, rol, vacío, perfil).
2. Descarga de lo que falta, en una carpeta propia y con su ficha de licencia.
3. Reemplazar el mapa satelital de demo por el SDK de mapas.
