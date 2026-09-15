# Procedencia de las imágenes de `assets/imagenes/`

Registro de origen/licencia — para poder mostrarlo si alguna vez se cuestiona el uso de una imagen en el APK. Las cinco fotos de fondo las aportó el dueño el 14/9/2026 (reemplazan a las tres de Pexels de la ronda 1, que se retiraron del repo ese mismo día).

**Pendiente del dueño**: completar la columna "Fuente / licencia" de cada foto. Dos de los archivos originales (`0S3B9601`, `BI5A3485`, con sufijo `-scaled`) tienen nombre de cámara pasado por un sitio web, y los otros tres tienen nombre de descarga (`DJ4`, `Drone-DJI-Agras-T50`, `NuWay_Ag-Merch...`); mientras no se registre de dónde salieron y bajo qué licencia, no conviene publicar un APK con ellas fuera del equipo.

| Archivo | Archivo original (nombre con el que llegó) | Fuente / licencia | Uso |
|---|---|---|---|
| `fondo_dron_pulverizando.jpg` | `BI5A3485-scaled.webp` | _a completar_ | Fondo pleno del login |
| `fondo_dron_pulverizando_vertical.jpg` | `DJ4.jpg` | _a completar_ | Fondo pleno del onboarding (formato vertical) |
| `fondo_dron_agras_t50.jpg` | `Drone-DJI-Agras-T50.jpg` | _a completar_ | Franja superior de inicio |
| `fondo_dron_sobre_agua.jpg` | `0S3B9601-scaled.webp` | _a completar_ | Franja superior de vinculación de dispositivo (vitrina) |
| `fondo_equipo_dron.jpg` | `NuWay_Ag-Merch_Update-55389_-_Square.webp` | _a completar_ | Reservada: pantallas de equipos/baterías (HU-80) |
| `agrocom_logo.png` | — | Marca propia de Agrocom SRL | Logo en pantalla y origen del ícono del launcher |

Uso: fondos decorativos de pantallas del modo campo (ADR 0008) — nunca como evidencia de un trabajo real ("sin captura no cierra", invariante 8 de `CLAUDE.md`: la evidencia siempre la captura el piloto/auxiliar en el momento).

Todas convertidas a JPEG y redimensionadas a ancho máx. 1000-1200 px (Pillow, `LANCZOS`, calidad 72-78) desde el original — quedaron entre 73 y 244 KB cada una, apto para el RC de gama media/baja (mismo criterio de peso que ADR 0003). Los `.webp` no se conservan en el repo: el APK empaqueta toda la carpeta (`pubspec.yaml`, `assets/imagenes/`) y un original de 2560 px duplicaría el peso sin ganancia en pantalla.

Las rutas se leen de `ImagenesCampo` (`lib/nucleo/ui/imagenes_campo.dart`) y se pintan siempre a través de `FondoFotoCampo`, nunca con un `Image.asset` suelto por pantalla. Hoy las usa la vista previa del modo campo (`lib/nucleo/ui/vitrina_campo/`, solo `kDebugMode`); la primera pantalla real que las adopta es el login (segunda mitad de TE-15).
