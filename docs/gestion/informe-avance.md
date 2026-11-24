# Informe de avance de la app móvil

Estado de `agrocom-field` sobre `develop` al cierre del QA visual: qué se construyó en cada flavor, qué se ejecutó en `agrocom-api`, qué falta, qué riesgos hay y qué debe revisar una persona. Las capturas son del simulador de iOS (iPhone 17 Pro e iPad Pro 11 pulgadas) con cada flavor en modo demo (ADR 0010); no hay emulador de Android instalado en esta máquina.

## Resumen

- Los tres flavors tienen su recorrido completo de interfaz sobre repositorios demo en memoria: **cliente** (arranque, presentación, ingreso, registro, inicio, solicitar, buscar proveedor, mis servicios, seguimiento en vivo, conformidad, calificación, cuenta), **piloto** (ofertas, servicio asignado, sesión de vuelo, drones, perfil) y **auxiliar** (servicio, mezcla, ofertas, perfil, drones).
- El sistema visual es común a los tres (`docs/diseno/sistema-visual.md`): claro y oscuro en el cliente, modo campo de alto contraste en piloto y auxiliar.
- Lo que falta es el cableado: ninguna pantalla del marketplace lee todavía de la red ni de `drift`. El contrato de `agrocom-api` ya publica ofertas, solicitudes, calificaciones y proveedores; el esquema local del marketplace y los repositorios de red son la siguiente fase.
- Este QA agrega capturas de las tres superficies (154 del cliente, 27 del piloto y 30 del auxiliar), una auditoría de accesibilidad automática de las pantallas raíz y las correcciones que salieron de ambas.

## Qué hay construido por flavor

Cada tabla enlaza las capturas del simulador. Las pantallas se recorren con `integration_test/` y se capturan con `xcrun simctl io` (ver «Cómo regenerar las capturas»).

### Cliente (online-first, sin outbox)

Entrada: arranque, tres pasos de presentación, ingreso y registro. Dentro: Inicio (servicio activo, avisos, por calificar), Solicitar (lote en el mapa o dibujado, aplicación, fecha y horario, resumen con precio estimado, confirmación con clave de idempotencia), búsqueda de proveedor con radar, Servicios (resumen de hectáreas, filtros, detalle con línea de tiempo), seguimiento en vivo sobre el mapa, acta de conformidad con evidencias, calificación de dos toques, reporte de problema y Cuenta. En iPad la navegación pasa a riel lateral y el inicio y la solicitud usan dos columnas.

**iPhone 17 Pro** (`docs/diseno/capturas/cliente/iphone17pro/`)

