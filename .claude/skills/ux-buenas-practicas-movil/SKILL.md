---
name: ux-buenas-practicas-movil
description: Pautas de buen y mal diseño UI/UX para apps móviles (zona del pulgar, un CTA, jerarquía, simetría de espaciado, formularios, estados vacíos con ilustración, errores, animación con propósito, imágenes a sangre) extraídas de comparativos reales, más su aplicación en Agrocom. Usar antes de diseñar o rediseñar cualquier pantalla de esta app o de una app nueva, y al revisar una pantalla que "se ve simple" o "se ve sobrecargada".
---

# UX buena y mala en móvil — base de diseño

Fuente: 15 comparativos «Good vs Bad UX» recopilados por el dueño (zona del pulgar, perfil, bienvenida, formularios, planes, estados vacíos, Slack/Teams, Telegram/WhatsApp, Booking/Ryanair, Glassdoor/Workday, Apple). Este skill es la base para esta app y para las siguientes. Complementa `diseno-movil-flutter` (tokens, paleta, accesibilidad); si chocan, gana el que sea más estricto.

## Las 12 pautas

1. **Acción principal en la zona del pulgar.** El CTA va abajo, a ancho completo, nunca arriba a la derecha. La cabecera solo orienta (volver, título). El ojo recorre: título → contenido → CTA, sin saltar a una esquina.
2. **Un solo CTA lleno por pantalla.** Si hay dos acciones, la principal va llena (ámbar) y la secundaria de contorno, apiladas con el mismo ancho, alto y radio. Botones iguales en forma y tamaño, nunca uno gris y otro amarillo de estilos distintos.
3. **Menos elementos, mejor elegidos.** Si algo no ayuda a decidir o actuar, se quita. Señales de sobrecarga: más de tres colores de acento, banners de oferta, tres niveles de navegación, más de un CTA, texto en mayúsculas gritando, íconos sin etiqueta.
4. **Jerarquía clara y visible.** Título grande y fuerte, apoyo en gris legible (contraste AA), cifras en peso alto. Lo importante pesa más; lo demás se atenúa sin volverse ilegible (el «malo» suele tener todo gris claro).
5. **Simetría y ritmo de espaciado.** Dentro de un mismo cuadro: mismo padding en los cuatro lados, misma separación entre filas (escala de 4: 8, 12, 16, 24), mismo alto de fila, ícono y texto alineados al mismo eje, y una sola columna de borde izquierdo. Entre grupos distintos, el doble que dentro de un grupo (proximidad). Los elementos hermanos (tarjetas de métricas, chips, botones) miden lo mismo.
6. **Imagen a sangre cuando es bienvenida o perfil.** La foto llena el fondo y el texto va encima sobre un degradado oscuro; el avatar se solapa con la cabecera. Evitar foto pequeña en caja con texto arriba y botones aparte.
7. **Comparar opciones en tarjetas lado a lado, no en lista de radios.** La opción elegida se eleva y lleva borde de acento. Cada tarjeta: etiqueta, cifra grande, unidad en gris.
8. **Formularios en una columna.** Etiqueta encima del campo, un campo por fila, errores en línea, botón al final a ancho completo. Nada de dos campos por fila en teléfono.
9. **Estados vacíos como oportunidad.** Ilustración o imagen + una frase que oriente + máximo dos beneficios + el CTA. Nunca «No tienes nada» solo.
10. **Errores: reconocer, diagnosticar, recuperar.** Qué pasó en lenguaje llano, qué hacer, y el botón para hacerlo. Sin códigos.
11. **Precio y estado siempre claros.** Un solo precio final, sin costos escondidos; el resumen de «lo que importa» al alcance (cifra grande, estado con ícono y texto, no solo color).
12. **Consistencia entre plataformas y pantallas.** Mismo componente para lo mismo; fila de lista = ícono en burbuja + título + apoyo + dato a la derecha; mismo radio, mismo borde, misma sombra.

## Ilustración, imagen y animación (que no se vea plano)

- **Un héroe por pantalla clave, no por todas.** Cabecera de color con forma (esquinas inferiores redondeadas) o foto con degradado en inicio, perfil, portada y vacíos. Las pantallas de trabajo (formularios, listas) quedan limpias.
- **Íconos solo de Material** (`Icons.*_rounded` / `_outlined`), dentro de una burbuja ámbar (`IconoBurbujaCampo`) cuando marcan una fila o beneficio. Nada de íconos dibujados a mano. Para lote: `Icons.landscape`; dron: `Icons.flight`; oferta: `Icons.handshake`; mapa: `Icons.map`.
- **Ilustración de estado vacío.** Composición de formas simples + ícono de Material grande sobre un círculo tonal, o animación Lottie (paquete `lottie` ya está en `pubspec.yaml`) en vacíos, éxito y carga larga. Máximo 160 dp de alto.
- **Fotos reales de campo** (`assets/imagenes/`, comprimidas): dron pulverizando, lote, equipo. Siempre con degradado para que el texto sobre foto cumpla contraste.
- **Animación con propósito, 150 a 300 ms:** entrada escalonada de tarjetas (fundido + desplazamiento de 12 dp, retraso de 40 ms por elemento), cifras que cuentan hasta su valor, el CTA que aparece al final, `Hero` del avatar al detalle. Respetar «reducir movimiento» (`MediaQuery.disableAnimations`): sin movimiento, solo aparece.
- Nada decorativo en bucle; nada que retrase una acción.

## Aplicación en Agrocom

- **Temas:** solo Claro (ciudad, predeterminado) y Oscuro (alto contraste AAA sobre verde profundo). Ver [[dos temas]] en la memoria del proyecto y `lib/nucleo/ui/paleta_campo.dart`.
- **Color 60/30/10:** 60 % neutros (fondo, superficies), 30 % verde de marca (cabeceras, identidad, navegación activa), 10 % ámbar (CTA, burbujas de ícono, chips de turno y avisos). El grafito para texto y estructura.
- **Cabecera de perfil y de inicio:** `CabeceraPerfilCampo` (verde, esquinas redondeadas, avatar centrado).
- **CTA:** `BotonPrimarioCampo` (ámbar) al pie con `BarraAccionesCampo`; secundario `BotonSecundarioCampo`.
- **Espaciado:** tokens `EspaciadoCampo`; el padding de una tarjeta es el mismo en los cuatro lados, y entre filas de una misma tarjeta `EspaciadoCampo.m`.
- **Piloto:** además, objetivos de 56 dp o más y alto contraste; el lote no tiene señal, así que los vacíos y errores explican qué queda guardado sin red.

## Checklist rápida antes de abrir el PR

- [ ] ¿El CTA está abajo, a ancho completo, y es el único relleno?
- [ ] ¿Se entiende en dos segundos qué es y qué hacer?
- [ ] ¿Los espacios dentro de cada cuadro son simétricos y de la escala de 4?
- [ ] ¿Hay un héroe (color con forma, foto o ilustración) en las pantallas clave?
- [ ] ¿Los vacíos orientan con imagen y CTA?
- [ ] ¿Los errores dicen qué hacer?
- [ ] ¿Las animaciones duran 150 a 300 ms y respetan reducir movimiento?
- [ ] ¿Solo íconos de Material?
