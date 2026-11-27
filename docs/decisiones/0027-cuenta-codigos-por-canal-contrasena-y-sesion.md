# ADR 0027 — Cuenta y acceso: códigos por canal, contraseña mínima y renovación de la sesión

**Estado:** Aceptada, revisable · **Serie:** ADR propios de `agrocom-field` · **Fecha:** 2026-11-27 · Se apoya en los ADR 0046 y 0047 de `agrocom-api` (el servidor decide y publica el contrato). **Desarrolla** los ADR 0024 (cuenta por app, recuperar el acceso) y 0025 (eliminar la cuenta) y **reemplaza** de ellos lo que dicen del código «al correo de respaldo» y de la contraseña con letras y números.

## Contexto

El servidor ya publica los códigos de 6 dígitos por WhatsApp, SMS o correo, la contraseña con mínimo de 4 caracteres sin otras reglas, `POST /api/auth/renovar`, el estado de eliminación con su gracia de 7 días y `409 cuenta_ya_registrada`. Falta decir cómo se ven en las dos apps, que comparten la misma pantalla de cuenta.

## Decisión

1. **Una sola feature compartida.** La seguridad de la cuenta vive en `nucleo/auth/cuenta/` (`domain/`, `data/`, `presentation/`) y los dos flavors la montan; `cliente/` y `piloto/` solo la enlazan desde el ingreso y el perfil. El repositorio (`CuentaSeguridadRepositorio`) es en línea y sin outbox, como el resto de los trámites de cuenta (ADR 0024, punto 6). La interfaz traduce cada respuesta del contrato a una falla propia (`CuentaFalla`): la pantalla nunca interpreta códigos HTTP.
2. **Un mismo recorrido para todos los códigos.** Recuperar el acceso, cambiar la contraseña, verificar el teléfono y confirmar la eliminación comparten `FlujoCodigoCubit`: elegir canal, recibir el código, confirmarlo. Un toque en un canal envía el código (una sola acción por pantalla). Verificar el teléfono ofrece solo WhatsApp y SMS: el correo no prueba la posesión del teléfono.
3. **Un canal caído no es culpa de la persona.** Ante `503 canal_no_disponible` el canal queda marcado como no disponible en esa pantalla, el texto lo explica («WhatsApp no está disponible por ahora; no es un problema de tu cuenta») y sugiere los otros canales, que se pueden usar de inmediato.
4. **Cuenta regresiva de reenvío.** Tras enviar un código el reenvío por el mismo canal espera 30 s; cambiar de canal no espera. Ante `429` se bloquean todos los canales y la cuenta regresiva usa los segundos de `Retry-After` (60 s si no vino): `ApiExcepcionServidor.reintentarEn` los trae del encabezado. El ingreso con `429` hace lo mismo con el botón «Ingresar».
5. **Contraseña: mínimo 4 y máximo 100 caracteres, sin reglas de composición.** La validación local (`ReglasContrasena`) es la misma del servidor; al ingresar solo se exige que no esté vacía.
6. **Teléfono verificado.** Tras registrarse (con la sesión ya abierta) se ofrece la hoja «Verifica tu teléfono», que se puede dejar para después («Más tarde»); en el piloto, es un botón en la pantalla de registro enviado. Mientras `usuario.telefono_verificado` sea falso, «Seguridad y cuenta» del perfil lo recuerda. Nada depende de que esté verificado: la identidad la prueba la aprobación (ADR 0024).
7. **«Ya tienes una cuenta».** `409 cuenta_ya_registrada` abre una pantalla que explica y ofrece iniciar sesión o recuperar el acceso, sin crear otra cuenta. Si el tipo de cuenta es el de la otra app, manda a esa app. Al iniciar sesión, un proveedor con el registro a medias continúa donde quedó según `siguiente_paso` de `GET /api/proveedores/mi` (`subir_documentos`, `en_revision`, `corregir`, `suspendido`, `baja`, `listo`); un valor que la app no conoce se ignora y manda el estado de aprobación.
8. **Renovar la sesión al desbloquear.** Tras reconocer a la persona con la biometría (ADR 0026), la app pide `GET /api/auth/sesion` y, si a `dispositivo.expira_en` le quedan 7 días o menos, `POST /api/auth/renovar` y guarda el token nuevo. Una falla no impide entrar. Un `401` cae al ingreso por el camino de siempre (el cliente HTTP avisa que la sesión venció).
9. **Eliminar la cuenta.** Pantalla con qué se borra, qué se conserva y qué lo impide (los motivos de `409 eliminacion_bloqueada` y de `GET /api/cuenta/eliminacion`, cada uno con su salida). La confirmación va en una hoja inferior, con la contraseña o con un código para quien la olvidó. El piloto sincroniza antes lo que el lote tiene sin subir (ADR 0025, punto 3). Al aceptarla el servidor revoca los tokens: la app muestra el plazo y cierra la sesión local. Si la persona vuelve a entrar durante la gracia, la sesión es restringida (`403 cuenta_en_eliminacion`) y la app muestra solo «Tu cuenta se está eliminando» con «Conservar mi cuenta» y «Cerrar sesión». Como el servidor no avisa en el login, el piloto lo detecta con `GET /api/cuenta/eliminacion` (una de las pocas rutas permitidas); el cliente, con el `403` de sus lecturas de la sesión.
10. **Permisos solo en contexto.** Ningún punto de arranque pide permisos (lo vigila `test/nucleo/permisos/permisos_en_contexto_test.dart`). La cámara se pide al tocar «Cámara» del alta del dron y al tomar la foto de perfil, con la hoja que explica para qué (`permitirCamaraConExplicacion`); la ubicación, al compartirla en un servicio; los avisos, al activarlos.

## Alternativas descartadas

- **Código solo por correo:** deja sin salida a quien no puso correo y no aprovecha WhatsApp, que es el canal principal.
- **Contar intentos de código en la app:** el servidor ya limita (5 intentos, 3 códigos por hora) y la app no replica reglas.
- **Obligar a verificar el teléfono para entrar:** el contrato lo ofrece mientras sea falso; bloquear el uso no tiene respaldo en el servidor.
- **Renovar el token en cada apertura:** sin biometría no hay un desbloqueo local que justifique una llamada extra; quien no la usa vuelve a entrar con su contraseña al vencer.

## Consecuencias

- Pantallas nuevas con los cinco estados: Recuperar acceso, Cambiar contraseña, hoja de verificación del teléfono, Seguridad y cuenta, Eliminar mi cuenta, Cuenta en eliminación y Ya tienes una cuenta. El diseño vigente está en `docs/diseno/especificacion-pantallas.md`; los goldens se generan al terminar cada pantalla.
- `nucleo/sync` y `nucleo/db` no cambian; el replay sigue verde.
- **Revisable:** los 7 días de margen de renovación y los 30 s de espera de reenvío. Hallazgos de contrato en el informe del PR: el servidor no distingue en el login una cuenta en eliminación y `siguiente_paso` no incluye «registrar el dron».
