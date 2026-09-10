import 'dart:async';

import 'estado_sync.dart';

/// Motor de sync offline-first (ADR 0005 de `agrocom-api`, invariantes 1 a 7
/// y 10 de `CLAUDE.md`). Vive en `nucleo/`, sin BLoC: corre disparado por
/// conectividad, apertura de app o botón manual, y publica su estado por
/// [estado] para que un `SyncCubit` (capa de presentación, fuera de este
/// archivo) lo exponga a la UI.
///
/// Esqueleto del bootstrap — la lógica real es TE-05, todavía sin
/// implementar. Cuando se implemente, este motor tiene que cubrir, como
/// mínimo:
///
/// * Leer la cola outbox (`ColaSync`, en `nucleo/db/tablas/cola_sync.dart`)
///   y hacer el push respetando el orden causal por `secuencia` local
///   (invariante 5 de CLAUDE.md) — nunca por reloj de dispositivo. Ese orden
///   es lo que garantiza, por ejemplo, que un trabajo se sincronice antes que
///   la sesión que lo referencia, y la sesión antes que una recarga.
/// * Idempotencia por `uuid_cliente` (invariante 2 de CLAUDE.md): generado en
///   el dispositivo antes de tocar la red, nunca en el servidor, nunca
///   reutilizado entre reintentos — es la clave que hace seguro reintentar
///   un push que no confirmó si llegó.
/// * Avanzar el estado de cada fila del outbox (`pendiente → enviado →
///   confirmado | rechazado`) solo a partir de lo que el servidor confirma,
///   nunca adelantándose (invariante 7 de CLAUDE.md).
/// * TODO(TE-05, obligatorio antes de la primera pantalla del esqueleto
///   vertical): prueba de replay (invariante 10 de CLAUDE.md) — aplicar el
///   mismo lote de sync 10 veces, en orden y en desorden parcial, y verificar
///   que el estado final de la base local queda idéntico. No es un test
///   opcional ni se puede dejar simulado/vacío para desbloquear un commit
///   (ver skill `verificacion`); se escribe junto con la implementación real,
///   no después.
class SyncEngine {
  final _controladorEstado = StreamController<EstadoMotorSync>.broadcast();

  /// Estado del motor completo (no confundir con el `EstadoSync` de cada fila
  /// del outbox, ver `estado_sync.dart`).
  Stream<EstadoMotorSync> get estado => _controladorEstado.stream;

  /// Dispara un ciclo de sync. Quien lo invoca decide el trigger
  /// (conectividad recuperada, apertura de app, botón manual) — este método
  /// no implementa esos triggers, solo corre el ciclo cuando se lo llama.
  Future<void> sincronizar() async {
    throw UnimplementedError('Implementado por logica-offline — ver TE-05.');
  }

  void dispose() {
    _controladorEstado.close();
  }
}
