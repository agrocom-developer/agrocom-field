import 'package:torch_light/torch_light.dart';

/// Control de la linterna del dispositivo para el modo emergencia (HU-68,
/// Sprint 15 — exclusivo del flavor auxiliar). Abstracta para poder fakear
/// en tests sin canal de plataforma real, mismo patrón que
/// `nucleo/notificaciones/notificador_local.dart`.
abstract class LinternaControlador {
  /// Si el dispositivo tiene una linterna que se pueda controlar.
  Future<bool> disponible();

  Future<void> encender();

  Future<void> apagar();
}

/// Envuelve el plugin `torch_light` — solo Android (los dos flavors de este
/// repo corren únicamente ahí, ver `docs/vision.md`).
class LinternaControladorTorchLight implements LinternaControlador {
  @override
  Future<bool> disponible() => TorchLight.isTorchAvailable();

  @override
  Future<void> encender() => TorchLight.enableTorch();

  @override
  Future<void> apagar() => TorchLight.disableTorch();
}
