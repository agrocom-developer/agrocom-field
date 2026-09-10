# ADR 0002 — Paquete `decimal` para dinero y hectáreas

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

La invariante 9 de `CLAUDE.md` de este repo prohíbe `double`/`float` para dinero y hectáreas — espejo del lado servidor, donde `agrocom-api` usa `DECIMAL` (nunca `float`) — y explícitamente advierte "no asumir que alcanza sin confirmar qué paquete Dart se adopta antes de introducir el primer cálculo". `docs/api/openapi.yaml` de `agrocom-api` confirma el mismo criterio del lado contrato: la descripción general del spec declara "Dinero y hectáreas viajan como string decimal, nunca como número de punto flotante", y cada campo `DECIMAL` del modelo de datos relevante para esta app (dosis, litros de caldo, hectáreas declaradas y acumuladas, límites climáticos y de vuelo) está anotado explícitamente como "DECIMAL como string" en la especificación de cada endpoint. Este repo necesita fijar, antes del primer cálculo real, qué tipo Dart representa esos valores tanto al deserializar el JSON de la API como al mostrarlos en pantalla.

## Decisión

Paquete `decimal` de pub.dev para todo valor que en el contrato de API viaja como string decimal: litros de caldo, hectáreas, y dinero si algún día llega a mostrarse en esta app (hoy no es responsabilidad de esta app — ver "Qué NO hace esta app" en `docs/vision.md`).

Se define un `JsonConverter<Decimal, String>` en `lib/nucleo/tipos/decimal_json_converter.dart`, para usar con los DTOs `freezed`/`json_serializable` del cliente de API (ADR 0001 de este repo). Queda anotado, sin crearse todavía — no hay ninguna columna que lo necesite en el outbox mínimo de arranque —, que hará falta un `TypeConverter<Decimal, String>` equivalente para columnas `drift` el día que una tabla de negocio necesite guardar un valor decimal.

## Alternativas descartadas

- **`double`**: prohibido explícitamente por la invariante 9 de `CLAUDE.md` — el mismo problema de precisión de punto flotante que ya se evitó del lado servidor con `DECIMAL`.
- **Enteros con un factor de escala fijo** (tipo centavos): fragiliza el modelo ante litros o dosis con precisión variable, y obliga a manejar el factor de escala a mano en cada cálculo — un costo de mantenimiento que el paquete `decimal` ya resuelve.
- **Paquete `money2`**: modela específicamente dinero/moneda; no cubre naturalmente hectáreas ni litros, que son la mayoría de los valores decimales que esta app maneja hoy (esta app ni siquiera formula mezcla — ver "Qué NO hace esta app" en `docs/vision.md`), así que dinero es, en el mejor de los casos, secundario acá.

## Consecuencias

- Todo cálculo mostrado en pantalla o serializado hacia la API pasa por `Decimal`, nunca por aritmética de `double` intermedia.
- `modelo-datos-flutter` debe reutilizar este mismo paquete (no reinventar otro) el día que agregue la primera columna decimal de negocio en `drift`, y crear en ese momento el `TypeConverter` equivalente al `JsonConverter` ya definido acá.
- `flutter-ui` no debería formatear un `Decimal` convirtiéndolo primero a `double` para mostrarlo — el paquete `decimal` expone su propio formateo; hacerlo así reintroduce el problema que esta decisión evita.
