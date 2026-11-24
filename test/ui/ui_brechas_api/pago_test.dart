// Pago confirmado: «Ya recibí el pago» del proveedor titular (en línea, con
// reintento idempotente) y el sello que ve el cliente en el seguimiento.

import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/pago_confirmado.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/pagos_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/presentation/pago_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/presentation/tarjetas_pago.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

final _ahora = DateTime(2026, 11, 24, 9);

/// Falla las primeras veces con el error dado y luego responde como la demo.
class _Inestable extends PagosDemo {
  _Inestable({
    this.fallos = 0,
    this.error = const SinConexion(),
    super.montos,
    super.previos,
  }) : super(reloj: () => _ahora);

  int fallos;
  final Object error;
  final uuids = <String>[];
  var confirmaciones = 0;

  @override
  Future<PagoConfirmado> confirmar(
    int solicitudId, {
    required String uuidCliente,
    MetodoPago? metodo,
    String? nota,
  }) {
    confirmaciones++;
    uuids.add(uuidCliente);
    if (fallos > 0) {
      fallos--;
      throw error;
    }
    return super.confirmar(
      solicitudId,
      uuidCliente: uuidCliente,
      metodo: metodo,
      nota: nota,
    );
  }
}

class _LecturaFalla extends PagosDemo {
  _LecturaFalla(this.error);

  final Object error;

  @override
  Future<PagoConfirmado?> ver(int solicitudId) async => throw error;
}

PagoConfirmado _pago({int solicitud = 10, String uuid = 'otro'}) =>
    PagoConfirmado(
      id: 3,
      uuidCliente: uuid,
      solicitudId: solicitud,
      monto: Decimal.parse('9200'),
      metodo: MetodoPago.transferencia,
      confirmadoEn: _ahora,
    );

List<RepositoryProvider<Object>> _con(PagosRepositorio r) => [
  RepositoryProvider<PagosRepositorio>.value(value: r),
];

final _montos = {10: Decimal.parse('9200')};

