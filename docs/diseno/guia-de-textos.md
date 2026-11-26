# Guía de textos

Los textos visibles de las dos apps viven en `lib/l10n/app_es.arb` (ADR 0022). Esta guía fija cómo se escriben. Una prueba (`test/nucleo/l10n/redaccion_neutra_test.dart`) falla si reaparece una de las construcciones de la tabla final.

## Criterios

- **Español neutro, tuteo.** Se habla a la persona de «tú»: «Revisa», «Puedes», «Elige». Sin voseo (`tenés`, `elegí`), sin regionalismos locales ni anglicismos que sobren.
- **Un nombre por concepto.** Solicitud, oferta, contraoferta, proveedor, piloto, dron, reclamo, calificación, cliente, lote. «Teléfono» y no «celular»; «Notificaciones» y no «avisos» para lo que llega a la lista o a la campana; «Eliminar» y nunca «dar de baja»; «Subir» fotos y documentos. «Cargar» solo significa traer datos a la pantalla («No pudimos cargar tus lotes»).
- **Etiquetas con el sustantivo primero**, concordando en género y número con él. Un adjetivo suelto lleva su sustantivo a la vista o concuerda con él: las solicitudes son «Todas», «Activas», «Terminadas»; el reclamo es masculino («Abierto», «En reclamo»).
- **Botones** con verbo en infinitivo («Enviar», «Publicar solicitud», «Reintentar»). Las instrucciones y los títulos de pasos hablan en imperativo («Elige la fecha», «Escribe tu usuario»).
- **Ingresar.** Se «ingresa» a la cuenta y a la app; «Entrar» no se usa.
- **Reintento.** Siempre «Vuelve a intentarlo» (con «cuando tengas señal» si el motivo es la red). Un error dice qué pasó y qué hacer.
- **Vacío, error y sin red** orientan: dicen qué falta y cuál es el siguiente paso, sin culpar a la persona.
- **Mayúscula solo inicial** en etiquetas, botones y títulos. Sin punto final en etiquetas y botones; con punto en mensajes completos. Los rótulos en mayúsculas sostenidas («HOY», «PASO 2 DE 4») son un recurso tipográfico del sistema de diseño, no una regla para el texto corriente.
- **Signos y acentos.** `¿ ¡` de apertura y todos los acentos; nunca ASCII por tilde.
- **Cifras.** Hectáreas como «12,5 ha», dinero como «Bs 1.250» y porcentajes como «40 %» (espacio antes del signo). Fechas por el formateador de `nucleo/marketplace/ui`, no a mano.
- **Sin jerga técnica** hacia la persona: no se habla de «registro», «servidor», «payload» ni «sincronización fallida». Se dice «envío», «No pudimos…» y qué hacer.
- **Un texto nuevo** va al ARB con su clave; el texto de permisos y los textos legales los fija la política de privacidad y no se retocan aquí.

## Ejemplos

| Mal | Bien |
|---|---|
| Intenta de nuevo en un momento. | Vuelve a intentarlo en un momento. |
| Los verás acá. | Los verás aquí. |
| Fumigación con drones, a pedido | Fumigación con drones cuando la necesites |
| Pedido 12, en ejecución | Solicitud 12, en ejecución |
| Celular | Teléfono |
| Todos · Activos · Listos (solicitudes) | Todas · Activas · Terminadas |
| Avisos | Notificaciones |
| Quitar contacto (borra a la persona) | Eliminar contacto |
| Todavía no cargaste documentos. | Todavía no subiste documentos. |
| Podés corregir los datos. | Puedes corregir los datos. |
| Entra a tu cuenta · Entrar | Ingresa a tu cuenta · Ingresar |
| 2 registros rechazados | 2 envíos rechazados |
| Jala hacia abajo para actualizar. | Desliza hacia abajo para actualizar. |
