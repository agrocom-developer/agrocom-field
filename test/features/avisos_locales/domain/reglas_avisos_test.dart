// Etapa 2 de HU-62: `ordenesNuevas` es Dart puro (sin drift ni
// flutter_local_notifications), como toda función de
// `features/*/domain/` en este repo (ver `reglas_sesion.dart` de
// `sesion_vuelo`) — testeable sin emulador (ADR 0005).

import 'package:agrocom_field/features/avisos_locales/domain/reglas_avisos.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

OrdenVigente _orden(int id) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: 1,
  nroAplicacion: 1,
  litrosHa: Decimal.parse('10.00'),
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
);

void main() {
  test('lista vacía de órdenes actuales no devuelve nuevas', () {
    expect(
      ordenesNuevas(actuales: const [], idsYaNotificados: {1, 2}),
      isEmpty,
    );
  });

  test('sin ids nuevos (todas ya notificadas) no devuelve nada', () {
    final actuales = [_orden(1), _orden(2)];

    expect(
      ordenesNuevas(actuales: actuales, idsYaNotificados: {1, 2}),
      isEmpty,
    );
  });

  test('una orden nueva entre las ya notificadas se devuelve sola', () {
    final actuales = [_orden(1), _orden(2), _orden(3)];

    final nuevas = ordenesNuevas(actuales: actuales, idsYaNotificados: {1, 2});

    expect(nuevas.map((o) => o.id), [3]);
  });

  test('varias órdenes nuevas se devuelven todas, en el orden recibido', () {
    final actuales = [_orden(5), _orden(1), _orden(6)];

    final nuevas = ordenesNuevas(actuales: actuales, idsYaNotificados: {1});

    expect(nuevas.map((o) => o.id), [5, 6]);
  });

  test('conjunto de ids ya notificados vacío: todas son nuevas', () {
    final actuales = [_orden(1), _orden(2)];

    final nuevas = ordenesNuevas(actuales: actuales, idsYaNotificados: {});

    expect(nuevas.map((o) => o.id), [1, 2]);
  });
}