| Pantalla | Capturas |
|---|---|
| Arranque | [claro](../diseno/capturas/cliente/iphone17pro/cliente_01_splash_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_01_splash_oscuro.jpg) |
| Presentación, paso 1 | [claro](../diseno/capturas/cliente/iphone17pro/cliente_02_onboarding_1_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_02_onboarding_1_oscuro.jpg) |
| Presentación, paso 2 | [claro](../diseno/capturas/cliente/iphone17pro/cliente_03_onboarding_2_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_03_onboarding_2_oscuro.jpg) |
| Presentación, paso 3 | [claro](../diseno/capturas/cliente/iphone17pro/cliente_04_onboarding_3_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_04_onboarding_3_oscuro.jpg) |
| Ingreso | [claro](../diseno/capturas/cliente/iphone17pro/cliente_05_login_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_05_login_oscuro.jpg) |
| Registro | [claro](../diseno/capturas/cliente/iphone17pro/cliente_06_registro_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_06_registro_oscuro.jpg) |
| Inicio | [claro](../diseno/capturas/cliente/iphone17pro/cliente_07_inicio_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_07_inicio_oscuro.jpg) |
| Inicio, avisos y por calificar | [claro](../diseno/capturas/cliente/iphone17pro/cliente_08_inicio_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_08_inicio_abajo_oscuro.jpg) |
| Solicitar, paso 1 (lote) | [claro](../diseno/capturas/cliente/iphone17pro/cliente_09_solicitar_lote_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_09_solicitar_lote_oscuro.jpg) |
| Solicitar, lote elegido | [claro](../diseno/capturas/cliente/iphone17pro/cliente_10_solicitar_lote_elegido_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_10_solicitar_lote_elegido_oscuro.jpg) |
| Solicitar, paso 2 (aplicación) | [claro](../diseno/capturas/cliente/iphone17pro/cliente_11_solicitar_aplicacion_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_11_solicitar_aplicacion_oscuro.jpg) |
| Solicitar, producto y dosis | [claro](../diseno/capturas/cliente/iphone17pro/cliente_12_solicitar_producto_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_12_solicitar_producto_oscuro.jpg) |
| Solicitar, paso 3 (cuándo) | [claro](../diseno/capturas/cliente/iphone17pro/cliente_13_solicitar_cuando_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_13_solicitar_cuando_oscuro.jpg) |
| Solicitar, resumen y precio | [claro](../diseno/capturas/cliente/iphone17pro/cliente_14_solicitar_resumen_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_14_solicitar_resumen_oscuro.jpg) |
| Búsqueda de proveedor | [claro](../diseno/capturas/cliente/iphone17pro/cliente_15_buscando_proveedor_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_15_buscando_proveedor_oscuro.jpg) |
| Servicio buscando proveedor | [claro](../diseno/capturas/cliente/iphone17pro/cliente_16_servicio_buscando_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_16_servicio_buscando_oscuro.jpg) |
| Mis servicios | [claro](../diseno/capturas/cliente/iphone17pro/cliente_17_servicios_lista_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_17_servicios_lista_oscuro.jpg) |
| Servicio en ejecución | [claro](../diseno/capturas/cliente/iphone17pro/cliente_18_servicio_en_curso_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_18_servicio_en_curso_oscuro.jpg) |
| Servicio en ejecución, quién fumiga | [claro](../diseno/capturas/cliente/iphone17pro/cliente_19_servicio_en_curso_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_19_servicio_en_curso_abajo_oscuro.jpg) |
| Seguimiento en vivo | [claro](../diseno/capturas/cliente/iphone17pro/cliente_20_seguimiento_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_20_seguimiento_oscuro.jpg) |
| Seguimiento, hoja inferior | [claro](../diseno/capturas/cliente/iphone17pro/cliente_21_seguimiento_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_21_seguimiento_abajo_oscuro.jpg) |
| Servicio por conformar | [claro](../diseno/capturas/cliente/iphone17pro/cliente_22_servicio_por_conformar_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_22_servicio_por_conformar_oscuro.jpg) |
| Acta de conformidad | [claro](../diseno/capturas/cliente/iphone17pro/cliente_23_acta_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_23_acta_oscuro.jpg) |
| Acta, evidencias | [claro](../diseno/capturas/cliente/iphone17pro/cliente_24_acta_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_24_acta_abajo_oscuro.jpg) |
| Confirmar conformidad | [claro](../diseno/capturas/cliente/iphone17pro/cliente_25_confirmar_conformidad_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_25_confirmar_conformidad_oscuro.jpg) |
| Calificar | [claro](../diseno/capturas/cliente/iphone17pro/cliente_26_calificar_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_26_calificar_oscuro.jpg) |
| Calificar, con estrellas | [claro](../diseno/capturas/cliente/iphone17pro/cliente_27_calificar_estrellas_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_27_calificar_estrellas_oscuro.jpg) |
| Gracias por calificar | [claro](../diseno/capturas/cliente/iphone17pro/cliente_28_calificado_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_28_calificado_oscuro.jpg) |
| Servicio calificado | [claro](../diseno/capturas/cliente/iphone17pro/cliente_29_servicio_calificado_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_29_servicio_calificado_oscuro.jpg) |
| Cuenta | [claro](../diseno/capturas/cliente/iphone17pro/cliente_30_cuenta_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_30_cuenta_oscuro.jpg) |
| Cuenta, reseñas | [claro](../diseno/capturas/cliente/iphone17pro/cliente_31_cuenta_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/iphone17pro/cliente_31_cuenta_abajo_oscuro.jpg) |

