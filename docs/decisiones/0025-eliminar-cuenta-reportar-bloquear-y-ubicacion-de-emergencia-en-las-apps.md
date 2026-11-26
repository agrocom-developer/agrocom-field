# ADR 0025 — Eliminar mi cuenta, reportar y bloquear, ubicación de emergencia y textos de permisos en las apps

**Estado:** Aceptada, revisable (pendiente de revisión legal) · **Serie:** ADR propios de `agrocom-field` · **Fecha:** 2026-11-27 · **Decide:** el dueño: «si son restricción de las tiendas, nos tenemos que ajustar a ellas» · Se apoya en el ADR 0047 de `agrocom-api` (decisión y motivos), en `docs/politicas/tiendas-y-privacidad.md` de ese repo (requisitos de Google Play y App Store, fuente de verdad) y en `docs/politicas/eliminacion_de_cuenta.md`. **Complementa** los ADR 0017 (seguimiento y chat), 0018 (piloto) y 0024 (cuenta por app y verificación), y **corrige** la regla de ubicación de `CLAUDE.md`.

## Contexto

Las dos tiendas exigen a toda app con cuentas: eliminar la cuenta desde la app, un chat con reporte y bloqueo, textos de permisos claros y una política de privacidad coherente con lo que la app recoge. El servidor ya decidió cómo (ADR 0047); este ADR dice qué hace cada app.

## Decisión

### 1. Eliminar mi cuenta

1. **Dónde.** Perfil, Privacidad y datos, «Eliminar mi cuenta», en los dos flavors. Es una feature compartida de `nucleo/marketplace` (`eliminacion/` con `domain/`, `data/` y `presentation/`, cubit propio); `cliente/` y `piloto/` no se importan entre sí. Es un trámite de alta y de seguridad: **requiere red y no pasa por el outbox** (como el registro, la verificación y la recuperación, ADR 0024 punto 6; la excepción se amplía en `CLAUDE.md`).
2. **Flujo, una acción principal por pantalla.** (a) Resumen: qué se elimina y qué se conserva (selfie y documento 90 días, o 12 meses con antecedentes; servicios y calificaciones sin su nombre; plazo de 7 días para arrepentirse) y los impedimentos; (b) contraseña y envío del código al correo de respaldo; (c) código de 6 dígitos y botón destructivo «Eliminar mi cuenta»; (d) confirmación: «Recibimos tu pedido. Tu cuenta se eliminará el DD/MM. Si cambias de opinión, entra a la app antes de esa fecha». La app **no replica reglas**: `GET /api/cuenta/eliminacion` le dice si puede y por qué no (`servicio_en_curso`, `reclamo_abierto`, `incidencia_abierta`, `pilotos_vinculados`), y le entrega los plazos y lo conservado para mostrarlos; cada motivo se explica con su salida («Termina o cancela tu servicio primero»). Ante `409 eliminacion_bloqueada` muestra esos motivos, no un error genérico.
3. **Antes de pedirla, el piloto sincroniza.** Si el outbox tiene registros pendientes, la pantalla lo dice («Primero sincroniza lo que registraste en el lote») y no ofrece continuar: un registro que llegara después de la eliminación se rechazaría y se perdería. No se toca `nucleo/sync` ni `nucleo/db`.
4. **Al pedirla** el servidor revoca las sesiones: la app cierra la sesión y **borra todo lo local** (almacenamiento seguro, preferencias y `drift`, con el mismo mecanismo del cierre de sesión), y vuelve al inicio. Si la persona vuelve a entrar durante la gracia, el login funciona pero la sesión trae `cuenta.eliminacion` (estado `solicitada` y fecha de ejecución) y la app muestra solo una pantalla: «Tu cuenta está en proceso de eliminación. Se eliminará el DD/MM», con «Conservar mi cuenta» (`POST /api/cuenta/eliminacion/cancelar`) y «Cerrar sesión»; todo lo demás responde `403 cuenta_en_eliminacion` y la app no lo intenta. Cancelar no restaura las solicitudes abiertas ni las ofertas retiradas, y la pantalla lo dice.
5. **Estados** (los cinco, con textos en español y una salida): carga, bloqueada (motivos), sin red («Para eliminar tu cuenta necesitas conexión»), error con reintento (y `429` «Espera unos minutos antes de pedir otro código») y éxito. El código vencido o equivocado lo decide el servidor; la app no cuenta intentos. **El código no se guarda** (ADR 0024 punto 7).
6. **La web `/eliminar-cuenta`** es de `agrocom-api`; la app la enlaza desde la misma pantalla («¿No puedes entrar? Pídelo en la web») y desde la ficha de la tienda.

