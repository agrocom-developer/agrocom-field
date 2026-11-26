# Handoff: Agrocom Móvil · Identidad Industrial AgTech

## Overview
Agrocom Móvil es un marketplace de fumigación con drones por negociación. El cliente publica lotes en un mapa con hectáreas y precio por ha. Los pilotos aceptan o contraofertan (máximo 5 rondas) y el cliente elige. Después vienen las fotos de avance, el precio final (ha ejecutadas × precio acordado; el pago es directo y no pasa por la app) y la calificación. Hay dos roles de uso, uno por flavor: cliente y piloto. El auxiliar no es usuario de la app (ADR 0021).

Este paquete define la identidad **Industrial AgTech**: verde agrícola #347A36, grafito #29343A y ámbar #F5A623. Tiene variantes clara, oscura y modo campo AAA, e incluye 21 pantallas.

## About the Design Files

Para verlos: abre `prototipo/Agrocom Direcciones.dc.html` en un navegador (necesita `support.js` y `assets/` en la misma carpeta). El selector de arriba cambia el tema de todas las pantallas.

## Fidelity
**Alta fidelidad** para colores, tipografía, radios, jerarquía y copy. Los marcos miden 360×780 con un bisel de 10 px, así que el área útil es de 340×760 dp. Los iconos son glifos provisionales (◉ ◇ ▢ ○ ←): reemplázalos por la familia de iconos del proyecto (sugerencia: Material Symbols Rounded). Las portadas (01) están aprobadas en concepto, pero todavía se pueden enriquecer.

## Design Tokens
La fuente de verdad es `tokens/tokens.json` (en `docs/diseno/`). También hay `tokens/tokens.css` y `tokens/agrocom_tokens.dart`.

| Token | Claro | Oscuro | Campo AAA |
|---|---|---|---|
| bg | #F3F5F1 | #17251C | #000000 |
| surface | #FFFFFF | #293832 | #0F1A13 |
| surface2 | #E9EEE7 | #34443B | #1B2A20 |
| primary / hover | #347A36 / #28632C | #62B66A / #79CA80 | #8EE08F / #A8EBA8 |
| onPrimary | #FFFFFF | #0F1F12 | #000000 |
| primaryContainer / on | #E1EEDD / #22562A | #2E4A35 / #A8DCAC | #1B3A22 / #CBF5CB |
| graphite / on | #29343A / #FFFFFF | #34443B / #EDF3EC | #1B2A20 / #FFFFFF |
| amber / on | #F5A623 / #29343A | #FFB52E / #17251C | #FFC547 / #000000 |
| amberContainer / on | #FDF0D3 / #7A4B00 | #4A3A17 / #FFD488 | #3A2C00 / #FFE3A3 |
| paper / paper2 / fold (post-it) | #FFE680 / #FFDA55 / #E8C13E | #F2D56E / #E6C552 / #C9A83A | = claro |
| text / text2 | #202A2E / #68756D | #EDF3EC / #AAB8AC | #FFFFFF / #D7E2D9 |
| border | #DDE4DC | #405247 | #6B8272 |
| info / container / on | #2785C7 / #E2F0FA / #14577F | #50A5D8 / #1E3A4C / #A6D4F0 | #8CCBF2 / #0E2A3B / #C6E6FA |
| error / container / on | #DC4545 / #FCE6E6 / #A12727 | #FF6868 / #4A2326 / #FFB4B4 | #FF8A8A / #3D1214 / #FFC9C9 |

Correcto = primary, Advertencia = amber.

- **Tipografía:** Manrope (400–800) para la UI y JetBrains Mono (500/700) para todas las cifras.
  - h1 28/800, −0.02em
  - h2 24/800
  - título de barra 17/800
  - cuerpo 15/500, interlineado 1.5
  - etiqueta 12/700
  - overline mono 11/700, +0.08em
  - número display mono 56/700, −0.04em
  - número de tarjeta mono 22–26/700
