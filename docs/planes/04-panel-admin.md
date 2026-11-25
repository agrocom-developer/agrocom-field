# Plan 04 · Panel web admin

**Objetivo.** Que el panel (`agrocom-api`, AdminLTE y Livewire) hable el mismo lenguaje visual que la app: los mismos colores y las mismas fuentes.

**Punto de partida.** El panel ya tiene tokens en dos capas (`resources/css/tokens/primitives/` y `semantic/`, con tema claro y oscuro). Los primitivos de marca (`brand.css`) derivan del logo (verde `#8CC63F` a `#1E7A34`, ámbar `#F5A623` a `#E8720C`) y la tipografía es IBM Plex Sans y Plex Mono. La app pasa a Manrope y JetBrains Mono.

## Fases

| Fase | Qué | Criterio |
|---|---|---|
| 1 | Reemplazar `brand.css` por los valores de `tokens.json` (verde `#347A36`, grafito `#29343A`, ámbar `#F5A623` con contenedores) sin tocar componentes: todo pasa por los tokens semánticos | Contraste AA en ambos temas; nada fuera de `semantic/` usa un hex |
| 2 | Manrope y JetBrains Mono en `--ag-font-family-base` y `--ag-font-family-mono`, con la fuente cargada localmente | Cifras de tablas y métricas en mono |
| 3 | Pantallas con más valor del negociador: solicitudes y ofertas, rondas de negociación, disputas, aprobación de proveedores y dron | Sin tablas donde convenga mostrar la conversación |
| 4 | Gráficas y PDF con los mismos tokens (los PDF ya usan tokens de color) | Una sola fuente de color |

**Dependencia.** Se hace en `agrocom-api` con su flujo (worktree desde `origin/develop`, PR, CI). La fuente de verdad de los valores es `tokens.json` de este repo.
