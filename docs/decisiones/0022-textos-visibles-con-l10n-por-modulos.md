# ADR 0022 — Textos visibles con `gen-l10n`, migrados por módulos

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field`.

## Contexto

Los textos del flavor `cliente` están escritos en los widgets. Eso dispersa la ortografía y el tono, impide revisarlos juntos y bloquea una segunda lengua. Migrar todo en un solo PR mezclaría cientos de cambios de texto con riesgo de regresión visual.

## Decisión

- Se usa `flutter_localizations` e `intl` con `gen-l10n` (`l10n.yaml` en la raíz, `generate: true`). Plantilla y única lengua por ahora: español (`lib/l10n/app_es.arb`).
- El código generado (`lib/l10n/app_localizations*.dart`) se versiona, igual que los ARB: `analyze` y las pruebas no dependen de un paso previo.
- `MaterialApp` del cliente declara `localizationsDelegates`, `supportedLocales` y `locale: es`. Las pruebas que montan pantallas migradas hacen lo mismo en su ayuda de montaje.
- Se migra **un módulo por PR** (`lib/cliente/<modulo>/`). Las claves llevan el módulo como prefijo (`problemaTitulo`, `problemaBotonEnviar`).
- Los textos con datos usan placeholders tipados (`problemaEnviadoCaso(numero, motivo)`), nunca concatenación. Plurales y géneros usan la sintaxis ICU.
- Los textos de enums del dominio (`MotivoProblema.etiqueta`) quedan en `nucleo` mientras otros módulos aún los lean. La pantalla migrada traduce con una extensión de `presentation/` (`textos_motivo.dart`) y un `switch` exhaustivo, de modo que un valor nuevo del enum no compila hasta tener texto. Cuando el último consumidor migra, se elimina el texto del dominio.
- Texto en español con acentos, tono directo, sin jerga técnica. Los textos de cubits y repositorios (mensajes de error) migran con su módulo, devolviendo un tipo de fallo que la pantalla traduce.

## Método por módulo

1. Listar los literales visibles del módulo (títulos, botones, ayudas, errores, etiquetas semánticas).
2. Agregarlos al ARB con prefijo de módulo; `flutter gen-l10n`.
3. Sustituir en los widgets con `AppLocalizations.of(context)`.
4. Montar las pruebas del módulo con los delegados; los goldens no deben cambiar (el texto es el mismo). Si cambian, se revisan.
5. `bin/verify`; un PR por módulo.

## Estado

Todos los textos visibles de las pantallas, componentes, etiquetas semánticas, ayudas, tooltips y avisos de los cubits están en `lib/l10n/app_es.arb` (módulos `cliente/*`, `nucleo/ui`, `nucleo/marketplace/*` y `piloto`). La prueba `test/nucleo/l10n/sin_textos_en_duro_test.dart` falla si aparece un literal visible en `lib/`; sus excepciones están escritas y justificadas en la propia prueba.

Reglas que salieron de la migración:

- Los cubits que construyen un aviso propio reciben `AppLocalizations` por constructor (se obtiene en el `build` que los crea, no dentro de `create:`). Los mensajes que llegan del servidor dentro de `OperacionRechazada` se muestran tal cual.
- Los enums y fallos de dominio traducen en una extensión de `presentation/` con `switch` exhaustivo (`TextosOrdenOfertas`, `TextosErrorHectareas`, `TextosRolElegido`).
- Quedan fuera, por decisión: las capas `data/` y `domain/` (respuestas simuladas, etiquetas de enums y reglas de validación que migran con su módulo cuando el último lector pase a la extensión), `demo/` (datos de demostración), el catálogo de diseño `vitrina_campo/` y `FormatoMarketplace` (unidades y fechas relativas es-BO sin contexto; pasa a `intl` con la segunda lengua).

## Consecuencias

- Un literal nuevo en un módulo migrado va al ARB; una revisión de PR lo exige.
- Dependencia nueva: `intl` (mantenida por el equipo de Dart, BSD-3) y `flutter_localizations` (SDK).
