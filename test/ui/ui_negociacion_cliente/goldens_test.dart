// Goldens de las pantallas del cliente de la negociación: lista de
// solicitudes, detalle, ofertas, seguimiento, chat, calificación y reclamo.
// Cada pantalla principal se captura en claro (teléfono chico y grande), en
// oscuro (grande) y con el texto al 200 % (chico); los estados secundarios
// (carga, vacío, error, sin señal, éxito) se capturan una vez. Un desborde de
// layout hace fallar la prueba antes de comparar.
//
// Se regeneran con
// `flutter test --update-goldens test/ui/ui_negociacion_cliente`.
// Solo corren en macOS (el render de texto difiere en Linux).

import 'dart:async';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/ofertas/domain/ofertas_repositorio.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/ofertas_pantalla.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento_repositorio.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_pantalla.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/cliente/solicitar/domain/solicitud_repositorio.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitudes_repositorio.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/historial_pantalla.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/solicitud_detalle_pantalla.dart';

import 'ayudas.dart';

/// Solicitudes que nunca llegan (carga) o que llegan vacías.
class _SolicitudesFijas implements SolicitudesRepositorio {
  _SolicitudesFijas(this.lista);

  final List<Solicitud>? lista;

  @override
  Stream<List<Solicitud>> observar() =>
      lista == null ? const Stream.empty() : Stream.value(lista!);

  @override
  Future<Solicitud?> porId(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ofertas que nunca terminan de cargar.
class _OfertasPendientes implements OfertasRepositorio {
  @override
  Future<List<OfertaRecibida>> deLaSolicitud(String solicitudId) =>
      Completer<List<OfertaRecibida>>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Seguimiento que delega en la demo pero decide la ubicación del piloto.
class _SeguimientoConUbicacion implements SeguimientoRepositorio {
  _SeguimientoConUbicacion(this._base, this._ubicacion);

  final SeguimientoRepositorio _base;
  final UbicacionPiloto? Function(UbicacionPiloto?) _ubicacion;

  @override
  Future<AvanceServicio> avance(String id) => _base.avance(id);

  @override
  Future<UbicacionPiloto?> ubicacionDelPiloto(String id) async =>
      _ubicacion(await _base.ubicacionDelPiloto(id));

  @override
  Future<PaginaMensajes> mensajes(String id, {String? despues}) =>
      _base.mensajes(id, despues: despues);

  @override
  Future<MensajeChat> enviarMensaje(
    String id, {
    required String texto,
    required String claveCliente,
  }) => _base.enviarMensaje(id, texto: texto, claveCliente: claveCliente);

  @override
  Future<MensajeChat> enviarFoto(
    String id, {
    required Uint8List bytes,
    required String claveCliente,
    String? pie,
  }) =>
      _base.enviarFoto(id, bytes: bytes, claveCliente: claveCliente, pie: pie);

  @override
  Future<Uint8List> archivo(String ruta) => _base.archivo(ruta);

  @override
  Future<void> marcarLeidos(String id, String cursor) =>
      _base.marcarLeidos(id, cursor);
}

Widget _historial() => Scaffold(
  body: SafeArea(child: HistorialPantalla(reloj: () => ahoraDePrueba)),
);

Widget _ofertas(String id) => OfertasPantalla(
  solicitudId: id,
  reloj: () => ahoraDePrueba,
  intervalo: null,
);

Widget _seguimiento(String id) => SeguimientoPantalla(
  solicitudId: id,
  reloj: () => ahoraDePrueba,
  intervalo: null,
);

Widget _chat(String id) => ChatPantalla(solicitudId: id, intervalo: null);

/// Una solicitud abierta, recién publicada y sin ofertas.
Future<Solicitud> _abierta(AlmacenDemoCliente almacen) =>
    SolicitudDemo(almacen, latencia: Duration.zero).publicar(
      NuevaSolicitud(
        lote: almacen.datos.lotes[3],
        hectareas: Decimal.parse('150'),
        cultivo: 'Trigo',
        producto: 'Fungicida triazol + estrobilurina',
        fechaDeseada: ahoraDePrueba.add(const Duration(days: 3)),
        precioHa: Decimal.parse('115'),
        claveIdempotencia: 'golden-abierta',
        observaciones: 'Hay una línea eléctrica al sur del lote.',
      ),
    );

/// Adjudica la oferta [id] y devuelve la solicitud ya sin empezar.
void _adjudicar(AlmacenDemoCliente almacen, String id) =>
    almacen.adjudicar(almacen.ofertaPorId(id)!);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  /// Una captura por cada variante de la matriz.
  void matriz(
    String nombre,
    Future<void> Function(WidgetTester tester, Variante variante) preparar,
  ) {
    for (final v in Variante.matriz) {
      testWidgets('$nombre · ${v.sufijo}', skip: saltarGolden, (tester) async {
        await preparar(tester, v);
        await esperarGolden(tester, '${nombre}_${v.sufijo}.png');
      });
    }
  }

  /// Una sola captura, en la variante base.
  void unica(
    String nombre,
    Future<void> Function(WidgetTester tester, Variante variante) preparar,
  ) {
    testWidgets(nombre, skip: saltarGolden, (tester) async {
      await preparar(tester, Variante.base);
      await esperarGolden(tester, '$nombre.png');
    });
  }

  Future<void> abrir(
    WidgetTester tester,
    AlmacenDemoCliente almacen,
    Widget pantalla,
    Variante v, {
    bool conFotos = false,
    DependenciasClienteFactory? deps,
  }) async {
    await montar(
      tester,
      pantalla: pantalla,
      dependencias: (deps ?? dependenciasDePrueba)(almacen),
      variante: v,
    );
    if (conFotos) await precargarFotos(tester);
    await asentar(tester);
  }

  group('historial', () {
    matriz('historial', (tester, v) async {
      await abrir(tester, almacenDePrueba(), _historial(), v);
    });

    unica('historial_cargando', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(
          almacen,
          solicitudes: _SolicitudesFijas(null),
        ),
        variante: v,
      );
      await asentar(tester);
    });

    unica('historial_vacio', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(
          almacen,
          solicitudes: _SolicitudesFijas(const []),
        ),
        variante: v,
      );
      await asentar(tester);
    });

