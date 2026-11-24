import 'package:agrocom_field/cliente/solicitar/domain/reglas_solicitud.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_solicitar.dart';

void main() {
  group('polígono a hectáreas decimales', () {
    test('un cuadrado de 1.000 m de lado da 100 ha', () {
      final hectareas = hectareasDePoligono(contornoDePrueba);
      expect(hectareas, isA<Decimal>());
      expect(hectareas.scale, lessThanOrEqualTo(1));
      expect(hectareas, greaterThan(Decimal.parse('99')));
      expect(hectareas, lessThan(Decimal.parse('101')));
    });

    test('el sentido en que se marcan las esquinas no cambia el área', () {
      expect(
        hectareasDePoligono(contornoDePrueba.reversed.toList()),
        hectareasDePoligono(contornoDePrueba),
      );
    });

    test('menos de tres esquinas no encierran superficie', () {
      expect(hectareasDePoligono(const []), Decimal.zero);
      expect(hectareasDePoligono(contornoDePrueba.sublist(0, 2)), Decimal.zero);
    });

    test('el área calculada de un lote demo se acerca a la declarada', () {
      final repo = RepositorioEspia();
      for (final lote in repo.almacen.datos.lotes) {
        final calculada = hectareasDePoligono(lote.poligono);
        final diferencia = (calculada - lote.hectareas).abs();
        expect(
          diferencia < lote.hectareas * Decimal.parse('0.1'),
          isTrue,
          reason: '${lote.nombre}: $calculada vs ${lote.hectareas}',
        );
      }
    });

    test('un punto adentro y uno afuera del contorno', () {
      expect(
        poligonoContiene(contornoDePrueba, const GeoPunto(-16.935, -62.625)),
        isTrue,
      );
      expect(
        poligonoContiene(contornoDePrueba, const GeoPunto(-16.90, -62.625)),
        isFalse,
      );
    });
  });

  group('hectáreas escritas por el cliente', () {
    test('acepta coma o punto y nunca pasa por double', () {
      expect(ReglasSolicitud.parsearHectareas('85,5'), Decimal.parse('85.5'));
      expect(ReglasSolicitud.parsearHectareas('85.5'), Decimal.parse('85.5'));
      expect(ReglasSolicitud.parsearHectareas(' 120 '), Decimal.fromInt(120));
      // 0,1 + 0,2 en double no es 0,3; en decimal sí.
      expect(
        ReglasSolicitud.parsearHectareas('0,1')! +
            ReglasSolicitud.parsearHectareas('0,2')!,
        Decimal.parse('0.3'),
      );
    });

    test('rechaza vacío, texto, cero, exceso de decimales y de superficie', () {
      expect(ReglasSolicitud.errorDeHectareas(''), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('abc'), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('1,2,3'), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('0'), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('10,123'), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('5001'), isNotNull);
      expect(ReglasSolicitud.errorDeHectareas('85,5'), isNull);
      expect(ReglasSolicitud.errorDeHectareas('5000'), isNull);
    });
  });

  group('fecha deseada', () {
    test('se ofrecen 14 días a partir de mañana', () {
      final fechas = ReglasSolicitud.fechasDisponibles(ahoraDePrueba);
      expect(fechas, hasLength(14));
      expect(fechas.first, DateTime(2026, 11, 24));
      expect(fechas.last, DateTime(2026, 12, 7));
    });

    test('hoy, ayer y más allá del rango son inválidas', () {
      String? error(DateTime f) =>
          ReglasSolicitud.errorDeFecha(f, ahoraDePrueba);
      expect(error(DateTime(2026, 11, 23, 23, 59)), isNotNull);
      expect(error(DateTime(2026, 11, 22)), isNotNull);
      expect(error(DateTime(2026, 12, 8)), isNotNull);
      expect(error(DateTime(2026, 11, 24)), isNull);
      expect(error(DateTime(2026, 12, 7)), isNull);
    });

    test('solo el pedido para mañana es urgente', () {
      expect(
        ReglasSolicitud.esUrgente(DateTime(2026, 11, 24), ahoraDePrueba),
        isTrue,
      );
      expect(
        ReglasSolicitud.esUrgente(DateTime(2026, 11, 25), ahoraDePrueba),
        isFalse,
      );
    });
  });
}