void main() {
  setUpAll(cargarFuentes);

  group('PagoCubit', () {
    test('confirmar registra el pago con el monto del servidor', () async {
      final repo = _Inestable(montos: _montos);
      final c = PagoCubit(repo, 10, uuidCliente: 'u-1');
      await c.cargar();
      expect(c.state.fase, FasePago.pendiente);

      c.elegirMetodo(MetodoPago.qr);
      await c.confirmar();
      expect(c.state.fase, FasePago.confirmado);
      expect(c.state.pago!.monto, Decimal.parse('9200'));
      expect(c.state.pago!.metodo, MetodoPago.qr);
    });

    test('reintentar tras un fallo reutiliza el mismo uuid_cliente', () async {
      final repo = _Inestable(fallos: 2, montos: _montos);
      final c = PagoCubit(repo, 10);
      await c.cargar();
      await c.confirmar();
      expect(c.state.fase, FasePago.error);
      expect(c.state.fallo, FalloPago.sinRed);
      expect(c.state.sePuedeReintentar, isTrue);
      await c.confirmar();
      expect(c.state.fase, FasePago.error);
      await c.confirmar();
      expect(c.state.fase, FasePago.confirmado);
      expect(repo.uuids.toSet(), hasLength(1));
      expect(repo.confirmaciones, 3);
    });

    test('un doble toque no confirma dos veces', () async {
      final repo = _Inestable(montos: _montos);
      final c = PagoCubit(repo, 10);
      await c.cargar();
      await Future.wait([c.confirmar(), c.confirmar()]);
      expect(repo.confirmaciones, 1);
    });

    test(
      'si el pago ya estaba confirmado por otro registro lo muestra',
      () async {
        final repo = _Inestable(
          error: const OperacionRechazada(
            'ya',
            codigo: 409,
            motivo: MotivoPago.yaConfirmado,
          ),
          fallos: 1,
          previos: [_pago()],
        );
        final c = PagoCubit(repo, 10);
        // Se carga antes de que el servidor lo tuviera: se simula con un
        // estado pendiente y un 409 al confirmar.
        c.emit(const PagoEstado(fase: FasePago.pendiente));
        await c.confirmar();
        expect(c.state.fase, FasePago.confirmado);
        expect(c.state.pago!.uuidCliente, 'otro');
      },
    );

    test('quien no es titular recibe una explicación y no reintento', () async {
      final repo = _Inestable(
        fallos: 1,
        error: const OperacionRechazada(
          'No',
          codigo: 403,
          motivo: MotivoPago.soloTitular,
        ),
        montos: _montos,
      );
      final c = PagoCubit(repo, 10);
      await c.cargar();
      await c.confirmar();
      expect(c.state.fallo, FalloPago.soloTitular);
      expect(c.state.sePuedeReintentar, isFalse);
      expect(c.state.mensaje, contains('titular'));
    });

    test('un error al leer no dice que falló la confirmación', () async {
      final c = PagoCubit(_LecturaFalla(const SinConexion()), 10);
      await c.cargar();
      expect(c.state.fase, FasePago.error);
      expect(c.state.fallaAlLeer, isTrue);
    });
  });

  group('TarjetaConfirmarPago (proveedor)', () {
    Future<void> abrir(
      WidgetTester tester,
      PagosRepositorio repo, {
      Variante? variante,
    }) async {
      await montar(
        tester,
        const TarjetaConfirmarPago(solicitudId: 10),
        variante: variante ?? matrizCampo[1],
        repositorios: _con(repo),
      );
      await asentar(tester);
    }

    testWidgets('pide confirmación y deja el sello «Pago confirmado»', (
      tester,
    ) async {
      await abrir(tester, _Inestable(montos: _montos));
      expect(find.text('¿Ya te pagaron?'), findsOneWidget);
      expect(find.textContaining('la app no cobra'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pago-metodo-transferencia')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      expect(find.text('¿Confirmas que recibiste el pago?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pago-confirmar-si')));
      await asentar(tester);
      expect(find.text('Pago confirmado'), findsOneWidget);
      expect(find.textContaining('Bs 9.200'), findsOneWidget);
      expect(find.textContaining('Transferencia'), findsOneWidget);
      expect(find.byKey(const Key('pago-confirmar')), findsNothing);
    });

    testWidgets('«Todavía no» no confirma nada', (tester) async {
      final repo = _Inestable(montos: _montos);
      await abrir(tester, repo);
      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      await tester.tap(find.text('Todavía no'));
      await asentar(tester);
      expect(repo.confirmaciones, 0);
    });

    testWidgets('sin red muestra el aviso y reintenta con el mismo uuid', (
      tester,
    ) async {
      final repo = _Inestable(fallos: 1, montos: _montos);
      await abrir(tester, repo);
      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('pago-confirmar-si')));
      await asentar(tester);
      expect(find.byKey(const Key('pago-aviso')), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      expect(find.text('Pago confirmado'), findsOneWidget);
      expect(repo.uuids.toSet(), hasLength(1));
    });

    testWidgets('quien no es titular no ve el botón de reintento', (
      tester,
    ) async {
      final repo = _Inestable(
        fallos: 1,
        error: const OperacionRechazada(
          'No',
          codigo: 403,
          motivo: MotivoPago.soloTitular,
        ),
      );
      await abrir(tester, repo);
      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('pago-confirmar-si')));
      await asentar(tester);
      expect(find.textContaining('titular'), findsOneWidget);
      expect(find.byKey(const Key('pago-confirmar')), findsNothing);
    });

    testWidgets('si ya estaba confirmado muestra el sello directo', (
      tester,
    ) async {
      await abrir(tester, _Inestable(previos: [_pago()]));
      expect(find.text('Pago confirmado'), findsOneWidget);
    });

    testWidgets('el botón mide 56 dp o más y tiene etiqueta', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester, _Inestable(montos: _montos));
      expect(
        tester.getSize(find.byKey(const Key('pago-confirmar'))).height,
        greaterThanOrEqualTo(56),
      );
      expect(find.bySemanticsLabel('Ya recibí el pago'), findsWidgets);
      semantica.dispose();
    });

    for (final v in matrizCampo) {
      testWidgets('golden pendiente ${v.nombre}', (tester) async {
        await abrir(tester, _Inestable(montos: _montos), variante: v);
        await golden(tester, 'pago_proveedor_pendiente_${v.nombre}');
      }, skip: saltarGolden != null);
      testWidgets('golden confirmado ${v.nombre}', (tester) async {
        await abrir(tester, _Inestable(previos: [_pago()]), variante: v);
        await golden(tester, 'pago_proveedor_confirmado_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    testWidgets('golden error sin red y carga', (tester) async {
      await abrir(
        tester,
        _Inestable(fallos: 1, montos: _montos),
        variante: matrizCampo.first,
      );
      await tester.tap(find.byKey(const Key('pago-confirmar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('pago-confirmar-si')));
      await asentar(tester);
      await golden(tester, 'pago_proveedor_sin_red_campo_360');
    }, skip: saltarGolden != null);
  });

  group('TarjetaPagoDelCliente', () {
    Future<void> abrir(
      WidgetTester tester,
      PagosRepositorio repo, {
      Variante? variante,
    }) async {
      await montar(
        tester,
        const TarjetaPagoDelCliente(solicitudId: 10),
        variante: variante ?? matrizCliente[1],
        repositorios: _con(repo),
      );
      await asentar(tester);
    }

    testWidgets('con pago confirmado muestra «Pago confirmado»', (
      tester,
    ) async {
      await abrir(tester, _Inestable(previos: [_pago()]));
      expect(find.text('Pago confirmado'), findsOneWidget);
      expect(find.textContaining('El piloto confirmó'), findsOneWidget);
    });

    testWidgets('sin pago explica qué esperar y no ofrece confirmar', (
      tester,
    ) async {
      await abrir(tester, _Inestable());
      expect(find.text('Pago pendiente'), findsOneWidget);
      expect(find.byKey(const Key('pago-confirmar')), findsNothing);
    });

    testWidgets('un error al leer permite reintentar', (tester) async {
      await abrir(tester, _LecturaFalla(const SinConexion()));
      expect(find.byKey(const Key('pago-cliente-error')), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    for (final v in matrizCliente) {
      testWidgets('golden confirmado ${v.nombre}', (tester) async {
        await abrir(tester, _Inestable(previos: [_pago()]), variante: v);
        await golden(tester, 'pago_cliente_confirmado_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    testWidgets('golden pendiente, error y carga', (tester) async {
      final v = matrizCliente.first;
      await abrir(tester, _Inestable(), variante: v);
      await golden(tester, 'pago_cliente_pendiente_${v.nombre}');
      await abrir(tester, _LecturaFalla(const SinConexion()), variante: v);
      await golden(tester, 'pago_cliente_sin_red_${v.nombre}');
    }, skip: saltarGolden != null);
  });
}