**iPad Pro 11 pulgadas** (`docs/diseno/capturas/cliente/ipadpro11/`)

| Pantalla | Capturas |
|---|---|
| Arranque | [claro](../diseno/capturas/cliente/ipadpro11/cliente_01_splash_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_01_splash_oscuro.jpg) |
| Presentación, paso 1 | [claro](../diseno/capturas/cliente/ipadpro11/cliente_02_onboarding_1_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_02_onboarding_1_oscuro.jpg) |
| Presentación, paso 2 | [claro](../diseno/capturas/cliente/ipadpro11/cliente_03_onboarding_2_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_03_onboarding_2_oscuro.jpg) |
| Presentación, paso 3 | [claro](../diseno/capturas/cliente/ipadpro11/cliente_04_onboarding_3_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_04_onboarding_3_oscuro.jpg) |
| Ingreso | [claro](../diseno/capturas/cliente/ipadpro11/cliente_05_login_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_05_login_oscuro.jpg) |
| Registro | [claro](../diseno/capturas/cliente/ipadpro11/cliente_06_registro_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_06_registro_oscuro.jpg) |
| Inicio | [claro](../diseno/capturas/cliente/ipadpro11/cliente_07_inicio_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_07_inicio_oscuro.jpg) |
| Inicio, avisos y por calificar | [claro](../diseno/capturas/cliente/ipadpro11/cliente_08_inicio_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_08_inicio_abajo_oscuro.jpg) |
| Solicitar, paso 1 (lote) | [claro](../diseno/capturas/cliente/ipadpro11/cliente_09_solicitar_lote_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_09_solicitar_lote_oscuro.jpg) |
| Solicitar, lote elegido | [claro](../diseno/capturas/cliente/ipadpro11/cliente_10_solicitar_lote_elegido_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_10_solicitar_lote_elegido_oscuro.jpg) |
| Solicitar, paso 2 (aplicación) | [claro](../diseno/capturas/cliente/ipadpro11/cliente_11_solicitar_aplicacion_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_11_solicitar_aplicacion_oscuro.jpg) |
| Solicitar, producto y dosis | [claro](../diseno/capturas/cliente/ipadpro11/cliente_12_solicitar_producto_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_12_solicitar_producto_oscuro.jpg) |
| Solicitar, paso 3 (cuándo) | [claro](../diseno/capturas/cliente/ipadpro11/cliente_13_solicitar_cuando_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_13_solicitar_cuando_oscuro.jpg) |
| Solicitar, resumen y precio | [claro](../diseno/capturas/cliente/ipadpro11/cliente_14_solicitar_resumen_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_14_solicitar_resumen_oscuro.jpg) |
| Búsqueda de proveedor | [claro](../diseno/capturas/cliente/ipadpro11/cliente_15_buscando_proveedor_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_15_buscando_proveedor_oscuro.jpg) |
| Servicio buscando proveedor | [claro](../diseno/capturas/cliente/ipadpro11/cliente_16_servicio_buscando_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_16_servicio_buscando_oscuro.jpg) |
| Mis servicios | [claro](../diseno/capturas/cliente/ipadpro11/cliente_17_servicios_lista_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_17_servicios_lista_oscuro.jpg) |
| Servicio en ejecución | [claro](../diseno/capturas/cliente/ipadpro11/cliente_18_servicio_en_curso_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_18_servicio_en_curso_oscuro.jpg) |
| Servicio en ejecución, quién fumiga | [claro](../diseno/capturas/cliente/ipadpro11/cliente_19_servicio_en_curso_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_19_servicio_en_curso_abajo_oscuro.jpg) |
| Seguimiento en vivo | [claro](../diseno/capturas/cliente/ipadpro11/cliente_20_seguimiento_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_20_seguimiento_oscuro.jpg) |
| Seguimiento, hoja inferior | [claro](../diseno/capturas/cliente/ipadpro11/cliente_21_seguimiento_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_21_seguimiento_abajo_oscuro.jpg) |
| Servicio por conformar | [claro](../diseno/capturas/cliente/ipadpro11/cliente_22_servicio_por_conformar_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_22_servicio_por_conformar_oscuro.jpg) |
| Acta de conformidad | [claro](../diseno/capturas/cliente/ipadpro11/cliente_23_acta_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_23_acta_oscuro.jpg) |
| Acta, evidencias | [claro](../diseno/capturas/cliente/ipadpro11/cliente_24_acta_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_24_acta_abajo_oscuro.jpg) |
| Confirmar conformidad | [claro](../diseno/capturas/cliente/ipadpro11/cliente_25_confirmar_conformidad_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_25_confirmar_conformidad_oscuro.jpg) |
| Calificar | [claro](../diseno/capturas/cliente/ipadpro11/cliente_26_calificar_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_26_calificar_oscuro.jpg) |
| Calificar, con estrellas | [claro](../diseno/capturas/cliente/ipadpro11/cliente_27_calificar_estrellas_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_27_calificar_estrellas_oscuro.jpg) |
| Gracias por calificar | [claro](../diseno/capturas/cliente/ipadpro11/cliente_28_calificado_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_28_calificado_oscuro.jpg) |
| Servicio calificado | [claro](../diseno/capturas/cliente/ipadpro11/cliente_29_servicio_calificado_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_29_servicio_calificado_oscuro.jpg) |
| Cuenta | [claro](../diseno/capturas/cliente/ipadpro11/cliente_30_cuenta_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_30_cuenta_oscuro.jpg) |
| Cuenta, reseñas | [claro](../diseno/capturas/cliente/ipadpro11/cliente_31_cuenta_abajo_claro.jpg) · [oscuro](../diseno/capturas/cliente/ipadpro11/cliente_31_cuenta_abajo_oscuro.jpg) |