    unica('historial_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(tester, almacen, _historial(), v);
    });
  });

  group('detalle', () {
    matriz('detalle_con_ofertas', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4101'),
        v,
      );
    });

    matriz('detalle_en_ejecucion', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4102'),
        v,
      );
    });

    matriz('detalle_finalizada', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4103'),
        v,
      );
    });

    unica('detalle_abierta_sin_ofertas', (tester, v) async {
      final almacen = almacenDePrueba();
      final s = (await tester.runAsync(() => _abierta(almacen)))!;
      await abrir(
        tester,
        almacen,
        SolicitudDetallePantalla(solicitudId: s.id),
        v,
      );
    });

    unica('detalle_adjudicada', (tester, v) async {
      final almacen = almacenDePrueba();
      _adjudicar(almacen, 'of-4101-a');
      await abrir(
        tester,
        almacen,
        const SolicitudDetallePantalla(solicitudId: '4101'),
        v,
      );
    });

    unica('detalle_calificada', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4104'),
        v,
      );
    });

    unica('detalle_expirada', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4105'),
        v,
      );
    });

    unica('detalle_cancelada', (tester, v) async {
      final almacen = almacenDePrueba();
      final s = almacen.porId('4105')!;
      almacen.reemplazar(s.copiarCon(estado: EstadoSolicitud.cancelada));
      await abrir(
        tester,
        almacen,
        const SolicitudDetallePantalla(solicitudId: '4105'),
        v,
      );
    });

    unica('detalle_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(
        tester,
        almacen,
        const SolicitudDetallePantalla(solicitudId: '4101'),
        v,
      );
    });

    unica('detalle_hoja_cambiar_precio', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4101'),
        v,
      );
      await tester.tap(find.byKey(const ValueKey('cambiar-precio')));
      await asentar(tester);
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '118');
      await asentar(tester);
    });

    unica('detalle_dialogo_cancelar', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        const SolicitudDetallePantalla(solicitudId: '4101'),
        v,
      );
      final boton = find.byKey(const ValueKey('cancelar-solicitud'));
      await tester.dragUntilVisible(
        boton,
        find.byType(ListView).first,
        const Offset(0, -250),
      );
      await tester.ensureVisible(boton);
      await asentar(tester);
      await tester.tap(boton);
      await asentar(tester);
    });
  });

  group('ofertas', () {
    matriz('ofertas', (tester, v) async {
      await abrir(tester, almacenDePrueba(), _ofertas('4101'), v);
    });

    unica('ofertas_cargando', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(
        tester,
        almacen,
        _ofertas('4101'),
        v,
        deps: (a) => dependenciasDePrueba(a, ofertas: _OfertasPendientes()),
      );
    });

    unica('ofertas_vacia', (tester, v) async {
      final almacen = almacenDePrueba();
      final s = (await tester.runAsync(() => _abierta(almacen)))!;
      await abrir(tester, almacen, _ofertas(s.id), v);
    });

    unica('ofertas_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(tester, almacen, _ofertas('4101'), v);
    });

    unica('ofertas_contraoferta_enviada', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, _ofertas('4101'), v);
      await tester.tap(find.byKey(const ValueKey('contraofertar-of-4101-b')));
      await asentar(tester);
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '107');
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('hoja-precio-enviar')));
      await asentar(tester);
    });

    unica('ofertas_hoja_contraoferta', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, _ofertas('4101'), v);
      await tester.tap(find.byKey(const ValueKey('contraofertar-of-4101-b')));
      await asentar(tester);
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '107');
      await asentar(tester);
    });

    unica('ofertas_confirmar_eleccion', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, _ofertas('4101'), v);
      await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
      await asentar(tester);
    });

    unica('ofertas_ultima_ronda', (tester, v) async {
      final almacen = almacenDePrueba();
      // Ronda 1 del piloto, 2 del cliente, 3 del piloto, 4 del cliente y 5
      // del piloto: la última, que solo se elige o se rechaza.
      var o = almacen.ofertaPorId('of-4101-b')!;
      o = almacen.contraofertar(o, AutorOferta.cliente, Decimal.parse('100'));
      o = almacen.contraofertar(o, AutorOferta.proveedor, Decimal.parse('103'));
      o = almacen.contraofertar(o, AutorOferta.cliente, Decimal.parse('101'));
      almacen.contraofertar(o, AutorOferta.proveedor, Decimal.parse('102'));
      await abrir(tester, almacen, _ofertas('4101'), v);
    });

    unica('ofertas_cambio_mientras_decidia', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, _ofertas('4101'), v);
      // El piloto retiró su oferta mientras el cliente la miraba.
      almacen.rechazarOferta(almacen.ofertaPorId('of-4101-b')!);
      await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-aceptar')));
      await asentar(tester);
    });
  });

  group('seguimiento', () {
    matriz('seguimiento_en_ejecucion', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        _seguimiento('4102'),
        v,
        conFotos: true,
      );
    });

    unica('seguimiento_adjudicada', (tester, v) async {
      final almacen = almacenDePrueba();
      _adjudicar(almacen, 'of-4101-a');
      await abrir(tester, almacen, _seguimiento('4101'), v);
    });

    unica('seguimiento_terminado', (tester, v) async {
      await abrir(
        tester,
        almacenDePrueba(),
        _seguimiento('4103'),
        v,
        conFotos: true,
      );
    });

    unica('seguimiento_ubicacion_vieja', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(
        tester,
        almacen,
        _seguimiento('4102'),
        v,
        conFotos: true,
        deps: (a) => dependenciasDePrueba(
          a,
          seguimiento: _SeguimientoConUbicacion(
            SeguimientoDemo(a, latencia: Duration.zero),
            (u) => u == null
                ? null
                : UbicacionPiloto(
                    punto: u.punto,
                    capturadaEn: u.capturadaEn.subtract(
                      const Duration(minutes: 20),
                    ),
                    vigente: false,
                  ),
          ),
        ),
      );
    });

    unica('seguimiento_sin_ubicacion', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(
        tester,
        almacen,
        _seguimiento('4102'),
        v,
        conFotos: true,
        deps: (a) => dependenciasDePrueba(
          a,
          seguimiento: _SeguimientoConUbicacion(
            SeguimientoDemo(a, latencia: Duration.zero),
            (_) => null,
          ),
        ),
      );
    });

    unica('seguimiento_cargando', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _seguimiento('4102'),
        dependencias: dependenciasDePrueba(
          almacen,
          solicitudes: _SolicitudesPendientes(),
        ),
        variante: v,
      );
      await asentar(tester);
    });

    unica('seguimiento_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(tester, almacen, _seguimiento('4102'), v);
    });
  });

  group('chat', () {
    matriz('chat', (tester, v) async {
      await abrir(tester, almacenDePrueba(), _chat('4102'), v);
    });

    unica('chat_vacio', (tester, v) async {
      final almacen = almacenDePrueba();
      _adjudicar(almacen, 'of-4101-a');
      await abrir(tester, almacen, _chat('4101'), v);
    });

    unica('chat_solo_lectura', (tester, v) async {
      await abrir(tester, almacenDePrueba(), _chat('4104'), v);
    });

    unica('chat_envio_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, _chat('4102'), v);
      await tester.enterText(
        find.byKey(const ValueKey('chat-campo')),
        'Llego a las 7 de la mañana.',
      );
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('chat-enviar')));
      await asentar(tester);
    });

    unica('chat_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(tester, almacen, _chat('4102'), v);
    });
  });

  group('calificar', () {
    Future<void> hoja(WidgetTester tester, Variante v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('4103')!),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
    }

    unica('calificar_inicial', hoja);

    matriz('calificar_con_estrellas', (tester, v) async {
      await hoja(tester, v);
      await tester.tap(find.bySemanticsLabel('5 estrellas'));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('etiqueta-puntualidad')));
      await asentar(tester);
    });
  });

  group('reportar problema', () {
    Future<void> formulario(WidgetTester tester, Variante v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ReportarProblemaPantalla(servicio: almacen.porId('4103')!),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await asentar(tester);
    }

    matriz('problema', (tester, v) async {
      await formulario(tester, v);
      await tester.tap(
        find.byKey(const ValueKey('motivo-coberturaIncompleta')),
      );
      await asentar(tester);
    });

    unica('problema_enviado', (tester, v) async {
      await formulario(tester, v);
      await tester.tap(find.byKey(const ValueKey('motivo-malaAplicacion')));
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('detalle-problema')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.enterText(
        find.byKey(const ValueKey('detalle-problema')),
        'Quedó una franja sin cubrir en la cabecera sur.',
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('enviar-reporte')));
      await asentar(tester);
    });
  });
}

typedef DependenciasClienteFactory =
    DependenciasCliente Function(AlmacenDemoCliente almacen);

/// Solicitudes que nunca llegan, para ver el esqueleto del seguimiento.
class _SolicitudesPendientes implements SolicitudesRepositorio {
  @override
  Future<Solicitud?> porId(String id) => Completer<Solicitud?>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
