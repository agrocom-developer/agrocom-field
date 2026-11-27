# Permisos por flavor

Google Play y la App Store penalizan los permisos declarados y no usados y exigen un texto de propósito claro por cada permiso sensible. Cada flavor declara solo lo que ejecuta. La fuente de verdad de lo que exigen las tiendas es `docs/politicas/tiendas-y-privacidad.md` de `agrocom-api` (sección 1.7).

## Android

Los permisos propios de cada flavor viven en su source set; el manifest común (`android/app/src/main/AndroidManifest.xml`) solo declara lo compartido. Gradle fusiona el manifest del flavor sobre el común, y los plugins aportan los suyos al fusionado.

| Permiso o característica | `cliente` | `piloto` | Por qué |
| --- | --- | --- | --- |
| `INTERNET` | sí | sí | Negociar, sincronizar y subir fotos; el tráfico en claro está prohibido en release |
| `CAMERA` (+ `uses-feature camera` y `camera.autofocus` con `required=false`) | sí | sí | Fotos de perfil, terreno, avance, documentos y chat. Permiso de ejecución: se pide con el motivo explicado justo antes de abrir la cámara (`lib/nucleo/permisos`). Declarado, el intent de captura exige que esté concedido; sin cámara el dispositivo sigue instalando y elige de galería |
| `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` | no | sí | Solo el piloto comparte su última posición, durante `en_ejecucion`, y puede desactivarla; también la toma una vez, solo si pulsa el botón de auxilio o reporta una incidencia (ADR 0025). No hay ubicación en segundo plano ni servicio en primer plano. El SOS del cliente usa la ubicación del terreno del servicio y no pide permiso |
| `POST_NOTIFICATIONS` | no | sí | El piloto recibe avisos locales de solicitudes nuevas. El cliente no tiene avisos hoy |
| `uses-feature camera.flash` (`required=false`) | no | sí | Linterna de emergencia del piloto (`torch_light`); no excluye dispositivos sin flash |
| `ACCESS_NETWORK_STATE`, `VIBRATE` | `ACCESS_NETWORK_STATE` | ambos | Los aportan `connectivity_plus` y `flutter_local_notifications`; son permisos normales, sin aviso al usuario. El cliente quita `VIBRATE` |

Los dos flavors declaran `CAMERA` en el manifest común y la piden en ejecución antes de abrir la cámara; la linterna usa `CameraManager.setTorchMode`, que no la exige. Ninguno declara almacenamiento amplio ni `READ_MEDIA_*` ni `READ_EXTERNAL_STORAGE`: la galería usa el selector de fotos del sistema (Photo Picker en Android 13+ y `ACTION_GET_CONTENT` en versiones anteriores, PHPicker en iOS), que solo entrega lo que la persona elige y no pide permiso en ninguna versión.

### Cuándo se pide cada permiso (`lib/nucleo/permisos`)

Nunca al arrancar. `asegurarPermiso` explica el motivo, luego muestra el aviso del sistema; si se niega explica qué se pierde, y si el sistema ya no deja preguntar ofrece «Abrir ajustes».

| Permiso | Android | iOS | Dónde se pide |
| --- | --- | --- | --- |
| Cámara | todas las versiones (`CAMERA`) | `NSCameraUsageDescription` | Al tomar foto: perfil, terreno, avance, registro del proveedor, chat |
| Galería | no requerido (selector del sistema) | no requerido (PHPicker) | — |
| Ubicación | `ACCESS_COARSE/FINE_LOCATION` solo `piloto`; en Android 12+ la persona elige aproximada o precisa | `NSLocationWhenInUseUsageDescription` | Piloto: botón «Usar mi ubicación» del mapa de solicitudes y el servicio en ejecución. El mapa funciona sin ella. El cliente no la pide |
| Notificaciones | `POST_NOTIFICATIONS` (Android 13+, solo `piloto`) | aviso del sistema | Al activar «Nuevas solicitudes» en avisos |

En el simulador de iOS no hay cámara, así que el aviso de cámara no aparece; en el emulador de Android aparece con el emulador de cámara activo.

Los plugins `flutter_local_notifications` y `geolocator` están en el `pubspec.yaml` compartido, y sus manifests agregan `POST_NOTIFICATIONS`, `VIBRATE` y el servicio de ubicación en primer plano a los dos flavors. `android/app/src/cliente/AndroidManifest.xml` los quita con `tools:node="remove"`. Cuando el cliente reciba avisos, se retira la línea de `POST_NOTIFICATIONS` y se agrega su explicación previa.

Para ver el manifest fusionado de un flavor: `bin/probar flutter build apk --debug --flavor <flavor> -t lib/main_<flavor>.dart` y leer `build/app/intermediates/merged_manifests/<flavor>Debug/`.

`test/android/permisos_por_flavor_test.dart` falla si reaparece la ubicación (o `POST_NOTIFICATIONS`, la linterna o el servicio de ubicación) en el cliente, o si el piloto pierde los suyos.

## iOS

`ios/Runner/Info.plist` es uno solo para los dos flavors: separar un plist por flavor exige duplicar el archivo en cada configuración de build, y no se justifica mientras los textos sirvan a ambos. Además, `geolocator` enlaza CoreLocation en el binario del cliente, y Apple rechaza un binario que usa una API protegida sin su texto de propósito; por eso el texto de ubicación queda en los dos flavors, aunque el cliente nunca la pide ni muestra el aviso.

| Clave | Quién la usa | Texto |
| --- | --- | --- |
| `NSCameraUsageDescription` | ambos | Selfie de verificación, documento, fotos del terreno y del avance del servicio, y quién las ve |
| `NSPhotoLibraryUsageDescription` | ambos | Fotos que la persona elige (perfil, logo, documentos, terreno); no se lee el resto de la galería |
| `NSLocationWhenInUseUsageDescription` | `piloto` (el cliente nunca la pide) | Nombra «Agrocom Piloto»: la última ubicación se comparte con el cliente solo durante un servicio en ejecución y puede desactivarse; **debe agregar** que también se usa, solo si pulsa el botón de auxilio o reporta una incidencia, para avisar a soporte dónde está (ADR 0025, punto 15) |

No hay `UIBackgroundModes`, ubicación permanente ni micrófono. El permiso de notificaciones de iOS no lleva clave en el plist: lo pide el plugin en ejecución. Cada permiso se pide en contexto, con el motivo explicado antes del aviso del sistema (ADR 0024).
