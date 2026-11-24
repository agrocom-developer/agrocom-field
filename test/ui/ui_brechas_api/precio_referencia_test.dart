// Sugerencia «Referencia: Bs X por ha»: todos sus estados, el toque que la
// usa, la hoja de contraoferta del piloto y los goldens.

import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/pedir_precio_hoja.dart';
import 'package:agrocom_field/nucleo/marketplace/referencias/precio_referencia.dart';
import 'package:agrocom_field/nucleo/marketplace/referencias/presentation/sugerencia_precio_referencia.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

class _Falla implements ReferenciasRepositorio {
  _Falla(this.error);

  final Object error;
  var llamadas = 0;

  @override
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  }) async {
    llamadas++;
    throw error;
  }
}

class _SinPrecio implements ReferenciasRepositorio {
  @override
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  }) async => PrecioReferencia(tipoAplicacion: tipoAplicacion);
}

class _Pendiente implements ReferenciasRepositorio {
  @override
  Future<PrecioReferencia> precio({
    required String tipoAplicacion,
    int? zonaId,
    String? macrorregion,
  }) => Future<PrecioReferencia>.delayed(const Duration(days: 1));
}

List<RepositoryProvider<Object>> _con(ReferenciasRepositorio r) => [
  RepositoryProvider<ReferenciasRepositorio>.value(value: r),
];

Widget _sugerencia({Decimal? actual, ValueChanged<Decimal>? alUsar}) =>
    SugerenciaPrecioReferencia(
      tipoAplicacion: 'herbicida',
      actual: actual,
      alUsar: alUsar ?? (_) {},
    );

void main() {
  setUpAll(cargarFuentes);

  group('tipoAplicacionDe', () {
    test('reconoce el tipo por el texto del producto', () {
      expect(tipoAplicacionDe('Glifosato 480 SL + coadyuvante'), 'herbicida');
      expect(tipoAplicacionDe('Insecticida piretroide'), 'insecticida');
      expect(tipoAplicacionDe('Fungicida triazol'), 'fungicida');
      expect(tipoAplicacionDe('Fertilizante foliar'), 'fertilizante_foliar');
      expect(tipoAplicacionDe('fertilizante_foliar'), 'fertilizante_foliar');
      expect(tipoAplicacionDe('Desecante'), 'desecante');
      expect(tipoAplicacionDe('Algo raro'), 'otro');
      expect(tipoAplicacionDe(null), 'otro');
    });
  });

  group('SugerenciaPrecioReferencia', () {
    testWidgets('muestra «Referencia: Bs 132 por ha» y la usa al tocarla', (
      tester,
    ) async {
      Decimal? usado;
      await montar(
        tester,
        _sugerencia(alUsar: (v) => usado = v),
        repositorios: _con(ReferenciasDemo()),
      );
      await asentar(tester);
      expect(find.text('Referencia: Bs 132 por ha'), findsOneWidget);
      expect(find.text('Usar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('referencia-usar')));
      expect(usado, Decimal.parse('132'));
    });

    testWidgets('con el precio ya escrito se marca como usada', (tester) async {
      await montar(
        tester,
        _sugerencia(actual: Decimal.parse('132')),
        repositorios: _con(ReferenciasDemo()),
      );
      await asentar(tester);
      expect(find.text('Estás usando este precio'), findsOneWidget);
      expect(find.text('Usar'), findsNothing);
    });

    testWidgets('sin referencia lo dice y no estorba', (tester) async {
      await montar(tester, _sugerencia(), repositorios: _con(_SinPrecio()));
      await asentar(tester);
      expect(find.byKey(const Key('referencia-vacia')), findsOneWidget);
      expect(find.byKey(const Key('referencia-usar')), findsNothing);
    });

    testWidgets('sin red ofrece reintentar y al volver la red la muestra', (
      tester,
    ) async {
      final falla = _Falla(const SinConexion());
      await montar(tester, _sugerencia(), repositorios: _con(falla));
      await asentar(tester);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(falla.llamadas, 1);

      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(falla.llamadas, 2);
    });

    testWidgets('un error inesperado dice qué pasó y deja reintentar', (
      tester,
    ) async {
      await montar(
        tester,
        _sugerencia(),
        repositorios: _con(_Falla(StateError('x'))),
      );
      await asentar(tester);
      expect(find.textContaining('No pudimos traer'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('el objetivo táctil mide 56 dp o más', (tester) async {
      await montar(
        tester,
        _sugerencia(),
        repositorios: _con(ReferenciasDemo()),
      );
      await asentar(tester);
      expect(
        tester.getSize(find.byKey(const Key('referencia-usar'))).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('anuncia la referencia a los lectores de pantalla', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        _sugerencia(),
        repositorios: _con(ReferenciasDemo()),
      );
      await asentar(tester);
      expect(
        find.bySemanticsLabel(RegExp('Precio de referencia: Bs 132')),
        findsOneWidget,
      );
      semantica.dispose();
    });

    for (final v in [...matrizCliente, ...matrizCampo]) {
      testWidgets('golden lista ${v.nombre}', (tester) async {
        await montar(
          tester,
          _sugerencia(),
          variante: v,
          repositorios: _con(ReferenciasDemo()),
        );
        await asentar(tester);
        await golden(tester, 'referencia_lista_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    for (final (nombre, repo) in <(String, ReferenciasRepositorio)>[
      ('carga', _Pendiente()),
      ('vacia', _SinPrecio()),
      ('sin_red', _Falla(const SinConexion())),
    ]) {
      testWidgets('golden $nombre', (tester) async {
        await montar(
          tester,
          _sugerencia(),
          variante: matrizCliente.first,
          repositorios: _con(repo),
        );
        await asentar(tester, veces: 2);
        await golden(tester, 'referencia_${nombre}_claro_360');
      }, skip: saltarGolden != null);
    }
  });

  group('hoja de contraoferta del piloto', () {
    Future<void> abrir(WidgetTester tester, {Variante? variante}) async {
      await montar(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => pedirPrecio(
              context,
              titulo: 'Tu contraoferta',
              hectareas: Decimal.parse('80'),
              precioReferencia: Decimal.parse('115'),
              etiquetaReferencia: 'El cliente propone',
              tipoAplicacion: 'herbicida',
            ),
            child: const Text('Abrir'),
          ),
        ),
        variante: variante ?? matrizCampo[1],
        repositorios: _con(ReferenciasDemo()),
        conScaffold: false,
      );
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
    }

    testWidgets('trae la referencia y la usa en el campo de precio', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('Referencia: Bs 132 por ha'), findsOneWidget);
      await tester.tap(find.byKey(const Key('referencia-usar')));
      await tester.pump();
      expect(find.text('132'), findsOneWidget);
      // El total se calcula con la referencia: 80 ha × Bs 132.
      expect(find.textContaining('Bs 10.560'), findsOneWidget);
    });

    for (final v in matrizCampo) {
      testWidgets('golden ${v.nombre}', (tester) async {
        await abrir(tester, variante: v);
        await golden(tester, 'contraoferta_referencia_${v.nombre}');
      }, skip: saltarGolden != null);
    }
  });
}
