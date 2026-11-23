# Política de seguridad

## Versiones con soporte

Se mantiene la última versión publicada desde `master`. Las correcciones de
seguridad se integran en `develop` y se liberan en la siguiente versión.

## Cómo reportar una vulnerabilidad

No abras un issue público. Usa el reporte privado de GitHub:
**Security → Report a vulnerability** en este repositorio. Incluye:

- Descripción e impacto.
- Pasos para reproducir (flavor, versión, dispositivo).
- Si afecta datos de campo o la sesión, indícalo.

Se responde en un plazo de 5 días hábiles y se informa la fecha estimada de
corrección.

## Alcance

La app móvil Agrocom (flavors cliente, piloto y auxiliar): almacenamiento
local, sesión, sincronización, evidencias y configuración de compilación.
La API y el panel web se reportan en `agrocom-api`.

## Controles vigentes

- Sin secretos en el repositorio: la firma de release se inyecta por secrets
  (`docs/seguridad/firma-release.md`).
- Tráfico en claro prohibido en release; `http` solo en debug.
- Sin copias de respaldo del almacenamiento de la app.
- CI con permisos mínimos, acciones fijadas por SHA, análisis de
  vulnerabilidades en dependencias y Dependabot.
- Rutas sensibles protegidas por CODEOWNERS (`docs/seguridad/rulesets.md`).
