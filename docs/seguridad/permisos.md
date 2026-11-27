# Permisos por flavor

Google Play y la App Store penalizan los permisos declarados y no usados y exigen un texto de propósito claro por cada permiso sensible. Cada flavor declara solo lo que ejecuta. La fuente de verdad de lo que exigen las tiendas es `docs/politicas/tiendas-y-privacidad.md` de `agrocom-api` (sección 1.7).

## Android

Los permisos propios de cada flavor viven en su source set; el manifest común (`android/app/src/main/AndroidManifest.xml`) solo declara lo compartido. Gradle fusiona el manifest del flavor sobre el común, y los plugins aportan los suyos al fusionado.

| Permiso o característica | `cliente` | `piloto` | Por qué |
| --- | --- | --- | --- |
| `INTERNET` | sí | sí | Negociar, sincronizar y subir fotos; el tráfico en claro está prohibido en release |
| `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` | no | sí | Solo el piloto comparte su última posición, durante `en_ejecucion`, y puede desactivarla; también la toma una vez, solo si pulsa el botón de auxilio o reporta una incidencia (ADR 0025). No hay ubicación en segundo plano ni servicio en primer plano. El SOS del cliente usa la ubicación del terreno del servicio y no pide permiso |
| `POST_NOTIFICATIONS` | no | sí | El piloto recibe avisos locales de solicitudes nuevas. El cliente no tiene avisos hoy |
| `uses-feature camera.flash` (`required=false`) | no | sí | Linterna de emergencia del piloto (`torch_light`); no excluye dispositivos sin flash |
| `USE_BIOMETRIC` | sí | sí | Desbloquear con huella o rostro el token ya guardado (opcional, ADR 0026); lo aporta `local_auth` |
| `ACCESS_NETWORK_STATE`, `VIBRATE` | `ACCESS_NETWORK_STATE` | ambos | Los aportan `connectivity_plus` y `flutter_local_notifications`; son permisos normales, sin aviso al usuario. El cliente quita `VIBRATE` |

Ningún flavor declara `CAMERA`: la cámara se abre con `image_picker`, que usa el intent del sistema y no la exige; la linterna usa `CameraManager.setTorchMode`, que tampoco. Ninguno declara almacenamiento amplio ni `READ_MEDIA_*`: las fotos se eligen con el selector del sistema.

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

| `NSFaceIDUsageDescription` | ambos | Desbloquear la sesión en este teléfono si la persona lo activa; la biometría no sale del teléfono (ADR 0026) |
| `UIBackgroundModes` = `remote-notification` | ambos | Reservado para el push remoto; no hace nada hasta que exista el entitlement `aps-environment` (ADR 0026, punto 5) |

`ios/Runner/PrivacyInfo.xcprivacy` es el manifiesto de privacidad de la app: sin rastreo, datos recogidos y APIs de motivo requerido. Está incluido en la fase de recursos del target `Runner`.

No hay ubicación permanente ni micrófono. El permiso de notificaciones de iOS no lleva clave en el plist: lo pide el plugin en ejecución. Cada permiso se pide en contexto, con el motivo explicado antes del aviso del sistema (`nucleo/permisos`, ADR 0024 y 0026).

## Lo que no se declara, y por qué

`SYSTEM_ALERT_WINDOW`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `ACCESS_BACKGROUND_LOCATION` y `CAMERA` quedan fuera: ningún flujo los usa y Google Play los revisa a mano. Detalle y condiciones para reabrirlos en el ADR 0026.
