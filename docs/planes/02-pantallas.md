# Plan 02 · Pantallas del handoff

**Objetivo.** Llevar las 21 pantallas del handoff a Flutter, integradas con lo que ya existe, y diseñar las que faltan. Cada fase pide revisión con capturas del simulador.

## Auditoría de las 21 pantallas

El handoff exige auditar antes de editar. Rutas relativas a `lib/`. El flavor `auxiliar` ya no existe (ADR 0021), así que queda fuera de la tabla. «Piloto» vive en `nucleo/marketplace/proveedor/` porque el flavor `piloto` comparte esa superficie (ADR 0012).

Clasificación: **A** = existe y se re-estiliza · **B** = existe con otra estructura · **C** = no existe.

| # | Pantalla | Archivo actual | Clase | Qué falta frente al diseño |
|---|---|---|---|---|
| 01 | Portadas | `cliente/acceso/presentation/onboarding_pantalla.dart` | B | Hoy son pasos con una foto, botón «Continuar» y sin autoavance. El diseño pide carrusel de 3 slides con collage, autoavance de 3,5 s, pausa al interactuar, puntos tocables, «Comenzar» y «Ya tengo cuenta» |
| 02 | Login por celular | `cliente/acceso/presentation/login_cliente_pantalla.dart`, `lienzo_acceso.dart`; piloto: `proveedor/acceso/presentation/acceso_pantallas.dart` (`IngresoProveedorPantalla`) | B | Hoy ingresa con usuario y contraseña. El diseño es celular +591 y código de 6 casillas, más «Continuar con Google». El contrato no ofrece código por SMS ni Google: la lógica se conserva y solo cambia la presentación |
| 03 | Elegir rol | no existe | C | El selector de rol se retiró (ADR 0021): el flavor fija el rol. Queda solo la pantalla de presentación con Cliente y Piloto, sin navegación que la aloje hasta que el dueño decida |
| 04 | Datos personales | cliente: `cliente/acceso/presentation/registro_cliente_pantalla.dart`; piloto: `proveedor/acceso/presentation/registro_proveedor_pantalla.dart` (paso «Tus datos») | B | El diseño es «paso 1 de 3» con foto de perfil, cédula, celular verificado, zona base y licencia en una sola pantalla; hoy son cuatro pasos y el cliente tiene un formulario plano |
| 05 | Equipo (dron) | piloto: `registro_proveedor_pantalla.dart` (paso «Tu dron»), `proveedor/dron/presentation/drones_pantalla.dart` | B | Falta la tarjeta con foto, chip de revisión y el botón punteado «Agregar otro dron». Sin auxiliares (ADR 0021) |
| 06 | Inicio del cliente | `cliente/inicio/presentation/inicio_cliente_pantalla.dart` | A | Tarjeta de solicitud activa con cifras, FAB «Publicar lote» |
| 07 | Publicar lote | `cliente/solicitar/presentation/solicitar_pantalla.dart`, `pasos_solicitud.dart`, `mapa_solicitud.dart` | B | Flujo por pasos propio (ADR 0014); falta miniatura del mapa con stepper de precio y total estimado |
| 08 | Detalle de la solicitud | `cliente/solicitudes/presentation/solicitud_detalle_pantalla.dart` | A | Mapa a sangre con hoja inferior |
| 09 | Comparar ofertas | `cliente/ofertas/presentation/ofertas_pantalla.dart` | B | Existe la lista; faltan el ticket de pedido y los post-its |
| 10 | Seguimiento | `cliente/seguimiento/presentation/seguimiento_pantalla.dart` | A | Cifra mono 56, mosaico de fotos, línea de tiempo |
| 11 | Chat | `cliente/seguimiento/presentation/chat_pantalla.dart` (piloto: `proveedor/negociacion/presentation/chat_pantalla.dart`) | A | Burbuja con foto y evento de sistema |
| 12 | Precio final | `cliente/comun/presentation/hoja_precio.dart`; piloto: `_PrecioFinal` en `proveedor/ejecucion/presentation/servicio_lote_pantalla.dart` | B | Hoy es una hoja; el diseño es pantalla con ticket «Por confirmar» |
| 13 | Calificar | `cliente/calificar/presentation/hoja_calificar.dart` | B | Hoy es una hoja; el diseño es pantalla con avatar y chips de atributos |
| 14 | Mapa de solicitudes | `proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart`, `mapa_solicitudes.dart` | A | Pines de precio y hoja inferior |
| 15 | Negociación | `proveedor/negociacion/presentation/pedir_precio_hoja.dart`, `solicitud_detalle_pantalla.dart` | B | Hoy es una hoja de precio; el diseño es pantalla con rondas, burbujas y barra de 5 segmentos |
| 16 | Mis ofertas | `proveedor/negociacion/presentation/mis_ofertas_pantalla.dart` | A | Pestañas Activas, Ganadas y Cerradas; borde ámbar si es tu turno |
| 17 | Perfil del cliente | `cliente/cuenta/presentation/cuenta_pantalla.dart` | A | Faltan «Mis campos» y el selector de tema (no existe selector de tema en ningún perfil) |
| 18 | Perfil del proveedor | `proveedor/perfil/presentation/perfil_pantalla.dart` | A | Falta el selector Claro, Oscuro y Campo AAA y quitar lo del auxiliar |
| 19 | Perfil público del proveedor | no existe | C | Lo que ve el cliente antes de elegir |
| 20 | Estado vacío | `nucleo/marketplace/ui/estado_vacio_marketplace.dart` | A | Componente compartido; falta contenedor de 88 y CTA |
| 21 | Error de envío | `nucleo/marketplace/ui/estado_error_marketplace.dart`, `aviso_marketplace.dart` | B | Falta la pantalla con tabla de qué funciona sin red y «Reintentar ahora» |

