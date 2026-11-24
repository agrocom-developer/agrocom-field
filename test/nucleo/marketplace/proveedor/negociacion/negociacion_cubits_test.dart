// Cubits de la negociación del piloto: mapa, primera oferta, mis ofertas,
// chat y avisos. La negociación no usa outbox (ADR 0016): los reintentos son
// seguros porque cada intento conserva su `uuid_cliente`.

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/avisos_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/chat_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/ofertar_cubit.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _Contador implements Uuid {
  int n = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #v4 ? 'k${++n}' : super.noSuchMethod(invocation);
}

/// Mercado que falla las primeras veces con lo que se le pida.
class _MercadoQueFalla extends MercadoDemo {
  _MercadoQueFalla(super.almacen);

  final claves = <String>[];
  Object? falla;

  @override
  Future<OfertaNegociada> ofertar({
    required int solicitudId,
    required String uuidCliente,
    required TipoOferta tipo,
    Decimal? precioHa,
    String? nota,
  }) {
    claves.add(uuidCliente);
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
    return super.ofertar(
      solicitudId: solicitudId,
      uuidCliente: uuidCliente,
      tipo: tipo,
      precioHa: precioHa,
      nota: nota,
    );
  }
}

class _NegociacionQueFalla extends NegociacionDemo {
  _NegociacionQueFalla(super.almacen);

  final claves = <String>[];
  Object? falla;

  @override
  Future<OfertaNegociada> contraofertar(
    int ofertaId, {
    required Decimal precioHa,
    required String uuidCliente,
    String? nota,
  }) {
    claves.add(uuidCliente);
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
    return super.contraofertar(
      ofertaId,
      precioHa: precioHa,
      uuidCliente: uuidCliente,
      nota: nota,
    );
  }

  @override
  Future<OfertaNegociada> aceptar(int ofertaId) {
    final f = falla;
    if (f != null) {
      falla = null;
      throw f;
    }
    return super.aceptar(ofertaId);
  }
}

AlmacenNegociacionDemo _almacen() =>
    AlmacenNegociacionDemo(latencia: Duration.zero);