### Piloto (modo campo; ofertas con red, ejecución offline)

Ofertas con cuenta regresiva, mapa del lote, pago y distancia; aceptar y rechazar (con red); servicio asignado con progreso de hectáreas; detalle del servicio legible sin señal; sesión de vuelo (apertura con condiciones, sesión en curso, cierre, incidencias con foto, emergencia); drones con ciclos de batería; perfil con aprobación, métricas, documentos y calificaciones.

**iPhone 17 Pro** (`docs/diseno/capturas/piloto/iphone17pro/`)

| Pantalla | Capturas |
|---|---|
| Ofertas | [campo](../diseno/capturas/piloto/iphone17pro/piloto_01_ofertas_campo.jpg) |
| Detalle de la oferta y mapa | [campo](../diseno/capturas/piloto/iphone17pro/piloto_02_oferta_detalle_campo.jpg) |
| Detalle de la oferta, datos | [campo](../diseno/capturas/piloto/iphone17pro/piloto_03_oferta_detalle_abajo_campo.jpg) |
| Mis servicios | [campo](../diseno/capturas/piloto/iphone17pro/piloto_04_servicio_campo.jpg) |
| Mis servicios (continuación) | [campo](../diseno/capturas/piloto/iphone17pro/piloto_05_servicio_abajo_campo.jpg) |
| Detalle del servicio asignado | [campo](../diseno/capturas/piloto/iphone17pro/piloto_06_servicio_detalle_campo.jpg) |
| Detalle del servicio, datos | [campo](../diseno/capturas/piloto/iphone17pro/piloto_07_servicio_detalle_abajo_campo.jpg) |
| Sesión de vuelo, sin abrir | [campo](../diseno/capturas/piloto/iphone17pro/piloto_08_sesion_apertura_campo.jpg) |
| Sesión de vuelo (continuación) | [campo](../diseno/capturas/piloto/iphone17pro/piloto_09_sesion_apertura_abajo_campo.jpg) |

**iPad Pro 11 pulgadas** (`docs/diseno/capturas/piloto/ipadpro11/`)

