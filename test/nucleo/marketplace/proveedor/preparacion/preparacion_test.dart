import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/preparacion/data/preparacion_local.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/preparacion/domain/preparacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/preparacion/presentation/preparacion_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/preparacion/presentation/preparacion_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QueNoGuarda extends PreparacionMemoria {
  @override
  Future<void> guardar(ChecklistPreparacion lista, {int? servicioId}) =>
      throw StateError('sin espacio');
}

void main() {
  group('ChecklistPreparacion', () {
    test('empieza vacía y avanza al marcar', () {
      const vacia = ChecklistPreparacion();
      expect(vacia.completados, 0);
      expect(vacia.progreso, 0);
      final una = vacia.alternar(ItemPreparacion.baterias);
      expect(una.estaHecho(ItemPreparacion.baterias), isTrue);
      expect(una.progreso, closeTo(1 / ItemPreparacion.values.length, 1e-9));
    });

    test('marcar dos veces desmarca', () {
      final lista = const ChecklistPreparacion()
          .alternar(ItemPreparacion.epp)
          .alternar(ItemPreparacion.epp);
      expect(lista.completados, 0);
    });

    test('con todos los pasos está completa', () {
      var lista = const ChecklistPreparacion();
      for (final i in ItemPreparacion.values) {
        lista = lista.alternar(i);
      }
      expect(lista.completo, isTrue);
      expect(lista.progreso, 1);
    });

    test('ida y vuelta por JSON ignora nombres desconocidos', () {
      final lista = ChecklistPreparacion.deJson(['tanque', 'ya_no_existe']);
      expect(lista.hechos, {ItemPreparacion.tanque});
      expect(ChecklistPreparacion.deJson(lista.aJson()).hechos, lista.hechos);
    });
  });

  group('PreparacionLocal', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'guarda la lista genérica y la de cada servicio por separado',
      () async {
        final store = PreparacionLocal();
        await store.guardar(
          const ChecklistPreparacion({ItemPreparacion.tanque}),
        );
        await store.guardar(
          const ChecklistPreparacion({ItemPreparacion.epp}),
          servicioId: 7,
        );
        expect((await store.leer()).hechos, {ItemPreparacion.tanque});
        expect((await store.leer(servicioId: 7)).hechos, {ItemPreparacion.epp});
        expect((await store.leer(servicioId: 8)).hechos, isEmpty);
      },
    );
  });

  group('PreparacionCubit', () {
    test('cada cambio se guarda al momento', () async {
      final store = PreparacionMemoria();
      final cubit = PreparacionCubit(store);
      await cubit.cargar();
      await cubit.alternar(ItemPreparacion.clima);
      expect(cubit.state.lista.estaHecho(ItemPreparacion.clima), isTrue);
      expect((await store.leer()).estaHecho(ItemPreparacion.clima), isTrue);
      await cubit.reiniciar();
      expect((await store.leer()).completados, 0);
      await cubit.close();
    });

    test('si no se puede guardar, el cambio se ve y se avisa', () async {
      final cubit = PreparacionCubit(_QueNoGuarda());
      await cubit.cargar();
      await cubit.alternar(ItemPreparacion.dron);
      expect(cubit.state.lista.estaHecho(ItemPreparacion.dron), isTrue);
      expect(cubit.state.noSeGuardo, isTrue);
      await cubit.close();
    });
  });

  group('PreparacionEquipoPantalla', () {
    Widget app(Widget hijo) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.oscuro),
      home: hijo,
    );

    testWidgets('muestra todos los pasos y el progreso, y marca al tocar', (
      tester,
    ) async {
      final store = PreparacionMemoria();
      await tester.pumpWidget(app(PreparacionEquipoPantalla(store: store)));
      await tester.pumpAndSettle();
      expect(find.text('Preparación del equipo'), findsOneWidget);
      expect(find.text('0 de 9 listos'), findsOneWidget);
      expect(find.text('Baterías cargadas'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('preparacion-baterias')));
      await tester.pumpAndSettle();
      expect(find.text('1 de 9 listos'), findsOneWidget);
      expect((await store.leer()).estaHecho(ItemPreparacion.baterias), isTrue);
    });

    testWidgets('cada paso mide al menos 56 dp de alto', (tester) async {
      await tester.pumpWidget(
        app(PreparacionEquipoPantalla(store: PreparacionMemoria())),
      );
      await tester.pumpAndSettle();
      final alto = tester.getSize(
        find.byKey(const ValueKey('preparacion-baterias')),
      );
      expect(alto.height, greaterThanOrEqualTo(56));
    });

    testWidgets('la entrada muestra el avance guardado', (tester) async {
      final store = PreparacionMemoria();
      await store.guardar(
        const ChecklistPreparacion({
          ItemPreparacion.tanque,
          ItemPreparacion.epp,
        }),
      );
      await tester.pumpWidget(
        app(Scaffold(body: AccesoPreparacionEquipo(store: store))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Antes de salir'), findsOneWidget);
      expect(find.text('2 de 9 listos'), findsOneWidget);
    });
  });
}
