// HU-07 (resto): cálculo de hectáreas por acumulado — Dart puro, sin drift
// ni Flutter (ver comentario de `calcularHectareasDeCierrePorAcumulado`).

import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_sesion.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularHectareasDeCierrePorAcumulado', () {
    test('acumulado final mayor al inicial: devuelve la diferencia exacta', () {
      final resultado = calcularHectareasDeCierrePorAcumulado(
        hectareaInicialAcumulada: Decimal.parse('100.50'),
        hectareaFinalAcumulada: Decimal.parse('120.75'),
      );

      expect(resultado, Decimal.parse('20.25'));
    });

    test('acumulado final igual al inicial: devuelve cero', () {
      final resultado = calcularHectareasDeCierrePorAcumulado(
        hectareaInicialAcumulada: Decimal.parse('50'),
        hectareaFinalAcumulada: Decimal.parse('50'),
      );

      expect(resultado, Decimal.zero);
    });

    test(
      'acumulado final menor al inicial: lanza '
      'AcumuladoFinalMenorQueInicialExcepcion con los valores originales',
      () {
        expect(
          () => calcularHectareasDeCierrePorAcumulado(
            hectareaInicialAcumulada: Decimal.parse('100'),
            hectareaFinalAcumulada: Decimal.parse('90'),
          ),
          throwsA(
            isA<AcumuladoFinalMenorQueInicialExcepcion>()
                .having(
                  (e) => e.hectareaInicialAcumulada,
                  'hectareaInicialAcumulada',
                  Decimal.parse('100'),
                )
                .having(
                  (e) => e.hectareaFinalAcumulada,
                  'hectareaFinalAcumulada',
                  Decimal.parse('90'),
                ),
          ),
        );
      },
    );
  });
}