| Pantalla | Capturas |
|---|---|
| Ofertas | [campo](../diseno/capturas/piloto/ipadpro11/piloto_01_ofertas_campo.jpg) |
| Detalle de la oferta y mapa | [campo](../diseno/capturas/piloto/ipadpro11/piloto_02_oferta_detalle_campo.jpg) |
| Detalle de la oferta, datos | [campo](../diseno/capturas/piloto/ipadpro11/piloto_03_oferta_detalle_abajo_campo.jpg) |
| Mis servicios | [campo](../diseno/capturas/piloto/ipadpro11/piloto_04_servicio_campo.jpg) |
| Mis servicios (continuación) | [campo](../diseno/capturas/piloto/ipadpro11/piloto_05_servicio_abajo_campo.jpg) |
| Detalle del servicio asignado | [campo](../diseno/capturas/piloto/ipadpro11/piloto_06_servicio_detalle_campo.jpg) |
| Detalle del servicio, datos | [campo](../diseno/capturas/piloto/ipadpro11/piloto_07_servicio_detalle_abajo_campo.jpg) |
| Sesión de vuelo, sin abrir | [campo](../diseno/capturas/piloto/ipadpro11/piloto_08_sesion_apertura_campo.jpg) |
| Sesión de vuelo (continuación) | [campo](../diseno/capturas/piloto/ipadpro11/piloto_09_sesion_apertura_abajo_campo.jpg) |

### Auxiliar (modo campo; offline en el lote)

Servicio con caldo a preparar y datos del lote, mezcla con cargas registradas y estado de sincronización por carga, ofertas del auxiliar, perfil y drones del proveedor.

**iPhone 17 Pro** (`docs/diseno/capturas/auxiliar/iphone17pro/`)

| Pantalla | Capturas |
|---|---|
| Servicio | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_01_servicio_campo.jpg) |
| Servicio (continuación) | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_02_servicio_abajo_campo.jpg) |
| Mezcla | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_03_mezcla_campo.jpg) |
| Mezcla (continuación) | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_04_mezcla_abajo_campo.jpg) |
| Ofertas | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_06_ofertas_campo.jpg) |
| Detalle de la oferta | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_07_oferta_detalle_campo.jpg) |
| Detalle de la oferta, datos | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_08_oferta_detalle_abajo_campo.jpg) |
| Perfil | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_09_perfil_campo.jpg) |
| Perfil, documentos | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_10_perfil_abajo_campo.jpg) |
| Mis drones | [campo](../diseno/capturas/auxiliar/iphone17pro/auxiliar_11_drones_campo.jpg) |

**iPad Pro 11 pulgadas** (`docs/diseno/capturas/auxiliar/ipadpro11/`)

| Pantalla | Capturas |
|---|---|
| Servicio | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_01_servicio_campo.jpg) |
| Servicio (continuación) | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_02_servicio_abajo_campo.jpg) |
| Mezcla | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_03_mezcla_campo.jpg) |
| Mezcla (continuación) | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_04_mezcla_abajo_campo.jpg) |
| Ofertas | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_06_ofertas_campo.jpg) |
| Detalle de la oferta | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_07_oferta_detalle_campo.jpg) |
| Detalle de la oferta, datos | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_08_oferta_detalle_abajo_campo.jpg) |
| Perfil | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_09_perfil_campo.jpg) |
| Perfil, documentos | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_10_perfil_abajo_campo.jpg) |
| Mis drones | [campo](../diseno/capturas/auxiliar/ipadpro11/auxiliar_11_drones_campo.jpg) |

## Qué se ejecutó en la API

`agrocom-api` integró en `develop` (Pull Requests a `develop`):

| PR | Qué entregó |
|---|---|
| #316 | Especificación del marketplace de fumigación con drones |
| #317 | Endurecimiento de CI/CD y seguridad |
| #318 | Agentes y skills de la API para el marketplace |
| #319 | CI por impacto |
| #320 | Retiro de la operación interna: finanzas, inventario y mantenimiento de flota |
| #321 | Dominio de proveedores y flota del marketplace |
| #322 | Solicitud de servicio y trabajo; retiro del modelo de contratos |
| #323 | Motor de asignación: propios primero, luego terceros |
| #324 | Calificaciones, disputas, comisión y métricas |

Antes del marketplace quedaron integrados los PR #309 a #314 de la línea del motor de sincronización (límites efectivos por trabajo, validación de condiciones, trabajos dados de baja), de los que el esquema local y el motor de sync de esta app dependen.

