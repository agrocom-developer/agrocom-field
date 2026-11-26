# ADR 0024 — Una cuenta por app, login con tipo de cuenta y verificación de identidad desde la app

**Estado:** Aceptada, revisable · **Serie:** ADR propios de `agrocom-field` · **Desarrolla:** ADR 0021, punto 2 (el flavor fija la superficie), y **reemplaza** el acceso por roles del ADR 0018 (sección «Acceso y registro») y el selector de rol del ADR 0005. Se apoya en el ADR 0046 de `agrocom-api`, que define los tipos de cuenta, la persona única y la verificación.

## Contexto

Hasta ahora el servidor emitía el token de un **rol** (`cliente`, `proveedor`, `piloto`) y cada flavor exigía el suyo: la app `cliente` pedía `rol.name == 'cliente'`, reintentaba ante un `409` y rechazaba la cuenta ajena; la app `piloto` prefería `proveedor` y caía a `piloto`.

Son **dos apps distintas**, con dos fichas en las tiendas, y cada una admite un solo tipo de cuenta: la del cliente (dueño de terreno) y la del piloto o proveedor. Quien es cliente y quiere ser proveedor se registra de nuevo en la app del piloto, con otro usuario y otra contraseña; un proveedor no se vuelve cliente. Cualquiera puede registrarse y mirar su app, pero **nadie publica, ofrece ni acepta hasta estar aprobado**, y para ser aprobado hay que verificar que la persona existe: una selfie tomada en el momento y un documento de identidad. Una misma persona real tiene a lo sumo una cuenta de cliente y una de proveedor.

No hay apps instaladas fuera del equipo, así que el contrato de login cambia de golpe, sin compatibilidad.

## Decisión

1. **El login no lleva rol y declara la app.** `POST /api/auth/token` recibe usuario, contraseña, `uuid_dispositivo` y `app` (`cliente` o `proveedor`, según el flavor). No hay `role_id` ni `409`. La respuesta y `GET /api/auth/sesion` traen `cuenta` (con su `tipo`, su estado de aprobación, el motivo si fue rechazada o suspendida y lo que falta para aprobarla), `persona` y `verificacion`. `Sesion` reemplaza al «rol activo»: se borra el código sin uso de `nucleo/auth` (`login_service`, `rol_activo`, `rol_activo_store`, `resultado_login`, `persona_operativa_store`) y la pantalla «Elegir rol» en commits aparte.
2. **Cada app admite un solo tipo de cuenta, sin conversión ni selector.** Si la cuenta es del otro tipo, el servidor responde `403` con `codigo: tipo_de_cuenta_incorrecto` y el tipo de la cuenta, sin emitir token, y la app muestra «Esta cuenta es de proveedor: ingresa en la app Agrocom Piloto» (o la del cliente). No se ofrece activar, cambiar ni convertir nada. La app no distingue otra cosa: la cuenta es de su flavor o no entra.
3. **Registro y persona única.** El registro pide una sola vez nombres, apellidos, el documento (tipo: carnet, pasaporte o licencia de conducir, y número), celular y foto de perfil, y fecha de nacimiento al proveedor. Si esa persona ya tiene una cuenta de este tipo, el servidor responde `409 persona_ya_registrada` y la app muestra **«Ya tienes una cuenta de cliente. Inicia sesión o recupera tu acceso.»** (o «de proveedor») con los botones «Iniciar sesión» y «Recuperar mi acceso» y el texto «¿No fuiste tú? Escríbenos»; no dice nada más de la persona. Si la persona tiene una cuenta del otro tipo, el registro sigue normal: es una cuenta nueva con su propio usuario y contraseña.
4. **El estado se muestra y el servidor decide.** Mientras la cuenta no está `aprobado`, la app deja entrar y ver sus pantallas: cada acción bloqueada (publicar, aceptar y contraofertar en el cliente; ofertar, contraofertar y aceptar en el piloto) aparece deshabilitada con una explicación y un camino a la verificación, y el proveedor no aprobado no ve el mapa de solicitudes abiertas. La app **no replica** la regla: ante un `403` con `codigo: cuenta_no_aprobada` abre la pantalla de verificación con el estado que devuelve el servidor, y vuelve a leer la sesión al abrir, al volver de segundo plano y tras enviar la verificación. No hay una pantalla de espera que bloquee toda la app.
5. **Verificación desde la app, en línea.** Cada flavor tiene la pantalla de verificación de su cuenta, en pasos:
   - **Selfie**: se toma con la cámara frontal en ese momento y la app no ofrece elegirla de la galería. Se reutiliza `SelectorFoto`, que ya fija `ImageSource.camera`, con cámara frontal preferida. La selfie **no es la foto de perfil**, que sí puede salir de la galería y es otro campo de otra pantalla.
   - **Documento**: la imagen del documento declarado al registrarse (cámara o archivo).
   - Las imágenes se comprimen en el dispositivo (la selfie a menos de 300 KB; el documento, al límite que publica el servidor) y se envían por HTTPS con la hora de captura de la cámara.
   - **Siempre se piden de nuevo**, aunque la persona ya esté verificada con su otra cuenta: cada cuenta prueba que quien la maneja es la persona. No hay un «reutilizar lo que ya enviaste».
   - Estados que muestra la pantalla: sin enviar, en revisión, aprobada, rechazada con motivo y cómo reenviar, y «verificada por la oficina» cuando la cargó un administrador, con la invitación a completar la selfie y el documento.
