import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/notificaciones/data/bandeja_red.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/canal_aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/preferencias_canales.dart';
import 'package:agrocom_field/nucleo/notificaciones/presentation/bandeja_cubit.dart';
import 'package:agrocom_field/nucleo/notificaciones/presentation/bandeja_pantalla.dart';
import 'package:agrocom_field/nucleo/notificaciones/presentation/campana_avisos.dart';
import 'package:agrocom_field/nucleo/notificaciones/presentation/canales_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _ahora = DateTime.utc(2026, 11, 27, 12);

Aviso _aviso(int id, String tipo, {bool leida = false}) => Aviso(
  id: id,
  tipo: tipo,
  titulo: 'Aviso número $id',
  recursoTipo: 'solicitud',
  recursoId: id,
  leida: leida,
  creadaEn: _ahora.subtract(const Duration(minutes: 5)),
);

class _Falla implements BandejaRepositorio {
  _Falla(this.falla);

  Object falla;
  var lecturas = 0;
  final leidas = <int>[];

  @override
  Future<Bandeja> leer() async {
    lecturas++;
    throw falla;
  }

  @override
  Future<void> marcarLeida(int id) async => leidas.add(id);
}

class _Intermitente extends BandejaDemo {
  _Intermitente(super.avisos);

  bool cae = false;

  @override
  Future<Bandeja> leer() => cae ? throw const SinConexion() : super.leer();
}

Widget _app(Widget hijo) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
  home: hijo,
);

Widget _bandeja(BandejaRepositorio repo, {void Function(Aviso)? alAbrir}) =>
    _app(
      BlocProvider(
        create: (_) => BandejaCubit(repo)..cargar(),
        child: BandejaPantalla(alAbrir: alAbrir, reloj: () => DateTime.now()),
      ),
    );

void main() {
  group('BandejaCubit', () {
    test('sin red y sin avisos previos queda en error con sinRed', () async {
      final cubit = BandejaCubit(_Falla(const SinConexion()));
      await cubit.cargar();
      expect(cubit.state.fase, FaseBandeja.error);
      expect(cubit.state.sinRed, isTrue);
      await cubit.close();
    });

    test('con avisos ya a la vista, un fallo los conserva', () async {
      final repo = _Intermitente([_aviso(1, 'mensaje_nuevo')]);
      final cubit = BandejaCubit(repo);
      await cubit.cargar();
      repo.cae = true;
      await cubit.cargar();
      expect(cubit.state.fase, FaseBandeja.lista);
      expect(cubit.state.sinRed, isTrue);
      expect(cubit.state.visibles, hasLength(1));
      await cubit.close();
    });

    test(
      'marcar como leída actualiza al instante y avisa al servidor',
      () async {
        final demo = BandejaDemo([_aviso(1, 'mensaje_nuevo')]);
        final cubit = BandejaCubit(demo);
        await cubit.cargar();
        expect(cubit.state.noLeidas, 1);
        await cubit.marcarLeida(cubit.state.visibles.single);
        expect(cubit.state.noLeidas, 0);
        expect((await demo.leer()).noLeidas, 0);
        await cubit.close();
      },
    );
  });

  testWidgets('muestra los avisos, los grupos y el contador', (tester) async {
    final demo = BandejaDemo([
      _aviso(1, 'mensaje_nuevo'),
      _aviso(2, 'oferta_recibida'),
      _aviso(3, 'sujeto_aprobado', leida: true),
    ]);
    await tester.pumpWidget(_bandeja(demo));
    await tester.pumpAndSettle();
    expect(find.text('Mis notificaciones'), findsOneWidget);
    expect(find.text('Aviso número 1'), findsOneWidget);
    expect(find.text('Aviso número 3'), findsOneWidget);
    expect(find.text('Mensajes · 1'), findsOneWidget);
  });

  testWidgets('un grupo filtra por canal', (tester) async {
    final demo = BandejaDemo([
      _aviso(1, 'mensaje_nuevo'),
      _aviso(2, 'oferta_recibida'),
    ]);
    await tester.pumpWidget(_bandeja(demo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('grupo-mensajes')));
    await tester.pumpAndSettle();
    expect(find.text('Aviso número 1'), findsOneWidget);
    expect(find.text('Aviso número 2'), findsNothing);
  });

  testWidgets('tocar un aviso lo marca como leído y lo abre', (tester) async {
    final demo = BandejaDemo([_aviso(7, 'oferta_recibida')]);
    Aviso? abierto;
    await tester.pumpWidget(_bandeja(demo, alAbrir: (a) => abierto = a));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('aviso-7')));
    await tester.pumpAndSettle();
    expect(abierto?.id, 7);
    expect((await demo.leer()).noLeidas, 0);
  });

  testWidgets('sin avisos muestra el estado vacío orientador', (tester) async {
    await tester.pumpWidget(_bandeja(BandejaDemo(const [])));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no tienes notificaciones'), findsOneWidget);
  });

  testWidgets('sin red muestra el error con salida', (tester) async {
    final falla = _Falla(const SinConexion());
    await tester.pumpWidget(_bandeja(falla));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus notificaciones'), findsOneWidget);
    expect(falla.lecturas, 1);
  });

  testWidgets('la campana muestra los no leídos', (tester) async {
    final demo = BandejaDemo([
      _aviso(1, 'mensaje_nuevo'),
      _aviso(2, 'mensaje_nuevo'),
    ]);
    await tester.pumpWidget(
      _app(
        Scaffold(
          appBar: AppBar(actions: [CampanaAvisos(repositorio: demo)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    final boton = tester.widget<IconButton>(
      find.byKey(const ValueKey('campana-avisos')),
    );
    expect(boton.tooltip, 'Notificaciones, 2 sin leer');
  });

  group('CanalesPantalla', () {
    testWidgets('silenciar un canal lo guarda; el de cuenta no se apaga', (
      tester,
    ) async {
      final store = PreferenciasCanalesMemoria();
      await tester.pumpWidget(_app(CanalesPantalla(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('canal-mensajes')));
      await tester.pumpAndSettle();
      final guardadas = await store.leer();
      expect(guardadas.de(CanalAviso.mensajes).activo, isFalse);
      final cuenta = tester.widget<Switch>(
        find.byKey(const ValueKey('canal-cuenta')),
      );
      expect(cuenta.onChanged, isNull);
      expect(cuenta.value, isTrue);
    });
  });
}
