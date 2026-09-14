/// Estado del motor de sync completo (`SyncEngine`), no el de una fila
/// individual del outbox.
///
/// OJO: existe otro `EstadoSync` en `lib/nucleo/db/tablas/cola_sync.dart`
/// (`pendiente | enviado | confirmado | rechazado`) — es el estado de *cada
/// fila* de `ColaSync`. Este enum se llama distinto (`EstadoMotorSync`)
/// justamente para evitar el choque: uno describe si el motor está corriendo
/// un ciclo de sync ahora mismo, el otro describe el ciclo de vida de un
/// registro puntual dentro del outbox.
enum EstadoMotorSync { ocioso, sincronizando, error }
