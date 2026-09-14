import 'tipo_incidencia.dart';

/// Evento puntual registrado por el piloto durante una sesión activa
/// (HU-08), espejo de `IncidenciaLocal` — entidad Dart pura: sin `drift` ni
/// `dio`, testeable sin emulador (ADR 0005 de `agrocom-api`).
class Incidencia {
  const Incidencia({
    required this.uuidCliente,
    required this.sesionUuidCliente,
    required this.tipo,
    required this.hora,
    required this.evidenciaFotoUuidCliente,
    this.descripcion,
  });

  /// Identidad DEL EVENTO, generada en el dispositivo (invariante 2 de
  /// CLAUDE.md).
  final String uuidCliente;

  /// `uuid_cliente` de apertura de la sesión activa — nunca id de servidor.
  final String sesionUuidCliente;

  final TipoIncidencia tipo;

  final String? descripcion;

  /// Cuándo ocurrió el evento.
  final DateTime hora;

  /// `uuid_cliente` de la evidencia (`tipo: 'foto_incidencia'`) ya
  /// capturada — REQUERIDA, sin foto no hay incidencia.
  final String evidenciaFotoUuidCliente;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Incidencia &&
          other.uuidCliente == uuidCliente &&
          other.sesionUuidCliente == sesionUuidCliente &&
          other.tipo == tipo &&
          other.descripcion == descripcion &&
          other.hora == hora &&
          other.evidenciaFotoUuidCliente == evidenciaFotoUuidCliente);

  @override
  int get hashCode => Object.hash(
    uuidCliente,
    sesionUuidCliente,
    tipo,
    descripcion,
    hora,
    evidenciaFotoUuidCliente,
  );
}