## Qué se ejecutó en la app

| PR | Qué entregó |
|---|---|
| #75 | Servidor MCP de control de la migración |
| #76 | CI/CD y seguridad de la app |
| #77, #78 | Agentes, skills y documentación del marketplace |
| #79 | Sistema visual de los tres flavors |
| #80 | CI por impacto |
| #81 | Fundación de UI: iOS, flavor cliente y modo demo |
| #82 | Acceso e inicio del cliente |
| #83 | Ofertas, perfil y drones del proveedor |
| #84 | Servicio y sesión de vuelo en el lote |
| #85 | Seguimiento, conformidad y calificación del cliente |
| #86 | Solicitar fumigación |

El estado fila por fila de la cola está en [cola_tareas.md](cola_tareas.md).

## Auditoría de QA visual

Método: cada flavor corre en modo demo en el simulador, una prueba de `integration_test/` recorre las pantallas, el script `tool/capturar_pantallas.sh` toma la captura con `xcrun simctl io` y la compara a ojo con el sistema visual. Además, `test/ui/ui_qa_accesibilidad` aplica las guías de accesibilidad de Flutter a las cuatro pestañas de cada flavor, en 360x640 y 412x915, con texto al 100 % y al 200 %, en claro y oscuro (cliente) o modo campo (piloto y auxiliar).