### 2. Reportar y bloquear

7. **Reportar.** En el chat de las dos apps: tocar un mensaje abre «Reportar mensaje» y el menú del chat ofrece «Reportar conversación»; en la galería de fotos de avance (cliente), «Reportar foto». Una hoja pide el motivo (lista del servidor), un detalle opcional de hasta 280 caracteres y dice con claridad que **soporte podrá leer lo reportado** («Agrocom revisará este mensaje y algunos de los mensajes cercanos»); el botón «Enviar reporte» es la aceptación. Es en línea y sin outbox: sin red la hoja lo dice y no encola nada. Éxito: «Gracias. Lo revisaremos en 24 horas hábiles. Puedes bloquear a esta cuenta mientras tanto». El reportado no se entera.
8. **Bloquear.** Desde el menú del chat, desde la conversación de una negociación (junto a rechazar o cerrar) y desde «Cuentas bloqueadas» en Privacidad y datos, donde también se deshace. Antes de ejecutar, una confirmación explica el efecto en tres líneas: se cierra el chat, se cierra la negociación en curso y ya no se verán las solicitudes del otro; **un servicio adjudicado sigue**. Tras bloquear, el chat queda de solo lectura; a la otra parte solo le aparece «Este chat está cerrado». La app **no calcula** el efecto en el cupo, el mapa ni los avisos: lee lo que entrega el servidor (la bandeja del cliente y el mapa del piloto ya vienen filtrados; un `404` en una solicitud bloqueada se muestra como «Esta solicitud ya no está disponible»).
9. **Estados.** Cada hoja y la pantalla «Cuentas bloqueadas» definen carga, vacío («No bloqueaste a nadie»), error, sin red y éxito. El mensaje rechazado por el filtro del servidor (`mensaje_no_permitido`) se muestra como «Este mensaje no se puede enviar» con el motivo; en el piloto, el registro sincronizado vuelve `rechazado` y el mensaje queda marcado sin reintento.
10. **Contacto de soporte** visible en Perfil (Ayuda), con el correo publicado en las fichas de las tiendas.

### 3. SOS, incidencias y ubicación

11. **La ubicación de una emergencia se guarda en el servidor** solo si la persona pulsa el botón de auxilio o reporta una incidencia, con finalidad de seguridad y 90 días después de cerrar el caso (ADR 0047, punto 14). **Piloto:** al pulsar, la app toma la posición del dispositivo en ese momento (el permiso «mientras se usa» ya se explicó en la pantalla previa y el texto de permiso lo menciona) y la adjunta al registro de la incidencia; ese registro es del lote y va por el outbox, así que la posición **viaja dentro de ese registro mientras espera sincronizarse y se borra con él una vez confirmado**; es la única excepción a «ninguna ubicación en `drift`», y el SOS no espera a la red para guardar el caso. **Cliente:** el SOS adjunta la ubicación del terreno del servicio, que el servidor ya tiene, y un texto opcional («Dónde estás»); la app del cliente **no pide permiso de ubicación** y su manifiesto y su `Info.plist` no lo declaran. Es revisable.
12. **El SOS no sustituye llamar a los servicios de emergencia:** la pantalla ofrece primero el número local. Las fotos de una incidencia se comprimen sin metadatos de ubicación (EXIF).

### 4. Textos de permisos por flavor