- **Radios:** botón píldora 28 (alto 56), tarjeta 24, tarjeta compacta 18–20, input 16, chip/filtro 12, hoja inferior 32, avatar 22–24 (cuadrado redondeado) o círculo.
- **Sombra:** claro `0 1px 2px rgba(32,42,46,.06), 0 4px 14px rgba(32,42,46,.07)`; oscuro con alpha .30/.25; campo sin sombra.
- **Espaciado:** márgenes laterales de 16 (contenedores) y 20 (texto); separación entre tarjetas de 8–12.
- **Áreas táctiles:** mínimo 48, y 72 en modo campo.
- **Overlay sobre mapa:** claro rgba(23,37,28,.12), oscuro .38, campo .5.

## Componentes
- **Botón primario:** fondo primary, texto onPrimary 15/800, alto 56, radio 28, hover primaryHover.
- **Botón secundario:** surface, borde 1 px border, texto text.
- **Destructivo:** texto en error, sin fondo.
- **Acción especial "Publicar lote":** fondo grafito, "+" en ámbar, radio 18.
- **Chip de estado:** 12/700, padding 4×10, píldora. Variantes ok (primaryContainer), warn (amberContainer), info, err y neutro (surface2).
- **Filtro activo:** grafito con texto blanco. Inactivo: surface.
- **Barra inferior:** 4 ítems. El activo lleva un indicador tonal de 56×30 (radio 15, primaryContainer) y la etiqueta en 12/800.
- **Burbuja de negociación:** etiqueta mono 11 "R3 · CLIENTE" encima de la burbuja.
  - Cliente: surface con borde, radio 22 22 22 6, a la izquierda.
  - Piloto: primary, radio 22 22 6 22, a la derecha.
  - Contenido: Bs/ha en mono 22/700 y total en mono 12.
  - Barra de progreso de 5 segmentos: hechos en primary, turno actual en amber, pendientes en surface2.
- **Ticket de pedido:** cabecera grafito con "PEDIDO #AG-0412" en mono 12 y estado en ámbar. Filas clave/valor. Separador punteado de 2 px.
- **Post-it:** gradiente de 172° de paper a paper2, texto onPaper. Esquina inferior derecha recortada 22 px con un triángulo fold. Sombra `drop-shadow(0 6px 7px rgba(0,0,0,.2))`. Rotación de entre −1.2° y 0.8°. La oferta elegida lleva un badge "ELEGIDO" en primary.
- **Mosaico de fotos (collage):** grid de 2fr / 1fr con 2 filas y gap 4, radio 18. Una foto grande ocupa las dos filas. A la derecha va una foto y un bloque ámbar con un número mono y una etiqueta. Las fotos llevan la hora en una etiqueta mono sobre grafito al 78 %.
- **Banner sin señal:** fondo ámbar, punto, texto 14/800 y "AUTO" en mono.

## Screens / Views
Las capturas están en `referencia/claro/` (y una selección en `oscuro/` y `campo/`).

**Acceso y registro**
- **01 Portadas:** carrusel de 3 slides que avanza solo cada 3,5 s (transform 600 ms cubic-bezier(.2,.8,.2,1)). La mitad superior es un collage de 400 px con radio inferior de 36.
  1. Mapa con lote y pin "Bs 62/ha", foto del dron y bloque ámbar "120 hectáreas publicadas".
  2. Foto a sangre con burbujas de negociación y la barra "RONDA 3/5".
  3. Foto, post-it "PRECIO FINAL 118 ha × 64 = Bs 7.552" y foto del dron en tierra.
  - Título 28/800 y texto 15. Los puntos marcan la posición (activo de 28 px) y se pueden tocar. Botones "Comenzar" y "Ya tengo cuenta". "Saltar" arriba a la derecha.