| Aspecto | Resultado |
|---|---|
| Contraste | Los ratios de la paleta los vigila `test/nucleo/ui/paleta_campo_test.dart`; la guía `textContrastGuideline` pasa en las 16 combinaciones auditadas. |
| Objetivos táctiles | `androidTapTargetGuideline` (48 dp), `iOSTapTargetGuideline` (44 pt) y `labeledTapTargetGuideline` pasan en las pestañas raíz de los tres flavors. |
| Texto dinámico | Con escala 2,0 se encontraron cuatro desbordes y con el texto del sistema en su tamaño máximo de accesibilidad (muy superior al 200 %) uno más, el de la atribución del mapa (ver correcciones); corregidos. En ese tamaño máximo los títulos grandes parten palabras largas («servicio-s»); el producto no limita la escala del texto y conviene decidir un tope de 200 %. Capturas con el texto en su tamaño máximo: [auxiliar: 01_servicio_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_01_servicio_campo.jpg) · [auxiliar: 02_servicio_abajo_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_02_servicio_abajo_campo.jpg) · [auxiliar: 03_mezcla_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_03_mezcla_campo.jpg) · [auxiliar: 04_mezcla_abajo_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_04_mezcla_abajo_campo.jpg) · [auxiliar: 06_ofertas_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_06_ofertas_campo.jpg) · [auxiliar: 07_oferta_detalle_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_07_oferta_detalle_campo.jpg) · [auxiliar: 08_oferta_detalle_abajo_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_08_oferta_detalle_abajo_campo.jpg) · [auxiliar: 09_perfil_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_09_perfil_campo.jpg) · [auxiliar: 10_perfil_abajo_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_10_perfil_abajo_campo.jpg) · [auxiliar: 11_drones_campo](../diseno/capturas/auxiliar/iphone17pro-texto200/auxiliar_11_drones_campo.jpg) · [cliente: 01_splash_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_01_splash_claro.jpg) · [cliente: 02_onboarding_1_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_02_onboarding_1_claro.jpg) · [cliente: 03_onboarding_2_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_03_onboarding_2_claro.jpg) · [cliente: 04_onboarding_3_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_04_onboarding_3_claro.jpg) · [cliente: 05_login_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_05_login_claro.jpg) · [cliente: 06_registro_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_06_registro_claro.jpg) · [cliente: 07_inicio_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_07_inicio_claro.jpg) · [cliente: 08_inicio_abajo_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_08_inicio_abajo_claro.jpg) · [cliente: 09_solicitar_lote_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_09_solicitar_lote_claro.jpg) · [cliente: 10_solicitar_lote_elegido_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_10_solicitar_lote_elegido_claro.jpg) · [cliente: 11_solicitar_aplicacion_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_11_solicitar_aplicacion_claro.jpg) · [cliente: 12_solicitar_producto_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_12_solicitar_producto_claro.jpg) · [cliente: 13_solicitar_cuando_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_13_solicitar_cuando_claro.jpg) · [cliente: 14_solicitar_resumen_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_14_solicitar_resumen_claro.jpg) · [cliente: 15_buscando_proveedor_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_15_buscando_proveedor_claro.jpg) · [cliente: 16_servicio_buscando_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_16_servicio_buscando_claro.jpg) · [cliente: 17_servicios_lista_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_17_servicios_lista_claro.jpg) · [cliente: 18_servicio_en_curso_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_18_servicio_en_curso_claro.jpg) · [cliente: 19_servicio_en_curso_abajo_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_19_servicio_en_curso_abajo_claro.jpg) · [cliente: 20_seguimiento_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_20_seguimiento_claro.jpg) · [cliente: 21_seguimiento_abajo_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_21_seguimiento_abajo_claro.jpg) · [cliente: 22_servicio_por_conformar_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_22_servicio_por_conformar_claro.jpg) · [cliente: 23_acta_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_23_acta_claro.jpg) · [cliente: 24_acta_abajo_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_24_acta_abajo_claro.jpg) · [cliente: 25_confirmar_conformidad_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_25_confirmar_conformidad_claro.jpg) · [cliente: 26_calificar_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_26_calificar_claro.jpg) · [cliente: 27_calificar_estrellas_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_27_calificar_estrellas_claro.jpg) · [cliente: 28_calificado_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_28_calificado_claro.jpg) · [cliente: 30_cuenta_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_30_cuenta_claro.jpg) · [cliente: 31_cuenta_abajo_claro](../diseno/capturas/cliente/iphone17pro-texto200/cliente_31_cuenta_abajo_claro.jpg) · [piloto: 01_ofertas_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_01_ofertas_campo.jpg) · [piloto: 02_oferta_detalle_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_02_oferta_detalle_campo.jpg) · [piloto: 03_oferta_detalle_abajo_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_03_oferta_detalle_abajo_campo.jpg) · [piloto: 04_servicio_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_04_servicio_campo.jpg) · [piloto: 05_servicio_abajo_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_05_servicio_abajo_campo.jpg) · [piloto: 06_servicio_detalle_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_06_servicio_detalle_campo.jpg) · [piloto: 07_servicio_detalle_abajo_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_07_servicio_detalle_abajo_campo.jpg) · [piloto: 08_sesion_apertura_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_08_sesion_apertura_campo.jpg) · [piloto: 09_sesion_apertura_abajo_campo](../diseno/capturas/piloto/iphone17pro-texto200/piloto_09_sesion_apertura_abajo_campo.jpg). |
| Rendimiento | No medido: el simulador de iOS solo corre en modo depuración y los fotogramas de depuración no representan el producto. Pendiente en un dispositivo real con `flutter run --profile` (ver «Qué falta»). |
| Animaciones | Los tokens de `MovimientoCampo` (100 a 320 ms) y la reducción de movimiento los cubren las pruebas existentes; en el simulador el radar de búsqueda y el esqueleto de carga son los únicos bucles. |
| Mapa | Las teselas abiertas de OpenStreetMap rechazan las peticiones del simulador (HTTP 400): en las capturas el mapa puede verse sin teselas. Es la deuda ya registrada en la cola (límites de uso para producción). |

### Correcciones que salieron del QA

- Los textos del cliente pasan a tuteo («Toca una estrella», «Prueba de nuevo», «Lo que dicen de ti»): convivían con voseo en el mismo recorrido. Piloto y auxiliar conservan el voseo del lote.
- La atribución del mapa repetía el símbolo de copyright («© © OpenStreetMap»).
- `InsigniaEstadoServicio`: la etiqueta baja de renglón con texto grande en vez de desbordar la tarjeta (cliente en Inicio y piloto en Servicio).
- Fila de datos del servicio del auxiliar: la etiqueta larga («Capacidad del tanque») ya no empuja el valor fuera de la fila.
- La atribución del mapa deja de escalar con el texto del sistema: a tamaño máximo su fila se salía del mapa en las tarjetas de oferta.
- Ciclos de batería en Drones: la cifra baja de renglón con texto al 200 %.
- Los ADR de `docs/decisiones/` tenían dos con el número 0011; el de acceso e inicio del cliente pasa a 0015.

