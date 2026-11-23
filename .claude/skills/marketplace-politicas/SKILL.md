---
name: marketplace-politicas
description: Resumen operativo de las políticas del marketplace de fumigación con drones de Agrocom — roles, ciclo de una solicitud, asignación (propios primero, luego terceros), calificaciones, comisión, aprobaciones y excepciones de red. Usar antes de diseñar o implementar cualquier pantalla, caso de uso o regla que dependa de quién puede hacer qué y cuándo.
---

# Políticas del marketplace — referencia operativa

Agrocom es un marketplace de servicio de fumigación con drones, al estilo de las plataformas de transporte bajo demanda. El cliente solicita un servicio; los proveedores lo ejecutan; los drones son los "vehículos". Agrocom capta clientes, es el nexo y además es proveedor propio. Su negocio incluye vender drones y entregar a cada comprador trabajo asegurado. Cada regla de abajo es una decisión revisable: si cambia, se cambia aquí y en la especificación de `agrocom-api` (`docs/especificacion/`, ruta local `/Applications/MAMP/htdocs/agrocom-api`), no en el código solamente.

## Roles

| Rol | Qué hace | Superficie |
|---|---|---|
| Cliente | Solicita un servicio, sigue su estado, califica al proveedor | Flavor `cliente` (online-first, sin outbox) |
| Piloto | Acepta o rechaza ofertas, ejecuta el vuelo, registra la sesión; puede registrar a su auxiliar | Flavor `piloto` |
| Auxiliar | Prepara la mezcla y apoya en el lote | Flavor `auxiliar` |
| Proveedor independiente / dueño de drones | Se registra solo, opera con sus drones y auxiliares tras aprobación | Pilotos y panel web |
| Piloto propio de Agrocom | Recibe las ofertas primero | Flavor `piloto` |
| Admin | Aprueba proveedores y auxiliares, modera calificaciones, supervisa | Panel web de `agrocom-api` |

## Ciclo de una solicitud

solicitada → buscando proveedor → asignada → en ejecución → finalizada → calificada. Todo es solicitud por solicitud: no hay contratos ni campañas.

## Asignación

1. Primero pilotos y drones propios de Agrocom.
2. Si ninguno acepta dentro de la ventana, o ninguno está disponible, se ofrece a terceros, escalando por radio o zona y ordenando por calificación.
3. El servidor decide al recibir la primera aceptación válida.
El detalle de tiempos y casos límite lo mantiene el agente `asignacion-matching`.

## Reglas de red

- **Aceptar o rechazar una oferta requiere red** (excepción documentada): la confirma el servidor.
- **Lo ejecutado en el lote sigue offline**: sesiones, hectáreas, mezcla y evidencias se guardan en local y se sincronizan después (skill `protocolo-sync`).
- El flavor `cliente` lee de la red con caché local y muestra estados de carga, error y reintento.

## Calificaciones

El cliente califica al proveedor en un registro propio. El proveedor solo ve su calificación; no la edita. El admin modera (oculta o corrige abusos con motivo y autor). También existe calificación del cliente por el proveedor, visible solo para admin y para la asignación de proveedores. Una calificación confirmada no se reescribe: se agrega un registro de moderación.

## Dinero

La primera versión no cobra dentro de la app. El modelo de comisión (porcentaje de la plataforma sobre el servicio finalizado) está documentado en la especificación y se liquida fuera de la app. Dinero y hectáreas usan siempre un tipo decimal exacto, nunca `double`.

## Alta y aprobación

- El proveedor independiente se registra solo; un admin lo aprueba antes de que reciba ofertas.
- El piloto de un proveedor registra a su auxiliar; un admin lo aprueba antes de que opere.

## Lo que no existe

Contratos, campañas, inventario, mantenimiento, planilla ni contabilidad internos. De mantenimiento solo se conservan los ciclos de batería, dentro del dron.

## Quién decide qué

Regla nueva de producto: `producto-marketplace`. Despacho: `asignacion-matching`. Verificación, abuso y privacidad: `confianza-seguridad`. Una regla que cambia el backend se pide a `agrocom-api` (`docs/gestion/peticiones_agrocom_api/`).