- **02 Login:** "Ingresa con tu celular". Campo +591 con chip "Enviado". Código de 6 casillas de 56 de alto (la activa con borde primary de 2 px) y "Reenviar en 0:42". Botones Ingresar, "o", Continuar con Google y "¿Nuevo en Agrocom? Crear cuenta".
- **03 Elige tu rol:** collage de 270 px con foto grande, foto y bloque ámbar "Agrocom · Fumigación con dron". Título "Fumigación con dron, al precio que acuerdes". Selección de rol Cliente / Piloto: la opción elegida tiene fondo primaryContainer y borde primary de 2 px. Botones "Continuar como cliente" y "Ya tengo cuenta".
- **04 Registro · datos personales:** pasos 1 de 3. Foto de perfil (cuadro punteado). Campos: Nombre, Cédula (mono), Celular (chip Verificado), Zona base y Licencia DGAC (chip Subida). Botón Continuar.
- **05 Registro · tu equipo:** pasos 2 de 3.
  - DRONES: tarjeta con foto de 72, "DJI Agras T50", "Tanque 40 L · serie" y chip "En revisión"; debajo "+ Agregar otro dron" (borde punteado).

**Cliente**
- **06 Inicio:** saludo y avatar.
  - Tarjeta "SOLICITUD ACTIVA" con chip ámbar "3 ofertas nuevas", cifras ha / tu precio / mejor oferta y el botón "Comparar ofertas".
  - Tarjeta de servicio en curso con barra de progreso.
  - FAB grafito "Publicar lote" y barra inferior: Inicio / Lotes / Servicios / Perfil.
- **07 Publicar lote:** pasos 2 de 3. Miniatura del mapa con el polígono, "120 ha dibujadas" y "Editar". Campos: nombre, cultivo (chips) y precio con stepper ±. "Promedio en la zona 58–66". Total estimado y "Revisar y publicar".
- **08 Detalle de la solicitud:** mapa a sangre de 300 px. Hoja inferior con:
  - chip info "Abierta · recibiendo ofertas" y "Vence en 2 días";
  - una cuadrícula de 2×2 con superficie, precio, cultivo y fecha;
  - un aviso ámbar sobre las ofertas;
  - los botones Editar / Ver 3 ofertas.
- **09 Comparar ofertas (ticket):** ticket con cabecera grafito y el resumen del lote, y debajo 3 post-its ordenados por menor total. Botón "Elegir a Marcelo · Bs 7.680".
- **10 Seguimiento:** "48 / 120 ha" en mono 56, barra de 14 px y mosaico de fotos (+5 en ámbar). Timeline de 4 pasos: hecho en primary con ✓, actual con anillo ámbar, pendiente con borde. Tarjeta del piloto con botón Chat.
- **11 Chat:** burbujas de texto, burbuja con foto de 200 px de ancho, evento de sistema en píldora primaryContainer y campo de mensaje de 52 con botón de enviar circular.
- **12 Precio final:** ticket "POR CONFIRMAR" con 118 ha × 64 Bs/ha y "Bs 7.552" en mono 44. Avisos: ámbar (diferencia de ha) e info (pago directo). Botones "Confirmar precio final" y "Abrir disputa" (en error).
- **13 Calificar:** avatar de 80, 5 estrellas de 48 (ámbar), chips de atributos, comentario y "Enviar calificación".

**Piloto**
- **14 Mapa de solicitudes:** mapa a sangre con lotes (verde = abierto, ámbar = vence hoy) y pines de precio (el seleccionado en primary). Búsqueda en píldora de 56, filtros y hoja inferior con lote, cifras y los botones Contraofertar / Aceptar Bs 62.
- **15 Negociación:** cabecera "Ronda 4 de 5" con barra de segmentos, burbujas R1–R3 y aviso ámbar "Tu turno". Panel inferior con stepper (68 Bs/ha, total) y los botones Aceptar 65 / Enviar 68.
- **16 Mis ofertas:** pestañas segmentadas Activas / Ganadas / Cerradas. Tarjetas con chip de estado y cifras de cliente y tuyas; si es tu turno, la tarjeta lleva borde ámbar.

**Perfiles**
- **17 Perfil del cliente:** avatar, estadísticas (lotes, ha, calificación), "Mis campos" con miniaturas, ajustes (avisos, tema, cambiar a piloto) y "Cerrar sesión".
- **18 Perfil del proveedor · ajustes:** estadísticas, selector de tema Claro / Oscuro / Campo AAA, avisos, zona de trabajo, dron y licencia.
- **19 Perfil público del proveedor:** lo que ve el cliente. Chip "Licencia verificada", estadísticas, EQUIPO (dron y piloto), RESEÑAS y barra inferior con la oferta y el botón "Elegir".

