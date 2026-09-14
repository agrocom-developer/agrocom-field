// HU-08: precondición "la sesión existe y está abierta" antes de registrar
// una incidencia — Dart puro, sin drift ni Flutter (ver comentario de
// `verificarSesionActiva`).

import 'package:agrocom_field/features/incidencias/domain/reglas_incidencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('verificarSesionActiva', () {
    test('sesión existente y abierta no lanza nada', () {
      expect(
        () => verificarSesionActiva(
          sesionExiste: true,
          sesionAbierta: true,
          sesionUuidCliente: 'sesion-1',
        ),
        returnsNormally,
      );
    });

    test('sesión inexistente lanza SesionInexistenteExcepcion con el '
        'uuid_cliente original', () {
      expect(
        () => verificarSesionActiva(
          sesionExiste: false,
          sesionAbierta: false,
          sesionUuidCliente: 'sesion-inexistente',
        ),
        throwsA(
          isA<SesionInexistenteExcepcion>().having(
            (e) => e.sesionUuidCliente,
            'sesionUuidCliente',
            'sesion-inexistente',
          ),
        ),
      );
    });

    test('sesión existente pero cerrada lanza SesionCerradaExcepcion con el '
        'uuid_cliente original', () {
      expect(
        () => verificarSesionActiva(
          sesionExiste: true,
          sesionAbierta: false,
          sesionUuidCliente: 'sesion-cerrada',
        ),
        throwsA(
          isA<SesionCerradaExcepcion>().having(
            (e) => e.sesionUuidCliente,
            'sesionUuidCliente',
            'sesion-cerrada',
          ),
        ),
      );
    });
  });
}