void main() {
  group('mapa de solicitudes', () {
    test('carga las solicitudes y el resumen por zona', () async {
      final cubit = MapaSolicitudesCubit(MercadoDemo(_almacen()));
      await cubit.cargar();
      expect(cubit.state.estado, EstadoMapa.listo);
      expect(cubit.state.solicitudes, hasLength(6));
      expect(cubit.state.zonas, hasLength(6));
      await cubit.close();
    });

    test('filtrar por macrorregión deja solo las de esa zona', () async {
      final cubit = MapaSolicitudesCubit(MercadoDemo(_almacen()));
      await cubit.aplicarFiltros(
        const FiltrosMapa(macrorregion: Macrorregion.chiquitania),
      );
      expect(cubit.state.solicitudes.map((s) => s.id), [5, 6]);
      expect(cubit.state.filtros.hayFiltros, isTrue);
      await cubit.close();
    });

    test('filtrar por hectáreas y precio combina los filtros', () async {
      final cubit = MapaSolicitudesCubit(MercadoDemo(_almacen()));
      await cubit.aplicarFiltros(
        FiltrosMapa(
          hectareasMin: Decimal.parse('90'),
          precioHaMin: Decimal.parse('120'),
        ),
      );
      expect(cubit.state.solicitudes.map((s) => s.id), [4]);
      await cubit.close();
    });

    test(
      'sin conexión muestra el estado sin red y se puede reintentar',
      () async {
        final almacen = _almacen()..enLinea = false;
        final cubit = MapaSolicitudesCubit(MercadoDemo(almacen));
        await cubit.cargar();
        expect(cubit.state.estado, EstadoMapa.sinRed);
        almacen.enLinea = true;
        await cubit.cargar();
        expect(cubit.state.estado, EstadoMapa.listo);
        await cubit.close();
      },
    );

    test('seleccionar resalta una solicitud', () async {
      final cubit = MapaSolicitudesCubit(MercadoDemo(_almacen()));
      await cubit.cargar();
      cubit.seleccionar(3);
      expect(cubit.state.seleccionada, 3);
      cubit.seleccionar(null);
      expect(cubit.state.seleccionada, isNull);
      await cubit.close();
    });
  });

  group('primera oferta', () {
    test('aceptar el precio propuesto envía una oferta vigente', () async {
      final cubit = OfertarCubit(MercadoDemo(_almacen()), uuid: _Contador());
      await cubit.ofertar(solicitudId: 1, tipo: TipoOferta.aceptaPropuesta);
      expect(cubit.state.estado, FaseOferta.enviada);
      expect(cubit.state.oferta!.precioHa, Decimal.parse('121'));
      expect(cubit.state.oferta!.esperaAlCliente, isTrue);
      await cubit.close();
    });

    test(
      'si la respuesta se pierde, el reintento usa la MISMA clave',
      () async {
        final mercado = _MercadoQueFalla(_almacen())
          ..falla = const SinConexion();
        final cubit = OfertarCubit(mercado, uuid: _Contador());
        await cubit.ofertar(
          solicitudId: 1,
          tipo: TipoOferta.contraoferta,
          precioHa: Decimal.parse('118'),
        );
        expect(cubit.state.sinRed, isTrue);
        await cubit.ofertar(
          solicitudId: 1,
          tipo: TipoOferta.contraoferta,
          precioHa: Decimal.parse('118'),
        );
        expect(mercado.claves, ['k1', 'k1']);
        expect(cubit.state.estado, FaseOferta.enviada);
        await cubit.close();
      },
    );

    test(
      'una respuesta del servidor cierra el intento: el próximo es nuevo',
      () async {
        final mercado = _MercadoQueFalla(
          _almacen(),
        )..falla = const OperacionRechazada('La solicitud ya no está abierta.');
        final cubit = OfertarCubit(mercado, uuid: _Contador());
        await cubit.ofertar(solicitudId: 1, tipo: TipoOferta.aceptaPropuesta);
        expect(cubit.state.mensaje, 'La solicitud ya no está abierta.');
        await cubit.ofertar(solicitudId: 1, tipo: TipoOferta.aceptaPropuesta);
        expect(mercado.claves, ['k1', 'k2']);
        await cubit.close();
      },
    );
  });

  group('mis ofertas', () {
    test(
      'primero las que piden respuesta, luego las que espera el cliente',
      () async {
        final cubit = MisOfertasCubit(NegociacionDemo(_almacen()));
        await cubit.cargar();
        final ids = cubit.state.ordenadas.map((o) => o.id).toList();
        expect(ids, [501, 502, 503]);
        expect(cubit.state.ordenadas.first.esperaMiRespuesta, isTrue);
        await cubit.close();
      },
    );

    test('aceptar la contraoferta del cliente la adjudica y recarga', () async {
      final cubit = MisOfertasCubit(NegociacionDemo(_almacen()));
      await cubit.cargar();
      await cubit.aceptar(cubit.state.ofertas.firstWhere((o) => o.id == 501));
      expect(
        cubit.state.ofertas.firstWhere((o) => o.id == 501).estado,
        EstadoOferta.aceptada,
      );
      expect(cubit.state.aviso, contains('te eligió'));
      expect(cubit.state.avisoEsError, isFalse);
      await cubit.close();
    });

    test('contraofertar de vuelta conserva la clave si no hay red', () async {
      final negociacion = _NegociacionQueFalla(_almacen())
        ..falla = const SinConexion();
      final cubit = MisOfertasCubit(negociacion, uuid: _Contador());
      await cubit.cargar();
      final oferta = cubit.state.ofertas.firstWhere((o) => o.id == 501);
      await cubit.contraofertar(oferta, precioHa: Decimal.parse('125'));
      expect(cubit.state.avisoEsError, isTrue);
      await cubit.contraofertar(oferta, precioHa: Decimal.parse('125'));
      expect(negociacion.claves, ['k1', 'k1']);
      // Una oferta nueva reemplaza a la anterior y le toca al cliente.
      expect(cubit.state.ofertas.where((o) => o.esperaAlCliente).length, 2);
      await cubit.close();
    });

    test('un conflicto se explica y recarga la lista', () async {
      final negociacion = _NegociacionQueFalla(_almacen())
        ..falla = const OperacionRechazada(
          'x',
          codigo: 409,
          motivo: 'solicitud_ya_adjudicada',
        );
      final cubit = MisOfertasCubit(negociacion);
      await cubit.cargar();
      await cubit.aceptar(cubit.state.ofertas.firstWhere((o) => o.id == 501));
      expect(cubit.state.aviso, contains('eligió a otro piloto'));
      expect(cubit.state.avisoEsError, isTrue);
      expect(cubit.state.enCurso, isNull);
      await cubit.close();
    });

    test('retirar una oferta propia la cierra', () async {
      final cubit = MisOfertasCubit(NegociacionDemo(_almacen()));
      await cubit.cargar();
      await cubit.retirar(cubit.state.ofertas.firstWhere((o) => o.id == 502));
      expect(
        cubit.state.ofertas.firstWhere((o) => o.id == 502).estado,
        EstadoOferta.retirada,
      );
      await cubit.close();
    });

    test(
      'sin conexión y sin nada cargado, muestra el estado sin red',
      () async {
        final almacen = _almacen()..enLinea = false;
        final cubit = MisOfertasCubit(NegociacionDemo(almacen));
        await cubit.cargar();
        expect(cubit.state.estado, EstadoMisOfertas.sinRed);
        await cubit.close();
      },
    );
  });

  group('chat', () {
    test('lee los mensajes y los muestra en orden', () async {
      final cubit = ChatCubit(
        MensajesDemo(_almacen()),
        10,
        intervalo: const Duration(hours: 1),
      );
      await cubit.iniciar();
      expect(cubit.state.cargando, isFalse);
      expect(cubit.state.mensajes, hasLength(2));
      expect(cubit.state.mensajes.first.propio, isTrue);
      await cubit.close();
    });

    test('enviar agrega el mensaje y vacía lo escrito', () async {
      final cubit = ChatCubit(
        MensajesDemo(_almacen()),
        10,
        intervalo: const Duration(hours: 1),
      );
      await cubit.iniciar();
      expect(await cubit.enviar('  Llego a las 7  '), isTrue);
      expect(cubit.state.mensajes.last.texto, 'Llego a las 7');
      await cubit.close();
    });

    test('un mensaje vacío no se envía', () async {
      final cubit = ChatCubit(
        MensajesDemo(_almacen()),
        10,
        intervalo: const Duration(hours: 1),
      );
      await cubit.iniciar();
      expect(await cubit.enviar('   '), isFalse);
      await cubit.close();
    });

    test('sin red conserva el texto y reintenta con la misma clave', () async {
      final almacen = _almacen();
      final cubit = ChatCubit(
        MensajesDemo(almacen),
        10,
        uuid: _Contador(),
        intervalo: const Duration(hours: 1),
      );
      await cubit.iniciar();
      almacen.enLinea = false;
      expect(await cubit.enviar('Hola'), isFalse);
      expect(cubit.state.aviso, contains('Sin conexión'));
      almacen.enLinea = true;
      expect(await cubit.enviar('Hola'), isTrue);
      expect(
        almacen.mensajesDe(10).where((m) => m.uuidCliente == 'k1'),
        hasLength(1),
      );
      await cubit.close();
    });
  });

  group('avisos', () {
    test('activar las nuevas solicitudes se guarda', () async {
      final almacen = _almacen()
        ..preferencias = const PreferenciasAviso(nuevasSolicitudes: false);
      final cubit = AvisosCubit(AvisosDemo(almacen));
      await cubit.cargar();
      expect(cubit.state.preferencias.nuevasSolicitudes, isFalse);
      await cubit.cambiar(
        cubit.state.preferencias.copiarCon(nuevasSolicitudes: true),
      );
      expect(almacen.preferencias.nuevasSolicitudes, isTrue);
      await cubit.close();
    });

    test('si no se puede guardar, vuelve atrás y dice por qué', () async {
      final almacen = _almacen();
      final cubit = AvisosCubit(AvisosDemo(almacen));
      await cubit.cargar();
      almacen.enLinea = false;
      await cubit.cambiar(
        cubit.state.preferencias.copiarCon(nuevasSolicitudes: false),
      );
      expect(cubit.state.preferencias.nuevasSolicitudes, isTrue);
      expect(cubit.state.aviso, contains('No se guardó'));
      await cubit.close();
    });
  });
}
