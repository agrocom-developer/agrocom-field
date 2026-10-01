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

  group('tarea 24: límites efectivos del trabajo (LimitesEfectivos)', () {
    Decimal d(String v) => Decimal.parse(v);

    bool fuera(
      String viento,
      String temperatura,
      String humedad, {
      LimitesCondiciones? limites,
    }) => condicionesFueraDeRango(
      vientoKmh: d(viento),
      temperaturaC: d(temperatura),
      humedadPct: d(humedad),
      limites: limites,
    );

    test('sin límites propios usa los defaults del servidor: 17/30/90 y sin '
        'humedad mínima', () {
      final limites = LimitesCondiciones.porDefecto();
      expect(limites.vientoMaxKmh, d('17'));
      expect(limites.temperaturaMaxC, d('30'));
      expect(limites.humedadMaxPct, d('90'));
      expect(limites.humedadMinPct, isNull);
      expect(LimitesCondiciones.resolver(), limites);
    });

    test('los topes son inclusivos: igual al límite está dentro de rango', () {
      final limites = LimitesCondiciones.resolver(
        vientoMaxKmh: d('12.50'),
        temperaturaMaxC: d('28.00'),
        humedadMaxPct: d('80.00'),
      );
      expect(fuera('12.5', '28', '80', limites: limites), isFalse);
      expect(fuera('12.51', '28', '80', limites: limites), isTrue);
      expect(fuera('12.5', '28.01', '80', limites: limites), isTrue);
      expect(fuera('12.5', '28', '80.01', limites: limites), isTrue);
      // Con los defaults, igual al límite también está dentro.
      expect(fuera('17', '30', '90'), isFalse);
    });

    test('límite propio más estricto que la constante: exige observación por '
        'debajo de 17 km/h', () {
      final limites = LimitesCondiciones.resolver(vientoMaxKmh: d('12.00'));
      expect(fuera('15', '20', '50', limites: limites), isTrue);
      expect(fuera('15', '20', '50'), isFalse);
    });

    test('límite propio más permisivo que la constante: no exige observación '
        'por encima de 17 km/h', () {
      final limites = LimitesCondiciones.resolver(
        vientoMaxKmh: d('22.00'),
        temperaturaMaxC: d('35.00'),
        humedadMaxPct: d('95.00'),
      );
      expect(fuera('20', '33', '93', limites: limites), isFalse);
      expect(fuera('20', '33', '93'), isTrue);
    });

    test('un límite propio en blanco hereda el default y los demás se '
        'respetan', () {
      final limites = LimitesCondiciones.resolver(temperaturaMaxC: d('25.00'));
      expect(limites.vientoMaxKmh, d('17'));
      expect(limites.humedadMaxPct, d('90'));
      expect(fuera('17', '25', '90', limites: limites), isFalse);
      expect(fuera('17', '26', '90', limites: limites), isTrue);
      expect(fuera('18', '25', '90', limites: limites), isTrue);
    });

    test('humedad mínima fijada: por debajo exige observación, igual al '
        'mínimo está dentro', () {
      final limites = LimitesCondiciones.resolver(humedadMinPct: d('40.00'));
      expect(fuera('10', '20', '39.99', limites: limites), isTrue);
      expect(fuera('10', '20', '40', limites: limites), isFalse);
      expect(fuera('10', '20', '60', limites: limites), isFalse);
    });

    test('humedad mínima sin fijar: cualquier humedad bajo el máximo está '
        'dentro, incluso 0', () {
      expect(fuera('10', '20', '0'), isFalse);
      expect(
        fuera('10', '20', '0', limites: LimitesCondiciones.resolver()),
        isFalse,
      );
    });
  });
}
