// Tarea 27: `restriccionApertura` — una sesión NUEVA se bloquea solo con
// `dado_de_baja` (el servidor la rechaza con `trabajo_no_existe_aun`), con
// la orden pausada (decisión del dueño) o con otra sesión abierta; el resto
// de los motivos de retiro solo avisan, porque el servidor la acepta.

import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_apertura.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trabajo vigente, sin nada abierto: ni bloqueo ni aviso', () {
    expect(
      restriccionApertura(haySesionAbierta: false),
      RestriccionApertura.ninguna,
    );
  });

  test('dado_de_baja: bloquea la sesión nueva y avisa el motivo', () {
    final r = restriccionApertura(
      haySesionAbierta: false,
      motivoRetiroTrabajo: 'dado_de_baja',
    );

    expect(r.bloqueada, isTrue);
    expect(r.bloqueo, contains('dado de baja'));
    // Tarea 28: el aviso dice que lo en curso se registra igual (#314).
    expect(
      r.aviso,
      'El trabajo fue dado de baja desde el panel: no se puede abrir una '
      'sesión nueva. La sesión abierta y el trabajo se cierran y se '
      'registran igual.',
    );
  });

  for (final (motivo, aviso) in const [
    ('reasignado', 'El trabajo fue reasignado a otro equipo.'),
    ('cerrado', 'El trabajo fue cerrado desde el panel.'),
    (
      'orden_cerrada',
      'La orden del trabajo se cerró (consumida, cancelada o vencida).',
    ),
    (
      'fuera_de_alcance',
      'El trabajo ya no llega al catálogo de este dispositivo.',
    ),
  ]) {
    test('$motivo: el servidor acepta la sesión — no bloquea, solo avisa', () {
      final r = restriccionApertura(
        haySesionAbierta: false,
        motivoRetiroTrabajo: motivo,
      );

      expect(r.bloqueada, isFalse, reason: motivo);
      expect(r.aviso, aviso);
    });
  }

  test('orden pausada: bloquea aunque el trabajo siga vigente', () {
    final r = restriccionApertura(
      haySesionAbierta: false,
      motivoRetiroOrden: 'pausada',
    );

    expect(r.bloqueo, contains('pausada'));
    expect(r.aviso, isNull);
  });

  test('otra orden retirada (no pausada) no bloquea por sí sola', () {
    expect(
      restriccionApertura(
        haySesionAbierta: false,
        motivoRetiroOrden: 'consumida',
      ).bloqueada,
      isFalse,
    );
  });

  test('con una sesión abierta en el dispositivo, bloquea siempre', () {
    final r = restriccionApertura(
      haySesionAbierta: true,
      motivoRetiroTrabajo: 'reasignado',
    );

    expect(r.bloqueo, contains('Ya hay una sesión abierta'));
    expect(r.aviso, 'El trabajo fue reasignado a otro equipo.');
  });
}
