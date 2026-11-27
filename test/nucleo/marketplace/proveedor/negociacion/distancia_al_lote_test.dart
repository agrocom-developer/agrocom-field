import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/geo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/domain/ejecucion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/distancia_al_lote.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/distancia_al_lote_vista.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/distancia_cubit.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio de ubicación que cuenta cuántas veces se pidió cada cosa.
class _Gps implements ServicioUbicacion {
  _Gps(this.permiso, {this.posicion = const GeoPunto(-17.78, -63.18)});

  PermisoUbicacion permiso;
  GeoPunto? posicion;
  PermisoUbicacion alPedir = PermisoUbicacion.concedido;
  int pedidos = 0;
  int lecturas = 0;

  @override
  Future<PermisoUbicacion> estado() async => permiso;

  @override
  Future<PermisoUbicacion> pedir() async {
    pedidos++;
    return permiso = alPedir;
  }

  @override
  Future<GeoPunto?> actual() async {
    lecturas++;
    return posicion;
  }
}

const _lote = GeoPunto(-17.5341, -63.1968);

void main() {
  group('DistanciaAlLote', () {
    test('el mismo punto está a 0,0 km', () {
      expect(DistanciaAlLote.kilometros(_lote, _lote), Decimal.parse('0.0'));
    });

    test('Santa Cruz a Montero ronda los 50 km, con un decimal', () {
      const santaCruz = GeoPunto(-17.7833, -63.1821);
      const montero = GeoPunto(-17.3395, -63.2506);
      final km = DistanciaAlLote.kilometros(santaCruz, montero);
      expect(km.scale, lessThanOrEqualTo(1));
      expect(km, greaterThan(Decimal.parse('48')));
      expect(km, lessThan(Decimal.parse('51')));
    });

    test('es simétrica', () {
      const a = GeoPunto(-17.78, -63.18);
      expect(
        DistanciaAlLote.kilometros(a, _lote),
        DistanciaAlLote.kilometros(_lote, a),
      );
    });
  });

  group('DistanciaCubit', () {
    test('sin punto del lote no pide nada', () async {
      final gps = _Gps(PermisoUbicacion.concedido);
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(null, explicar: () async => true);
      expect(cubit.state.fase, FaseDistancia.sinLote);
      expect(gps.lecturas, 0);
      await cubit.close();
    });

    test('con el permiso concedido calcula sin explicar de nuevo', () async {
      final gps = _Gps(PermisoUbicacion.concedido);
      var explicaciones = 0;
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(
        _lote,
        explicar: () async {
          explicaciones++;
          return true;
        },
      );
      expect(cubit.state.fase, FaseDistancia.lista);
      expect(cubit.state.km, isNotNull);
      expect(explicaciones, 0);
      expect(gps.pedidos, 0);
      await cubit.close();
    });

    test('denegado: explica, pide el permiso y calcula', () async {
      final gps = _Gps(PermisoUbicacion.denegado);
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(_lote, explicar: () async => true);
      expect(gps.pedidos, 1);
      expect(cubit.state.fase, FaseDistancia.lista);
      await cubit.close();
    });

    test('«Ahora no» no molesta al sistema ni lee la posición', () async {
      final gps = _Gps(PermisoUbicacion.denegado);
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(_lote, explicar: () async => false);
      expect(gps.pedidos, 0);
      expect(gps.lecturas, 0);
      expect(cubit.state.fase, FaseDistancia.inicial);
      await cubit.close();
    });

    test('si el sistema niega el permiso, lo dice', () async {
      final gps = _Gps(PermisoUbicacion.denegado)
        ..alPedir = PermisoUbicacion.denegado;
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(_lote, explicar: () async => true);
      expect(cubit.state.fase, FaseDistancia.sinPermiso);
      expect(gps.lecturas, 0);
      await cubit.close();
    });

    test('denegado para siempre y GPS apagado llevan a los ajustes', () async {
      final siempre = DistanciaCubit(
        _Gps(PermisoUbicacion.denegadoParaSiempre),
      );
      await siempre.calcular(_lote, explicar: () async => true);
      expect(siempre.state.fase, FaseDistancia.denegadoParaSiempre);
      final apagado = DistanciaCubit(_Gps(PermisoUbicacion.servicioApagado));
      await apagado.calcular(_lote, explicar: () async => true);
      expect(apagado.state.fase, FaseDistancia.servicioApagado);
      await siempre.close();
      await apagado.close();
    });

    test('sin posición avisa y no inventa una distancia', () async {
      final gps = _Gps(PermisoUbicacion.concedido, posicion: null);
      final cubit = DistanciaCubit(gps);
      await cubit.calcular(_lote, explicar: () async => true);
      expect(cubit.state.fase, FaseDistancia.sinPosicion);
      expect(cubit.state.km, isNull);
      await cubit.close();
    });

    test('el estado solo guarda kilómetros, nunca la posición', () async {
      final cubit = DistanciaCubit(_Gps(PermisoUbicacion.concedido));
      await cubit.calcular(_lote, explicar: () async => true);
      expect(cubit.state.km, isA<Decimal>());
      await cubit.close();
    });
  });

  group('DistanciaAlLoteVista', () {
    Widget app(ServicioUbicacion gps) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
      home: Scaffold(
        body: DistanciaAlLoteVista(lote: _lote, servicio: gps),
      ),
    );

    testWidgets('no pide el permiso al mostrarse, solo al tocar', (
      tester,
    ) async {
      final gps = _Gps(PermisoUbicacion.denegado);
      await tester.pumpWidget(app(gps));
      expect(find.text('¿Qué tan lejos está el lote?'), findsOneWidget);
      expect(gps.pedidos, 0);
      expect(gps.lecturas, 0);
    });

    testWidgets('explica el motivo antes de pedir y luego muestra los km', (
      tester,
    ) async {
      final gps = _Gps(PermisoUbicacion.denegado);
      await tester.pumpWidget(app(gps));
      await tester.tap(find.byKey(const ValueKey('distancia-calcular')));
      await tester.pumpAndSettle();
      expect(find.text('Calcular la distancia al lote'), findsOneWidget);
      expect(gps.pedidos, 0);
      await tester.tap(find.byKey(const ValueKey('distancia-continuar')));
      await tester.pumpAndSettle();
      expect(gps.pedidos, 1);
      expect(find.textContaining('del lote'), findsOneWidget);
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('«Ahora no» deja todo como estaba', (tester) async {
      final gps = _Gps(PermisoUbicacion.denegado);
      await tester.pumpWidget(app(gps));
      await tester.tap(find.byKey(const ValueKey('distancia-calcular')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('distancia-ahora-no')));
      await tester.pumpAndSettle();
      expect(gps.pedidos, 0);
      expect(find.text('¿Qué tan lejos está el lote?'), findsOneWidget);
    });
  });
}
