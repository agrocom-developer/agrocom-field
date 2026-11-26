---
name: marketplace-politicas
description: Resumen operativo de las políticas del marketplace de fumigación con drones de Agrocom — roles, ciclo de una solicitud, negociación de ofertas por precio por hectárea, qué ve cada parte, calificaciones, precio final sin cobro en la app, aprobaciones y excepciones de red. Usar antes de diseñar o implementar cualquier pantalla, caso de uso o regla que dependa de quién puede hacer qué y cuándo.
---

# Políticas del marketplace — referencia operativa

Agrocom es un marketplace de servicio de fumigación con drones donde el precio se negocia. El cliente publica una solicitud con un precio por hectárea; los pilotos la ven en un mapa y aceptan o contraofertan; el cliente elige. Los drones son los "vehículos". Agrocom es el nexo y el registro del resultado, y además un proveedor propio que compite como cualquier otro. Lo operativo en el lote lo acuerdan en persona las partes. Cada regla de abajo es una decisión revisable: si cambia, se cambia aquí y en la especificación de `agrocom-api` (`docs/especificacion/`, ruta local `/Applications/MAMP/htdocs/agrocom-api`; la lista exacta de estados, reglas y recursos está en `negociacion-contrato.md`), no en el código solamente.

## Roles

| Rol | Qué hace | Superficie |
|---|---|---|
| Cliente | Publica la solicitud con su precio, compara y elige ofertas, ve fotos, chat y ubicación del piloto, califica; debe estar aprobado | Flavor `cliente` (online-first, sin outbox) |
| Proveedor | Ve el mapa de solicitudes abiertas, ofrece, marca inicio, avance y cierre, sube fotos, chatea, ajusta sus avisos de nuevas solicitudes (filtros) y su disponibilidad | Flavor `piloto` |
| Proveedor independiente / dueño de drones / piloto propio de Agrocom | Se registra con datos de la persona y del dron con fotos; opera tras aprobación; compite en igualdad | Flavor `piloto` |
| Admin / operador | Personal de Agrocom: verifica y aprueba clientes y proveedores y drones con sus fotos, modera calificaciones, resuelve reclamos | Panel web de `agrocom-api` |

Cada app admite un solo tipo de cuenta, con su propio usuario, verificación y aprobación; una persona tiene a lo sumo una cuenta de cada tipo y el teléfono es único por tipo de cuenta, con un correo de respaldo para recuperar el acceso desde la app con un código (ADR 0024). Quien ya es cliente y se registra como proveedor sube de nuevo todo: no se reutiliza verificación.

## Ciclo de una solicitud

`borrador` → `abierta` → `con_ofertas` → `adjudicada` → `en_ejecucion` → `finalizada` → `calificada`; además `cancelada`, `expirada` y `disputada`. Todo es solicitud por solicitud: no hay contratos ni campañas.

## Negociación

1. El cliente propone un precio por hectárea; la solicitud queda abierta y visible en el mapa del piloto.
2. El piloto acepta el precio o contraoferta, con el dron que usará, después de ver los lotes y sus fotos.
3. En cada negociación hay una sola oferta vigente: quien la recibe acepta, contraoferta o rechaza. Hay un máximo de ofertas y la última es definitiva. Las ofertas vencen y la solicitud expira; el cliente puede renovarla.
4. Aceptar la oferta vigente de la contraparte adjudica la solicitud con su precio acordado; las demás ofertas se cierran.
5. No hay asignación automática, zonas, radios, precio de referencia ni sanciones automáticas: el cliente elige. Hay prioridad solo en el aviso y en el orden sugerido: los avisos salen por oleadas desde el servidor (propios y mejor calificados primero, a nadie dos veces) y las ofertas se ordenan por defecto con los propios primero y luego por calificación.
6. Mientras el cliente negocia, la solicitud está «En negociación» y no aparece a los demás pilotos; el cliente puede elegir «Sin buscar más pilotos». Un dron que no cumple lo pedido puede ofertar y se le marca al cliente.
El detalle de reglas y casos límite lo mantiene el agente `negociacion-ofertas`.

## Qué ve cada parte

- Antes de ofertar, el piloto ve lotes, hectáreas, cultivo, accesos, observaciones y fotos del terreno; no ve datos del cliente ni las ofertas de otros pilotos.
- El cliente ve por oferta el precio, la calificación y el dron con fotos aprobadas, y qué requisito no cumple. No hay distancia calculada.
- Los datos de contacto se entregan solo tras adjudicar. La ubicación del piloto se comparte con el cliente solo durante `en_ejecucion`.

## Reglas de red

- **Negociar requiere red** (excepción documentada): ofertar, contraofertar, aceptar, rechazar y retirar los confirma el servidor y no pasan por el outbox.
- **Lo registrado en el lote sigue offline**: inicio, avance, cierre, mensajes del piloto y fotos se guardan en local y se sincronizan después (skill `protocolo-sync`).
- El flavor `cliente` lee de la red con caché local y muestra estados de carga, error y reintento.

## Calificaciones

El cliente califica al proveedor en un registro propio. El proveedor solo ve su calificación; no la edita. El admin modera (oculta o corrige abusos con motivo y autor). El proveedor califica al cliente en un registro privado aparte. Una calificación confirmada no se reescribe: se agrega un registro de moderación.

## Dinero

La app no cobra ni calcula comisión. Precio acordado al adjudicar; precio final = hectáreas ejecutadas × precio acordado, que calcula el servidor y la app muestra como monto a pagar fuera de ella. Dinero y hectáreas usan siempre un tipo decimal exacto, nunca `double`.

## Cancelación

Gratuita y sin registro antes de adjudicar. Tras adjudicar se registra quién cancela y se muestra en su tasa de cancelación; sin penalidad en dinero ni restricción automática.

## Alta y aprobación

- Cualquiera se registra y entra; el cliente y el proveedor se verifican desde la app (selfie con cámara y documento de identidad) y un admin aprueba cada cuenta antes de que publique, acepte, ofrezca o vea el mapa; el proveedor no aprobado ve solo un contador de solicitudes abiertas (sin lotes, clientes ni ubicación). El proveedor registra además la persona y su dron con fotos.
- Una cuenta creada por la oficina puede venir aprobada («verificada por la oficina»).
- El auxiliar no es usuario de la app (ADR 0021).

## Lo que no existe

Contratos, campañas, inventario, mantenimiento, planilla ni contabilidad internos. De mantenimiento solo se conservan los ciclos de batería, dentro del dron.

## Quién decide qué

Regla nueva de producto: `producto-marketplace`. Negociación de ofertas: `negociacion-ofertas`. Verificación, abuso y privacidad: `confianza-seguridad`. Una regla que cambia el backend se pide a `agrocom-api` (`docs/gestion/peticiones_agrocom_api/`).
