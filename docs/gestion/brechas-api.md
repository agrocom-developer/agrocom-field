# Brechas de la API vistas desde la app

Lo que una pantalla necesita y el contrato (`agrocom-api`, `docs/api/openapi.yaml`) todavía no entrega. La app no inventa endpoints: degrada la pantalla y lo deja anotado aquí. Cada fila se elimina cuando el contrato lo cubre.

## Flavor cliente

| Falta en la API | Qué hace la app hoy |
|---|---|
| El proveedor de una solicitud (nombre, tipo, calificación, piloto, dron). `SolicitudServicio` solo trae `proveedor_id`; el nombre sale de `GET /api/solicitudes/{id}/calificaciones` y solo en servicios completados. | Muestra «Proveedor asignado» sin calificación ni dron hasta que el servicio se completa. |
| Posición del dron, hectáreas cubiertas y estela de un servicio en ejecución. | El seguimiento lee el estado real cada 10 s, ubica el dron en el centro del lote y da por cubierto el lote completo solo al ejecutarse. |
| Evidencias (fotos, registro de vuelo) y acta de un servicio para el cliente. Las rutas de acta son del lado del proveedor. | El acta se arma con la solicitud y su historial (estado, fechas, hectáreas facturadas = monto final entre tarifa); las evidencias quedan vacías. |
| Estimación sin crear una solicitud. `GET /api/solicitudes/{id}/estimacion` exige una solicitud existente. | Estimar crea un borrador; publicar usa ese mismo borrador. Los borradores abandonados quedan en el servidor y no se muestran. |
| Dosis, producto y tipo de aplicación como campos. Solo hay `producto_indicado` (texto) y `tipo_aplicacion`. | La dosis viaja dentro del texto («Glifosato 480 SL, 2 L/ha») y se lee de vuelta; el tipo de aplicación se deduce del producto. |
| Si el cliente ya calificó, en la lista de solicitudes. | Una lectura de calificaciones por cada servicio completado al cargar la lista. |
| Fecha de creación de la solicitud en la lista. | Usa el historial (detalle) o `publicada_en`. |
| Contorno del terreno cuando `geometria` es nula. | Dibuja un cuadrado de reserva centrado en la zona, con la superficie del terreno, solo para ubicarlo en el mapa. |
| Fase de la asignación (propios o terceros) y radio de búsqueda. | La búsqueda muestra la ronda de propios mientras la solicitud está en asignación. |
| Catálogo de productos y cultivos sugeridos. | Listas fijas en la app. |
| Calificaciones que el proveedor da al cliente (son privadas por diseño). | Solo se muestra el promedio y el conteo de la ficha del cliente. |
| Marcar un aviso del inicio como leído desde la tarjeta. | Descartar un aviso solo lo oculta en la sesión. |
