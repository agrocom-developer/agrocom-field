# Plan 03 · Retiro del flavor `auxiliar`

**Estado: decidido (ADR 0021).** El flavor se retira; el esquema local no se toca en este cambio.

**Qué cambia.** Quedan dos flavors, `cliente` y `piloto`. El auxiliar deja de ser usuario de la app y el piloto no lo registra ni lo ve (ADR 0021).

## Fases

1. **Decisión y ADR.** Nuevo ADR que reemplaza el 0005 (selector de rol del flavor `auxiliar`) y ajusta el 0009. Se confirma con `agrocom-api` si el rol `auxiliar` se conserva como dato del equipo.
2. **API primero.** Revisar endpoints y reglas que dependen del rol activo `auxiliar`; el contrato manda. Cualquier retiro de tabla o columna es migración con `down` y se avisa en el PR.
3. **App.** Quitar `lib/auxiliar/`, `lib/main_auxiliar.dart`, el flavor de Gradle, el esquema de Xcode y los `xcconfig`, `Podfile`, `pubspec.yaml`, `tool/capturar_pantallas.sh`, el job de `ci.yml` y los textos que lo nombran (≈130 archivos lo mencionan).
4. **Datos locales.** Si el esquema `drift` tiene tablas que solo el auxiliar escribía (mezcla, por ejemplo), la migración exige respaldo, camino de vuelta y prueba con datos reales. **Revisión línea por línea del dueño.**
5. **Documentación.** `CLAUDE.md`, `docs/vision.md`, README y los planes pasan a dos flavors. Las invariantes del lote pasan a hablar solo del piloto.

## Riesgos

El motor de sync y el esquema local son críticos: no se borra nada sin la prueba de replay verde y sin aviso. Un piloto con sesiones pendientes de sincronizar no puede perderlas.
