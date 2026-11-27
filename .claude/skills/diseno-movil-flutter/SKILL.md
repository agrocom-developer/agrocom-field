---
name: diseno-movil-flutter
description: Principios, paleta, tipografía, movimiento, componentes y checklist de pantalla excelente para las apps Flutter de Agrocom (Android, iOS, iPad), con diseño limpio y sin sobrecarga visual. Usar antes de crear o rediseñar cualquier pantalla o componente, y al revisar una.
---

# Diseño móvil en Flutter — agrocom-field

Meta: una pantalla se entiende en dos segundos, se maneja con una mano, y se ve cuidada sin esfuerzo. Menos elementos, mejor elegidos.

## Principios

1. **Una acción principal por pantalla.** Un solo botón de énfasis; lo secundario es texto o contorno.
2. **Jerarquía por tamaño, peso y opacidad**, no por más colores. Dos niveles de énfasis como máximo por bloque.
3. **Espacio en blanco como herramienta.** Escala de espaciado fija de 4 dp (4, 8, 12, 16, 24, 32); gutter lateral de 16 dp en teléfono, 24 dp o más en tableta.
4. **Honestidad de estado.** Cargando, vacío, error, sin conexión y éxito se diseñan antes que el caso feliz.
5. **Consistencia antes que creatividad.** Si existe un componente en `lib/nucleo/ui/`, se usa; si falta, se agrega al catálogo, no se improvisa en la pantalla.
6. **Texto corto, en español con acentos y tuteo.** El nombre visible de la app es «Agrocom».

## Dos registros, un sistema

| | `cliente` | `piloto` |
|---|---|---|
| Uso | Cotidiano, interior y exterior | Lote, sol directo, guantes, RC de gama media |
| Modo | Claro por defecto; oscuro de alto contraste opcional | Claro por defecto; oscuro de alto contraste (ADR 0008) opcional |
| Contraste mínimo | 4.5:1 texto normal | 7:1 en texto crítico |
| Táctil | 48 dp | 56 dp o más |
| Plataforma | iOS y Android, iPad adaptativo | Android |

Comparten forma (radios), espaciado, tipografía y movimiento. Cambia solo la paleta.

## Paleta

- **Verde de marca** para identidad (cabeceras, navegación activa) y **ámbar** como el 10 % de acento: botón principal e íconos en burbuja. Más pautas en el skill `ux-buenas-practicas-movil`.
- **Neutros** con tinte verde sutil para fondos y bordes; texto principal casi negro (claro) o casi blanco (oscuro). La jerarquía del texto se resuelve con opacidad del mismo color.
- **Semánticos**: éxito, alerta, error e información. Siempre acompañados de ícono o texto; el color nunca es el único portador de significado.
- Verificar cada par texto/fondo con la fórmula de luminancia relativa de WCAG y anotar el valor en el PR. Nada de gradientes decorativos ni más de un acento por pantalla.

## Tipografía

Fuente de plataforma (San Francisco en iOS, Roboto en Android) para texto humano, con escala Material 3 (display, headline, title, body, label). Datos técnicos (códigos, hectáreas, marcas de tiempo) con cifras tabulares. Mínimo 14 sp en cuerpo, 12 sp en leyendas. Debe soportar escala de fuente del sistema hasta 200 % sin romper el diseño.

## Movimiento

- Duración 150 a 300 ms; entrada con `easeOutCubic`, salida más corta que la entrada.
- Transiciones que expliquen (un elemento que se expande hacia su detalle) y nunca decoren.
- Respetar "reducir movimiento": sustituir por fundido.
- Skeletons en lugar de spinners de pantalla completa; retroalimentación háptica sutil en confirmaciones.
- Nada de animación que bloquee una acción ni que corra en bucle sin motivo.

## Componentes base

Botón (primario, secundario, texto), campo de formulario con etiqueta y error en línea, tarjeta de servicio, fila de lista, chip de estado, barra de progreso del ciclo del servicio, calificación con estrellas, hoja inferior, diálogo, aviso (snackbar), estado vacío, esqueleto de carga. Todos en `lib/nucleo/ui/componentes/`, con su pantalla de catálogo y golden.

## Adaptativo

Teléfono (menos de 600 dp): una columna, navegación inferior. Tableta e iPad (600 dp o más): dos paneles (lista y detalle), ancho máximo de lectura de 640 dp, navegación lateral. Respetar áreas seguras, notch e isla dinámica, y teclado abierto sin tapar el campo activo.

## Rendimiento

60 fps en el RC de gama media: constructores `const`, listas con `builder`, imágenes con tamaño decodificado acotado, sin `Opacity` ni `BackdropFilter` apilados en listas, `RepaintBoundary` solo donde el perfil lo justifique. Revisar con el perfilador antes de agregar un paquete de animación.

## Elegir librerías

Antes de diseñar una pantalla, leer también `ux-buenas-practicas-movil` (zona del pulgar, simetría, héroes, vacíos, animación).

Primero lo que trae Flutter y Material 3. Si hace falta un paquete, se busca con `find-skills`, se evalúa (mantenimiento, licencia, tamaño, soporte iOS, Android e iPad) y se documenta en un ADR de este repo. Un paquete visual nuevo sin ADR no entra.

## Checklist de pantalla excelente

- [ ] Una acción principal clara; nada compite con ella.
- [ ] Usa solo componentes y tokens del catálogo.
- [ ] Contraste medido y anotado; no depende solo del color.
- [ ] Estados vacío, cargando, error, sin conexión y éxito diseñados.
- [ ] Texto escalado al 130 % y 200 % sin desbordes; nombres largos probados.
- [ ] Áreas táctiles de 48 dp (56 dp en campo) y etiquetas semánticas.
- [ ] Modo oscuro completo.
- [ ] Teléfono y tableta/iPad revisados; áreas seguras respetadas.
- [ ] Movimiento propositivo, con alternativa para reducir movimiento.
- [ ] Goldens y capturas de simulador y emulador revisados por `qa-visual`.
- [ ] Textos con acentos, tuteo y sin jerga técnica.
- [ ] Perfil de rendimiento sin caídas de cuadros en el flujo principal.
