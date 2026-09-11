// HU-06: `condicionesFueraDeRango`/`verificarObservacionSiFueraDeRango` son
// Dart puro (sin drift), como toda función de `features/*/domain/` en este
// repo (ver `reglas_sesion.dart` de `sesion_vuelo`) — testeable sin emulador
// (ADR 0005). Umbrales exactos del contrato real (`docs/api/openapi.yaml`
// de `agrocom-api`): viento > 17 km/h, temperatura > 30°C, humedad > 90%.

import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_condiciones.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal _d(String valor) => Decimal.parse(valor);

void main() {
  group('condicionesFueraDeRango', () {
    test('los tres valores dentro de rango no están fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('12.50'),
          temperaturaC: _d('24.00'),
          humedadPct: _d('65.00'),
        ),
        isFalse,
      );
    });

    test('exactamente en el umbral (17/30/90) no está fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('17'),
          temperaturaC: _d('30'),
          humedadPct: _d('90'),
        ),
        isFalse,
      );
    });

    test('viento apenas por encima de 17 km/h está fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('17.01'),
          temperaturaC: _d('24.00'),
          humedadPct: _d('65.00'),
        ),
        isTrue,
      );
    });

    test('temperatura apenas por encima de 30°C está fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('12.50'),
          temperaturaC: _d('30.01'),
          humedadPct: _d('65.00'),
        ),
        isTrue,
      );
    });

    test('humedad apenas por encima de 90% está fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('12.50'),
          temperaturaC: _d('24.00'),
          humedadPct: _d('90.01'),
        ),
        isTrue,
      );
    });

    test('más de un valor fuera de rango sigue siendo fuera de rango', () {
      expect(
        condicionesFueraDeRango(
          vientoKmh: _d('20'),
          temperaturaC: _d('35'),
          humedadPct: _d('95'),
        ),
        isTrue,
      );
    });
  });

  group('verificarObservacionSiFueraDeRango', () {
    test('dentro de rango, sin observación ni firma, no lanza', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: false,
          observacionAgronomo: null,
          firmaObservacion: null,
        ),
        returnsNormally,
      );
    });

    test('fuera de rango con observación y firma presentes no lanza', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: true,
          observacionAgronomo: 'Viento por encima del umbral, se autoriza.',
          firmaObservacion: 'Ing. Agr. Juana Pérez',
        ),
        returnsNormally,
      );
    });

    test('fuera de rango sin observación ni firma lanza la excepción', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: true,
          observacionAgronomo: null,
          firmaObservacion: null,
        ),
        throwsA(isA<ObservacionAgronomoRequeridaExcepcion>()),
      );
    });

    test('fuera de rango con observación pero sin firma lanza', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: true,
          observacionAgronomo: 'Viento por encima del umbral, se autoriza.',
          firmaObservacion: null,
        ),
        throwsA(isA<ObservacionAgronomoRequeridaExcepcion>()),
      );
    });

    test('fuera de rango con firma pero sin observación lanza', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: true,
          observacionAgronomo: null,
          firmaObservacion: 'Ing. Agr. Juana Pérez',
        ),
        throwsA(isA<ObservacionAgronomoRequeridaExcepcion>()),
      );
    });

    test('fuera de rango con observación/firma en blanco lanza igual', () {
      expect(
        () => verificarObservacionSiFueraDeRango(
          fueraDeRango: true,
          observacionAgronomo: '   ',
          firmaObservacion: '   ',
        ),
        throwsA(isA<ObservacionAgronomoRequeridaExcepcion>()),
      );
    });
  });
}