Requisito del dueño: el cliente puede ser **persona o empresa** con contactos de referencia. El contrato (`POST /api/clientes/registro`) soporta `tipo` (persona o empresa), `razon_social` y `documento_fiscal` (NIT, obligatorios para empresa); **no** soporta contactos de referencia (nombre, celular, cargo). Pantalla 04 del cliente: selector Persona o Empresa y campos de empresa con lo que el contrato ofrece. Los contactos de referencia son una brecha en `docs/gestion/brechas-api.md`; no se inventan en la app. El alta manual de pilotos y clientes desde el panel web es de la API.

Resumen: A = 9 (06, 08, 10, 11, 14, 16, 17, 18, 20), B = 10 (01, 02, 04, 05, 07, 09, 12, 13, 15, 21), C = 2 (03, 19).

### Colores y medidas sueltos por migrar

El test `test/nucleo/ui/tokens_sin_sueltos_test.dart` solo vigila colores literales (`Color(0x`, `Color.from`) y radios literales (`Radius.circular(n)`); ambos están en cero fuera de `nucleo/ui`. Quedan medidas literales (`fontSize`, `EdgeInsets`, `SizedBox`, `size`) que ningún test vigila. Conteo de coincidencias por archivo, fuera de `nucleo/ui`:

- `cliente/solicitudes/presentation/tarjeta_solicitud.dart` (12), `cliente/cuenta/presentation/cuenta_pantalla.dart` (8), `cliente/ofertas/presentation/ofertas_pantalla.dart` (6).
- `nucleo/version/version_bloqueada_pantalla.dart` (7), `nucleo/marketplace/ui/mapa_lote.dart` (5), `proveedor/perfil/presentation/perfil_pantalla.dart` (5), `proveedor/negociacion/presentation/mapa_solicitudes.dart` (5), `cliente/seguimiento/presentation/mapa_ubicacion_piloto.dart` (5).
- Con 3 o 4: `nucleo/marketplace/ui/estado_vacio_marketplace.dart`, `cliente/solicitar/presentation/mapa_solicitud.dart`, `cliente/seguimiento/presentation/seguimiento_pantalla.dart`, `cliente/inicio/presentation/inicio_cliente_pantalla.dart`, `insignia_estado_servicio.dart`, `calificacion_promedio.dart`, `aviso_marketplace.dart`, `visor_fotos_terreno.dart`, `proveedor/negociacion/presentation/solicitud_detalle_pantalla.dart`, `cliente/solicitar/presentation/solicitar_pantalla.dart`, `cliente/comun/presentation/insignia_estado_solicitud.dart`.
- El resto, con 1 o 2 coincidencias, está en `registro_proveedor_pantalla.dart`, `pasos_solicitud.dart`, `linea_tiempo_solicitud.dart`, `servicio_lote_pantalla.dart` y componentes de `nucleo/marketplace/ui`.