**Estados**
- **20 Vacío:** icono en contenedor de 88, título, texto con un dato útil y CTA "Ver lotes en el mapa".
- **21 Error de envío:** banner ámbar sin señal, icono "!" en errorContainer y el mensaje "No se envió tu contraoferta" (queda guardada y se reenvía sola). Tabla de qué funciona sin red. Botones "Reintentar ahora" y "Volver a la negociación".

## Interactions & Behavior
- **Portadas:** avanzan solas cada 3,5 s; al tocar un punto se salta a esa slide y se reinicia el temporizador. Recomendado: pausar mientras el usuario arrastra, permitir el gesto de deslizar y respetar "reducir movimiento".
- **Negociación:** máximo 5 rondas y la quinta es definitiva. El stepper cambia de a ±1 Bs/ha y el total = ha × precio se recalcula en vivo.
- **Sin conexión:** las fotos y el avance funcionan sin red y quedan en cola. Las ofertas y el chat requieren red, con reintento automático. El banner de estado de red está siempre visible en ejecución.
- **Tema:** Claro, Oscuro o Campo AAA, persistido en Ajustes. El modo campo agranda las áreas táctiles a 72.
- **Hojas inferiores:** arrastrables (manija de 36×4).

## State Management (sugerido)
Las variables mínimas son:
- tema;
- índice del carrusel;
- borrador de publicación (polígono, ha, cultivo, precio);
- negociación (rondas[], turno, precioPropuesto);
- ofertas[] y orden;
- servicio (haEjecutadas, fotos[], pasos);
- cola offline;
- estado de red;
- calificación.

## Páginas que convendría agregar
Estas pantallas aún no están diseñadas:
- Revisión y publicación (paso 3 de 3 de "Publicar lote").
- Dibujo del polígono sobre el mapa (paso 1).
- Detalle de la oferta del lado del piloto antes de aceptar.
- Ejecución en modo campo del piloto: marcar avance y finalizar.
- Disputa: motivo, evidencia y estado.
- Notificaciones.
- Historial de servicios.
- Revisión de verificación (perfil en revisión o rechazado).
- Permisos (ubicación, cámara).

## Assets
- `prototipo/assets/mapa-santa-cruz.png`: captura satelital de Google Maps del centro de Santa Cruz que dio el cliente. **Solo para la demo**; en la app hay que usar un SDK de mapas.
- `prototipo/assets/fotos/`: fotos de Unsplash bajo la Licencia Unsplash, usadas como contenido de demo.
  - `dron1.jpg`: dron fumigando en surcos (DRONE EFT).
  - `dron2.jpg`: boquilla de pulverización (DRONE EFT).
  - `dron3.jpg`: dron esparciendo (DRONE EFT).
  - `piloto.jpg`: dron agrícola en tierra (DRONE EFT).
  - `tractor.jpg`: pulverizadora aérea (Marios Gkortsilas).
  - `campo.jpg`: vista aérea de una finca (Max Böttinger).
  - En producción, las fotos vienen del backend.
- Fuentes: Manrope y JetBrains Mono (Google Fonts, licencia OFL).

## Pendientes conocidos
- El texto secundario #68756D sobre bg #F3F5F1 queda en unos 4.3:1. Sobre surface blanco sí pasa AA. Hay que oscurecerlo un poco o limitarlo a superficies blancas.
- En algunas capturas el borde izquierdo del marco se corta en las pantallas con imagen a sangre. Es un defecto del método de captura, no del diseño.

## Files
- `prototipo/Agrocom Direcciones.dc.html` (+ `support.js`, `assets/`): prototipo de referencia con las 21 pantallas.
- `tokens/tokens.json`, `tokens/tokens.css`, `tokens/agrocom_tokens.dart`.
- `referencia/claro/` (23 imágenes, incluidas las 3 portadas), `referencia/oscuro/` (5) y `referencia/campo/` (3).
