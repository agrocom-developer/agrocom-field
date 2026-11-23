# Firma de release

El `release` de Android se firma con una clave que nunca está en el repositorio.
`android/app/build.gradle.kts` lee cuatro valores de variables de entorno o de
propiedades de Gradle:

| Nombre | Contenido |
| --- | --- |
| `AGROCOM_KEYSTORE_FILE` | Ruta al archivo `.jks` |
| `AGROCOM_KEYSTORE_PASSWORD` | Contraseña del almacén |
| `AGROCOM_KEY_ALIAS` | Alias de la clave |
| `AGROCOM_KEY_PASSWORD` | Contraseña de la clave |

Si falta alguno, el build release queda sin firmar; nunca se firma con la
clave debug.

## Firma local

Define los valores en `~/.gradle/gradle.properties` (fuera del repo) o como
variables de entorno de la sesión, y compila:

```bash
flutter build apk --release --flavor piloto -t lib/main_piloto.dart
```

## Secrets en GitHub

1. Genera el keystore fuera del repo (`keytool -genkeypair ...`) y guárdalo en
   un gestor de contraseñas con copia de respaldo: perderlo impide actualizar
   la app publicada.
2. Codifícalo: `base64 -i agrocom.jks | pbcopy`.
3. En **Settings → Secrets and variables → Actions** crea
   `AGROCOM_KEYSTORE_BASE64`, `AGROCOM_KEYSTORE_PASSWORD`, `AGROCOM_KEY_ALIAS`
   y `AGROCOM_KEY_PASSWORD`. Para limitar el acceso, crea un *Environment*
   `release` con revisores requeridos y define allí los secrets.
4. En el workflow de release, decodifica en un archivo temporal del runner
   y exporta las variables:

   ```yaml
   - run: |
       echo "$AGROCOM_KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/agrocom.jks"
       echo "AGROCOM_KEYSTORE_FILE=$RUNNER_TEMP/agrocom.jks" >> "$GITHUB_ENV"
   ```
5. Los PR de forks no reciben secrets; el release corre solo desde `master`
   o por `workflow_dispatch`.

`*.jks` y `key.properties` están en `.gitignore`. Si una clave se filtra,
se rota con Play App Signing y se revocan los secrets.