Cada pantalla de las fases 1 a 5 migra sus medidas a `EspaciadoCampo`, `RadioCampo`, `ObjetivoTactilCampo` y `TipografiaCampo` al re-estilizarse; los componentes de `nucleo/marketplace/ui` se migran cuando los consume la primera pantalla de la fase.

## Fases

| Fase | Pantallas | Notas |
|---|---|---|
| 1 · Acceso y registro | 01 portadas, 02 login por celular, 03 elegir rol, 04 datos personales, 05 equipo (dron) | Con el retiro del auxiliar (plan 03), «Elige tu rol» queda en Cliente y Piloto; «tu equipo» pierde la lista de auxiliares |
| 2 · Cliente | 06 inicio, 07 publicar lote, 08 detalle de solicitud, 09 comparar ofertas (ticket y post-its), 10 seguimiento, 11 chat, 12 precio final, 13 calificar | Máximo 5 rondas; el precio final es ha ejecutadas × precio acordado |
| 3 · Piloto | 14 mapa de solicitudes, 15 negociación, 16 mis ofertas | Aceptar y negociar requieren red |
| 4 · Perfiles | 17 cliente, 18 proveedor (ajustes), 19 perfil público | Selector de tema Claro, Oscuro y Campo AAA |
| 5 · Estados | 20 vacío, 21 error de envío | El mismo patrón en todas las listas y envíos |

### Fases 4 y 5 en el código

- **Barra inferior.** `BarraInferiorCampo` (indicador tonal de 56×30). Cliente: Inicio, Lotes, Servicios, Perfil; piloto: Mapa, Ofertas, Servicios, Perfil. «Publicar lote» es la acción del inicio y abre el flujo sobre la navegación; el dron y la licencia viven en el perfil del piloto.
- **Tema.** Claro, Oscuro o Campo AAA en el perfil de ambos flavors (`SelectorTemaVisual`), guardado en `shared_preferences`. El cliente sigue al sistema mientras no elija; el piloto arranca en campo.
- **Perfil público del piloto (19).** `PerfilProveedorPantalla`, desde «Ver perfil» en comparar ofertas. Solo muestra lo que el contrato entrega con la oferta; el resto está en `docs/gestion/brechas-api.md`.
- **Contactos de referencia.** Pantalla de contactos (cliente empresa), selector de contacto en «Publicar lote» y la persona de contacto con cargo y empresa en el servicio del piloto. El registro del cliente es siempre de una persona; el interruptor «Asociar a una empresa» crea la empresa con quien se registra como contacto principal.
- **Chat.** Burbujas de texto sobre `chat_bubbles`, burbuja con foto de 200 de ancho y evento de sistema en píldora (`chat_campo.dart`); envío de fotos comprimidas a menos de 300 KB.
- **Precio final.** El cliente confirma el precio final en la pantalla 12; el reclamo queda como salida alterna.
- **Estados 20 y 21.** `EstadoVacioMarketplace` (contenedor de 88 y acción) y `EstadoErrorMarketplace` (banner sin señal, «!» tonal, tabla de qué funciona sin red y «Reintentar ahora») son el patrón de todas las listas; la publicación de una solicitud que falla usa la pantalla de error con «Volver al formulario».

## Pantallas que faltan por diseñar

Revisión y publicación (paso 3), dibujo del polígono, detalle de la oferta antes de aceptar, ejecución del piloto en modo campo (marcar avance y finalizar), reclamo, notificaciones, historial de servicios, verificación del proveedor (en revisión o rechazado), permisos de ubicación y cámara. La pantalla «App del auxiliar» del handoff se descarta (plan 03).

## Criterio común

Los estados de cada pantalla (carga, vacío, error, sin red, éxito), textos en español con acentos, goldens y captura del simulador antes del PR.
