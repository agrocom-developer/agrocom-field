# Plan 06 · Backend pendiente

Trabajo de `agrocom-api` que la app espera. Los bloques A y B corren en paralelo; C va después.

| Bloque | Qué | Estado |
|---|---|---|
| A | `neg_vencer_ofertas()` por lote y trigger de bitácora e inmutabilidad de lo validado (hallazgos L3 y L4 de la auditoría), con migración reversible probada en base temporal | En curso |
| B | `/api/ofertas` devuelve zona y lote; la app los usa en «Mis ofertas»; limpieza de worktrees ya integrados | En curso |
| C | Partir `UsuariosController` en casos de uso y `FormRequest` (L6); dividir `Negociar` y `Seguimiento` (L7, L9); validar con `FormRequest` los 16 controladores con validación inline; textos de la app a l10n por módulos; capturas reales del recorrido; revisar el verde lima del modo campo en el botón «Ya recibí el pago» | Pendiente de A y B |

**Revisión humana, sin automatizar.** Esquema `drift` y motor de sync (app); `Negociar::aceptar`, `Participantes` y `UbicacionDelPiloto`; y L5 (`EscrituraSincronizacionEloquent`). Del dueño: proveedor de push real y sus credenciales, reglas de las ramas protegidas, secretos de firma, visibilidad de los repos y el emulador de Android.
