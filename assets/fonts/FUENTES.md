# Procedencia de las fuentes de `assets/fonts/`

Registro de origen/licencia — mismo criterio que `assets/imagenes/FUENTES.md`.
Reabre lo que **ADR 0008** había descartado ("se descarta traer
Manrope/JetBrains Mono como paquete... costo de arranque/memoria en el RC de
gama media/baja, Android 10"): decisión consciente del dueño (14/9/2026),
sin evidencia nueva de que el RC lo soporte bien — acepta ese costo a cambio
de la tipografía real del mockup. Ver la ampliación del ADR con el detalle.

| Archivo | Fuente | Licencia | Uso |
|---|---|---|---|
| `Manrope.ttf` | [google/fonts, `ofl/manrope`](https://github.com/google/fonts/tree/main/ofl/manrope), fuente variable (eje `wght` 200-800) | SIL Open Font License 1.1 (`OFL-Manrope.txt`) | Texto humano — reemplaza la fuente de plataforma de `TipografiaCampo` |
| `JetBrainsMono.ttf` | [google/fonts, `ofl/jetbrainsmono`](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono), fuente variable (eje `wght` 100-800) | SIL Open Font License 1.1 (`OFL-JetBrainsMono.txt`) | Dato técnico — reemplaza la monoespaciada nativa del SO en `TipografiaCampo` |

Las dos son fuentes **variables** (un solo archivo cubre todos los pesos vía
el eje `wght`) — `pubspec.yaml` declara varias entradas de `weight` contra el
mismo archivo, mismo mecanismo que documenta Flutter para fuentes variables:
Skia elige la instancia correcta del eje sin necesitar un archivo por peso.

La OFL permite el uso, estudio, modificación y redistribución libres,
incluso empaquetadas en una app — la única condición relevante acá es
conservar el texto de la licencia junto con la fuente (por eso viven los
`OFL-*.txt` en esta misma carpeta) y no vender la fuente por sí sola, algo
que no aplica al empaquetarla dentro del APK.

Las familias se leen de `TipografiaCampo`
(`lib/nucleo/ui/tipografia_campo.dart`) — ningún widget declara
`fontFamily` suelto.
