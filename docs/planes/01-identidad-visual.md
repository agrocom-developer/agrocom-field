# Plan 01 · Identidad visual Industrial AgTech

**Objetivo.** Que la app use la identidad del handoff (`docs/diseno/` y `DESIGN.md`): verde agrícola `#347A36`, grafito `#29343A` y ámbar `#F5A623`, con tema claro, oscuro y campo AAA, Manrope para la interfaz y JetBrains Mono para toda cifra.

**Punto de partida.** `lib/nucleo/ui/paleta_campo.dart` define hoy una paleta crema y verde hoja (fondo `#F6F2E4`, texto `#15210F`) con tres modos. El handoff reemplaza esos valores y agrega grafito, ámbar con contenedores, el papel del post-it y un tono `info`.

## Fases

| Fase | Qué | Criterio de aceptación |
|---|---|---|
| 1 | `docs/diseno/tokens/tokens.json` como fuente; mapear `agrocom_tokens.dart` sobre `PaletaCampo` en vez de crear un sistema paralelo | El test de contraste (`paleta_campo_test.dart`) pasa con los valores nuevos; ningún color suelto en pantallas |
| 2 | Resolver el pendiente conocido: `text2` `#68756D` sobre `bg` `#F3F5F1` queda en 4,3:1; oscurecer o limitarlo a superficies blancas | AA medido en cada par de texto sobre fondo |
| 3 | Tipografía: Manrope y JetBrains Mono con la escala del handoff (display 56, h1 28, cuerpo 15, overline 11) | Cifras (ha, Bs/ha, totales, rondas) siempre en mono |
| 4 | Radios, sombra y áreas táctiles como tokens (píldora 28, tarjeta 24, hoja 32; táctil 48, y 72 en campo) | Un test falla si una pantalla declara medidas propias |
| 5 | Componentes nuevos: burbuja de negociación, ticket de pedido, post-it, collage de fotos, banner sin señal, stepper ±1, hoja inferior | Goldens claro y oscuro por componente, en la vitrina |
| 6 | `DESIGN.md` en la raíz, adaptado a los nombres reales; `CLAUDE.md` remite a él | Una línea en `CLAUDE.md`; `DESIGN.md` actualizado en cada cambio de token |
| 7 | Iconos: una sola familia (Material Symbols Rounded, peso 500) | Sin glifos provisionales |

## Decisiones abiertas

- Qué flavor usa campo AAA por defecto (hoy `piloto`).
- Si el modo oscuro del cliente se ofrece en Ajustes o sigue al sistema.

## Riesgos

Cambiar la paleta toca todos los goldens: se regeneran por pantalla en el mismo PR que la migra, con revisión visual.