13. **Cámara** (los dos): «Agrocom usa la cámara para tomarte una selfie y fotografiar tu documento, y para tomar fotos del terreno y del avance del servicio. Solo las ve quien tiene que verificarlas o quien participa del servicio.» Se pide justo antes del paso de la selfie, con una pantalla que explica para qué sirve y que no se usa para nada más.
14. **Fotos** (los dos): «Agrocom accede solo a las fotos que eliges para tu perfil, el logo de tu empresa, tus documentos y el terreno. No lee el resto de tu galería.» Se prefiere el selector del sistema.
15. **Ubicación (solo `piloto`):** «Agrocom comparte tu última ubicación con el cliente solo mientras tienes un servicio en ejecución. También la usamos, solo si pulsas el botón de auxilio o reportas una incidencia, para avisar a soporte dónde estás.» «Mientras se usa»; sin ubicación en segundo plano ni servicio en primer plano; el piloto puede desactivarla y la app funciona igual. **El flavor `cliente` no declara ningún permiso de ubicación** (`AndroidManifest.xml` por flavor e `Info.plist`).
16. **Notificaciones** (los dos): se piden en contexto, con una pantalla previa («Te avisamos cuando haya ofertas, mensajes o una solicitud nueva») y la app no las exige para usarse.
17. **Enlaces y edad.** Términos y privacidad como enlaces en el registro y en Perfil, con las direcciones de `GET /api/legal/vigentes`; el registro agrega la declaración «Soy mayor de 18 años» junto a la casilla de aceptación (las apps son para adultos).
18. **Sign in with Apple no aplica:** las apps usan solo su propio sistema de cuentas (Apple 4.8). Si se agrega un inicio de sesión de terceros, hay que revisarlo.

### 5. Mapa

19. El mapa usa hoy teselas públicas de OpenStreetMap, que no son una base para una app publicada. Cuál es la alternativa es una **decisión del dueño** (tres opciones en `tiendas-y-privacidad.md`, 1.12); la app mantiene la atribución y el `User-Agent`, y una clave de proveedor, si la hay, entra por `--dart-define-from-file`.

## Alternativas descartadas

- **Encolar la eliminación, el reporte o el bloqueo en el outbox:** son trámites de seguridad que el servidor confirma; un reporte o una eliminación que llegan días después no sirven.
- **Que la app calcule si se puede eliminar:** dos fuentes de verdad; el servidor ya decide y explica.
- **Pedir ubicación del dispositivo a la app del cliente para el SOS:** agrega un permiso y su formulario para un caso que el terreno del servicio ya cubre.
- **Guardar la posición de una emergencia en `drift` más allá del outbox:** deja un dato sensible en el dispositivo sin necesidad.
- **Bloquear que cancele el servicio adjudicado:** un clic rompería un acuerdo entre dos; el reclamo es la vía formal.

## Consecuencias

- Hay pantallas nuevas: Privacidad y datos, Eliminar mi cuenta (cuatro pasos y el aviso de cuenta en proceso), Reportar (mensaje, conversación y foto), confirmación de bloqueo, Cuentas bloqueadas, SOS con su ubicación y las pantallas previas de permisos; con los cinco estados y goldens en claro y oscuro, a ancho de teléfono pequeño y grande. El diseño va antes de implementarlas (`DESIGN.md`) y están listadas en `docs/diseno/especificacion-pantallas.md`.
- Cambian las reglas de `CLAUDE.md`: la excepción documentada de negociar con red incluye los trámites de cuenta (registro, verificación, recuperación, eliminación, reportar y bloquear); la frase «ninguna ubicación se guarda» pasa a su formulación exacta; y la eliminación y los permisos entran a la lista de «qué no delegar».
- Ninguna de estas piezas toca `nucleo/sync` ni `nucleo/db`: el replay sigue verde.
- Dependen de endpoints que `agrocom-api` publica en `docs/api/openapi.yaml`; los que no estén se anotan en `docs/gestion/brechas-api.md`.
- **Revisable:** el SOS del cliente sin permiso de ubicación, los textos y la declaración de edad. **Pendiente de asesoría legal:** los plazos de retención y el texto de la pantalla de eliminación (`tiendas-y-privacidad.md`, sección 3).
