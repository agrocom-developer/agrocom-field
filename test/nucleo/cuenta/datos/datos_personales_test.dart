import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/data/datos_personales_demo.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/data/datos_personales_red.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/domain/datos_personales.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/domain/datos_personales_repositorio.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/presentation/datos_personales_cubit.dart';
import 'package:agrocom_field/nucleo/cuenta/datos/presentation/datos_personales_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/ui/ajustes/ajustes_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _datos = DatosPersonales(
  nombre: 'Hugo Antelo',
  correo: 'hugo@ejemplo.com',
  telefono: '+591 77123456',
  empresa: 'Los Tajibos',
);

DatosPersonalesDemo _demo({bool puedeEditar = true}) => DatosPersonalesDemo(
  _datos,
  puedeEditar: puedeEditar,
  latencia: Duration.zero,
  reloj: () => DateTime(2026, 11, 27),
);

Future<void> _abrir(
  WidgetTester tester,
  DatosPersonalesRepositorio repo,
) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepositoryProvider<DatosPersonalesRepositorio>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: const DatosPersonalesPantalla(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DatosPersonalesDemo (la regla del servidor)', () {
    test('una edición libre; la segunda se rechaza con 409', () async {
      final repo = _demo();
      expect((await repo.cargar()).puedeEditar, isTrue);
      final tras = await repo.editarUnaVez(_datos.copiarCon(nombre: 'Hugo A.'));
      expect(tras.puedeEditar, isFalse);
      expect(tras.datos.nombre, 'Hugo A.');
      await expectLater(
        repo.editarUnaVez(_datos),
        throwsA(
          isA<OperacionRechazada>().having((e) => e.codigo, 'codigo', 409),
        ),
      );
    });

    test('no se puede pedir un cambio mientras queda la edición libre', () {
      expect(
        _demo().solicitarCambio('mi teléfono cambió'),
        throwsA(isA<OperacionRechazada>()),
      );
    });

    test('una sola solicitud abierta a la vez', () async {
      final repo = _demo(puedeEditar: false);
      final s = await repo.solicitarCambio('mi teléfono cambió');
      expect(s.estado, EstadoSolicitudCambio.pendiente);
      expect((await repo.cargar()).solicitudAbierta, isTrue);
      await expectLater(
        repo.solicitarCambio('otra cosa distinta'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.motivo,
            'motivo',
            'solicitud_abierta',
          ),
        ),
      );
    });

    test('la API real aún no está disponible y falla con mensaje claro', () {
      const red = DatosPersonalesRed();
      expect(red.disponible, isFalse);
      expect(red.cargar(), throwsA(isA<OperacionRechazada>()));
    });
  });

  group('DatosPersonalesCubit', () {
    test('carga y guarda la única edición', () async {
      final cubit = DatosPersonalesCubit(_demo());
      await cubit.cargar();
      expect(cubit.state.fase, FaseDatosPersonales.lista);
      expect(cubit.state.datos!.puedeEditar, isTrue);
      await cubit.guardar(_datos.copiarCon(correo: 'nuevo@ejemplo.com'));
      expect(cubit.state.resultado, ResultadoDatosPersonales.guardado);
      expect(cubit.state.datos!.puedeEditar, isFalse);
      expect(cubit.state.datos!.datos.correo, 'nuevo@ejemplo.com');
      await cubit.close();
    });

    test('si otra sesión ya gastó la edición, relee y lo avisa', () async {
      final repo = _demo();
      final cubit = DatosPersonalesCubit(repo);
      await cubit.cargar();
      await repo.editarUnaVez(_datos); // «otro dispositivo»
      await cubit.guardar(_datos);
      expect(cubit.state.resultado, ResultadoDatosPersonales.edicionAgotada);
      expect(cubit.state.datos!.puedeEditar, isFalse);
      await cubit.close();
    });

    test('un fallo de carga queda en error y permite reintentar', () async {
      final cubit = DatosPersonalesCubit(const DatosPersonalesRed());
      await cubit.cargar();
      expect(cubit.state.fase, FaseDatosPersonales.error);
      await cubit.close();
    });
  });

  group('DatosPersonalesPantalla', () {
    testWidgets(
      'avisa de la única edición, valida y confirma antes de guardar',
      (tester) async {
        await _abrir(tester, _demo());
        expect(find.byKey(const Key('datos-aviso-una-vez')), findsOneWidget);
        expect(find.text('Hugo Antelo'), findsOneWidget);

        // Correo inválido: no avanza y marca el error en línea.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'hugo@ejemplo.com'),
          'mal',
        );
        await tester.tap(find.byKey(const Key('datos-guardar')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Escribe un correo válido'), findsOneWidget);
        expect(find.byKey(const Key('datos-confirmar')), findsNothing);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'mal'),
          'nuevo@ejemplo.com',
        );
        await tester.tap(find.byKey(const Key('datos-guardar')));
        await tester.pumpAndSettle();
        expect(find.text('¿Guardar tus datos?'), findsOneWidget);
        expect(
          find.text('Después solo podrás pedir cambios a atención al cliente.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('datos-confirmar')));
        await tester.pumpAndSettle();

        // Quedó de solo lectura, con la salida clara.
        expect(find.byKey(const Key('datos-formulario')), findsNothing);
        expect(find.byKey(const Key('datos-aviso-ya-editado')), findsOneWidget);
        expect(find.text('nuevo@ejemplo.com'), findsOneWidget);
        expect(find.byKey(const Key('datos-solicitar-cambio')), findsOneWidget);
      },
    );

    testWidgets('sin edición libre: solo lectura y pide el cambio con motivo', (
      tester,
    ) async {
      final repo = _demo(puedeEditar: false);
      await _abrir(tester, repo);
      expect(find.byKey(const Key('datos-guardar')), findsNothing);
      await tester.tap(find.byKey(const Key('datos-solicitar-cambio')));
      await tester.pumpAndSettle();

      // El motivo es obligatorio.
      await tester.tap(find.byKey(const Key('solicitar-cambio-enviar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('mínimo 10 caracteres'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'Mi teléfono cambió porque perdí el chip.',
      );
      await tester.tap(find.byKey(const Key('solicitar-cambio-enviar')));
      await tester.pumpAndSettle();
      expect(find.text('Recibimos tu solicitud'), findsOneWidget);

      await tester.tap(find.byKey(const Key('solicitar-cambio-listo')));
      await tester.pumpAndSettle();
      // De vuelta: la solicitud queda en revisión y no se puede enviar otra.
      expect(
        find.textContaining('Tu solicitud de cambio está en revisión'),
        findsOneWidget,
      );
      final boton = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('datos-solicitar-cambio')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('un error de carga ofrece reintentar', (tester) async {
      await _abrir(tester, const DatosPersonalesRed());
      expect(find.text('No pudimos cargar tus datos'), findsOneWidget);
    });
  });

  group('Ajustes', () {
    Future<void> abrirAjustes(
      WidgetTester tester,
      DatosPersonalesRepositorio? repo,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget app = MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: const AjustesPantalla(),
      );
      if (repo != null) {
        app = RepositoryProvider<DatosPersonalesRepositorio>.value(
          value: repo,
          child: app,
        );
      }
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'ofrece «Datos personales» solo si la función está disponible',
      (tester) async {
        await abrirAjustes(tester, _demo());
        expect(
          find.byKey(const Key('ajustes-datos-personales')),
          findsOneWidget,
        );
        await abrirAjustes(tester, const DatosPersonalesRed());
        expect(find.byKey(const Key('ajustes-datos-personales')), findsNothing);
        await abrirAjustes(tester, null);
        expect(find.byKey(const Key('ajustes-datos-personales')), findsNothing);
      },
    );
  });
}