`./bin/verify --todo` termina en verde con 1061 pruebas (formato, análisis y suite completa).

## Qué falta

1. **Esquema local del marketplace** (tarea 31): el esquema `drift` sigue en la versión 14 sin tablas del servicio asignado. Es crítica y lleva migración con datos y prueba de replay.
2. **Repositorios de red** del cliente y del proveedor (tareas 33 a 40): registro e ingreso, catálogo de servicios asignados, drones, perfil y documentos, bandeja de ofertas (aceptar y rechazar con red), solicitud, seguimiento en vivo y calificación. Hoy todo corre sobre repositorios demo.
3. **Android**: no hay emulador ni `adb` en esta máquina; las capturas y la auditoría visual de Android quedan pendientes.
4. **Rendimiento en dispositivo real**: fotogramas en perfil, en el control remoto del piloto y en un teléfono de gama baja.
5. **Suite `ui_pase_transversal`** de la tarea 47: goldens de estados y escalas de texto por pantalla de piloto y auxiliar.
6. **Canal en vivo de ofertas** (sondeo o notificaciones push) y proveedor de teselas propio para producción.
7. **Modo claro y oscuro en piloto y auxiliar**: la demo solo monta el modo campo; si el dueño quiere que sigan el sistema, es una decisión de producto.

## Riesgos

- **El esquema local y el motor de sync no tienen todavía el marketplace.** Conectar las pantallas a la red sin pasar por `drift` rompería las invariantes 1 y 3 de `CLAUDE.md`; el orden correcto es esquema, replay, repositorios y después pantallas.
- **Aceptar una oferta exige red** y compite contra otros proveedores en una ventana corta: el flujo con red inestable (reintento, oferta perdida, doble toque) solo está cubierto con repositorios demo.
- **Teselas del mapa**: el servidor público de OpenStreetMap no es apto para producción.
- **Rendimiento sin medir** en hardware real, en especial el radar de búsqueda y el seguimiento en vivo sobre el mapa.
- **Dependencia de desarrollo nueva**: `integration_test` (del SDK de Flutter) trae `flutter_driver`, `webdriver` y `sync_http` solo para desarrollo; no entran en la app.

## Qué debe revisar una persona

Según `CLAUDE.md`, la revisión es línea por línea y posterior a la integración:

1. **Esquema `drift` y migraciones locales** (`lib/nucleo/db/`): versión 14; la próxima migración del marketplace pierde datos de campo si está mal escrita. Las migraciones v5 a v14 ya integradas están en `runs/revision-pendiente.txt` y siguen sin revisión.
2. **Motor de sincronización** (`lib/nucleo/sync/`): outbox, replay e idempotencia por `uuid_cliente`.
3. **Aceptar y rechazar ofertas con red** (`lib/nucleo/marketplace/proveedor/ofertas/`): es la excepción documentada a la regla de no esperar al servidor.
4. **Migraciones destructivas**: este PR no agrega ninguna. Las migraciones de la API que retiran la operación interna (#320) y los contratos (#322) pueden borrar tablas y se revisan del lado de `agrocom-api`.
5. **Decisiones de producto y de gusto**: tuteo en el cliente y voseo en el lote, modo campo sin claro y oscuro, y la estética en el emulador de Android.

## Cómo regenerar las capturas

```bash
xcrun simctl boot <id-del-simulador>
tool/capturar_pantallas.sh cliente  <id> iphone17pro claro
tool/capturar_pantallas.sh cliente  <id> iphone17pro oscuro
tool/capturar_pantallas.sh piloto   <id> iphone17pro campo
tool/capturar_pantallas.sh auxiliar <id> iphone17pro campo
```

El script usa `flutter drive` con `integration_test/<flavor>_capturas_test.dart` y el perfil demo. La auditoría de accesibilidad corre con `flutter test test/ui/ui_qa_accesibilidad`.