6. **El registro y la verificación requieren red y no pasan por el outbox.** Son trámites de alta, como negociar (ADR 0016): una selfie que se encola y llega días después deja de probar que la persona estaba ahí. La excepción al principio offline se amplía en `CLAUDE.md`; lo registrado en el lote no cambia.
7. **Selfie y documento son datos sensibles del dispositivo.** No se guardan en `drift`, ni en `shared_preferences`, ni en logs, reportes de error o capturas; la copia temporal se borra al subir, se envíe bien o mal; y la app no descarga selfies ni documentos de nadie. Las otras partes ven solo la insignia «Verificado».
8. **Empresas.** Cliente y proveedor pueden cargar, de forma opcional, logo, NIT, razón social y nombre comercial. Persona natural o empresa sigue como estaba.
9. **Integrantes del equipo del servicio.** En la app `piloto`, el equipo permite anotar de forma opcional a las personas que lo forman (nombre y celular opcional) dentro del mismo formulario, sin pantalla propia. En la app `cliente`, el detalle de un servicio adjudicado muestra el equipo completo e indica quién es el piloto; antes de adjudicar no se muestra. Son datos informativos y no se guardan en `drift`.
10. **Altas de la oficina.** Una cuenta que creó un administrador entra con su clave inicial y puede estar ya aprobada; su verificación aparece como «verificada por la oficina». La app no distingue otra cosa.
11. **No se tocan `nucleo/sync` ni `nucleo/db`**: nada de esto es del lote ni se guarda localmente. El replay sigue verde.

## Alternativas descartadas

- **Una cuenta con las dos capacidades (cliente y proveedor con un solo login):** son dos apps con dos fichas; exigiría activar perfiles, mostrar selectores y una sesión que sirva a ambas superficies. Se descartó por indicación del dueño.
- **Convertir una cuenta de cliente en proveedor:** mezcla dos verificaciones y dos aprobaciones en una; el cliente se registra de nuevo en la app del piloto.
- **Conservar el selector de rol:** el flavor ya fija la superficie; el selector era para el auxiliar, que se retiró (ADR 0021).
- **Un solo flavor con modo cliente y modo piloto:** el piloto es modo campo de alto contraste y offline en un control remoto; el cliente es claro y online (ADR 0003, 0008, 0009).
- **Reutilizar la selfie y el documento de la otra cuenta:** quien conociera el documento de una persona ya verificada obtendría una cuenta verificada con solo registrarse.
- **Enviar la verificación por el outbox:** pierde el valor de la selfie en el momento y el rechazo no tiene un camino claro.
- **Elegir la selfie de la galería:** no prueba presencia.
- **Replicar en la app las reglas de aprobación** (quién puede qué según el estado): dos fuentes de verdad; el servidor ya decide y responde un `403` con motivo.
- **Bloquear toda la app hasta la aprobación:** el dueño pidió que cualquiera pueda entrar y ver las pantallas.
- **Guardar la selfie y el documento localmente para reintentos:** deja datos de identidad en el dispositivo; se reintenta tomando la foto de nuevo.

## Consecuencias

- **Revisable:** que el proveedor no aprobado no vea el mapa (la política lo oculta para no exponer terrenos ajenos a una persona sin verificar; el dueño decide si ve una versión resumida) y volver a pedir la verificación a quien ya está verificado con su otra cuenta.
- ADR 0005 queda reemplazado y el ADR 0021 se concreta en el punto 2; el ADR 0018 se actualiza en «Acceso y registro».
- `CLAUDE.md`, `docs/vision.md` y la especificación de pantallas describen este modelo.
- Hay pantallas nuevas (verificación, registro con persona y mensaje de cuenta existente, estado de la cuenta, equipo del servicio) con estados de carga, vacío, error, sin red y éxito y goldens, y cambia el perfil del proveedor. El diseño de las pantallas se hace antes de implementarlas (`DESIGN.md`).
- La cámara se pide con el motivo explicado antes del permiso del sistema.
- El contrato nuevo vive en `docs/api/openapi.yaml` de `agrocom-api` y no se edita desde aquí.
