// Comportamiento de las pantallas del cliente de la negociación (solicitudes,
// ofertas, seguimiento, chat, calificación y reclamo) contra los
// repositorios demo.

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/ofertas_pantalla.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_pantalla.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/historial_pantalla.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/solicitud_detalle_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tokens_campo.dart';

import 'ayudas.dart';

/// Teléfono muy alto: la lista de ofertas arma sus tarjetas a medida que se
/// ven, y estas pruebas tocan las tres.
const _alta = Variante(ModoVisualCampo.claro, Size(412, 2400), 1);

void main() {
  Widget historial() => Scaffold(
    body: SafeArea(child: HistorialPantalla(reloj: () => ahoraDePrueba)),
  );

  Widget ofertas(String id) => OfertasPantalla(
    solicitudId: id,
    reloj: () => ahoraDePrueba,
    intervalo: null,
  );

  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) async {
    await tester.dragUntilVisible(
      objetivo,
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    await tester.ensureVisible(objetivo);
    await asentar(tester, veces: 2);
  }

  group('historial', () {
    testWidgets('resume lo fumigado y filtra la lista', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: historial(),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('274 ha'), findsOneWidget);
      expect(find.byKey(const ValueKey('solicitud-4101')), findsOneWidget);

      await tester.tap(find.text('Listos'));
      await asentar(tester);
      expect(find.byKey(const ValueKey('solicitud-4103')), findsOneWidget);
      expect(find.byKey(const ValueKey('solicitud-4101')), findsNothing);

      await tester.tap(find.text('Activos'));
      await asentar(tester);
      expect(find.byKey(const ValueKey('solicitud-4101')), findsOneWidget);
      expect(find.byKey(const ValueKey('solicitud-4104')), findsNothing);
    });

    testWidgets('sin conexión ofrece reintentar y se recupera', (tester) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await montar(
        tester,
        pantalla: historial(),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      almacen.sinRed = false;
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.byKey(const ValueKey('solicitud-4101')), findsOneWidget);
    });

    testWidgets('abre el detalle de la solicitud tocada', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: historial(),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('solicitud-4102')));
      await asentar(tester, veces: 10);
      expect(find.byType(SolicitudDetallePantalla), findsOneWidget);
      expect(find.text('Soya Norte'), findsNothing);
      expect(find.text('Maíz La Curva'), findsWidgets);
    });
  });

  group('detalle', () {
    Future<AlmacenDemoCliente> abrir(WidgetTester tester, String id) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: SolicitudDetallePantalla(solicitudId: id),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      return almacen;
    }

    testWidgets('con ofertas: la acción es compararlas', (tester) async {
      await abrir(tester, '4101');
      expect(find.text('Ver y comparar las ofertas (3)'), findsOneWidget);
      expect(find.text('Tu precio propuesto'), findsOneWidget);
      expect(find.text('Bs 110/ha'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ver-ofertas')));
      await asentar(tester, veces: 10);
      expect(find.byType(OfertasPantalla), findsOneWidget);
    });

    testWidgets('cambiar el precio actualiza la solicitud', (tester) async {
      final a = await abrir(tester, '4101');
      await tester.tap(find.byKey(const ValueKey('cambiar-precio')));
      await asentar(tester);
      final enviar = find.byKey(const ValueKey('hoja-precio-enviar'));
      // El precio de partida es el vigente; se cambia por otro.
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '');
      await asentar(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(of: enviar, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
        reason: 'sin precio no se puede guardar',
      );
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '118');
      await asentar(tester);
      expect(find.textContaining('Total estimado: Bs 14.160'), findsOneWidget);
      await tester.tap(enviar);
      await asentar(tester, veces: 8);
      expect(a.porId('4101')!.precioHaPropuesto, Decimal.fromInt(118));
      expect(find.text('Bs 118/ha'), findsOneWidget);
    });

    testWidgets('cancelar exige un motivo y cierra la solicitud', (
      tester,
    ) async {
      final a = await abrir(tester, '4101');
      await bajarHasta(
        tester,
        find.byKey(const ValueKey('cancelar-solicitud')),
      );
      await tester.tap(find.byKey(const ValueKey('cancelar-solicitud')));
      await asentar(tester);
      expect(find.text('¿Cancelar la solicitud?'), findsOneWidget);
      final confirmar = find.byKey(const ValueKey('confirmar-cancelar'));
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('motivo-cancelacion')),
        'Cambió la fecha de siembra',
      );
      await asentar(tester);
      await tester.tap(confirmar);
      await asentar(tester, veces: 8);
      expect(a.porId('4101')!.estado, EstadoSolicitud.cancelada);
      expect(find.text('Cancelada'), findsWidgets);
    });

    testWidgets('expirada: se puede volver a abrir', (tester) async {
      final a = await abrir(tester, '4105');
      expect(find.text('Volver a abrir la solicitud'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('renovar')));
      await asentar(tester, veces: 8);
      expect(a.porId('4105')!.estado, EstadoSolicitud.abierta);
    });

    testWidgets('finalizada: muestra el precio final y deja calificar', (
      tester,
    ) async {
      final a = await abrir(tester, '4103');
      // 64 ha × Bs 125/ha, congelado por el servidor.
      expect(find.text('Bs 8.000'), findsWidgets);
      expect(find.textContaining('Le pagas al piloto'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calificar')));
      await asentar(tester);
      await tester.tap(find.bySemanticsLabel('4 estrellas'));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('enviar-calificacion')));
      await asentar(tester, veces: 8);
      expect(a.porId('4103')!.puntajeDelCliente, 4);
      expect(a.porId('4103')!.estado, EstadoSolicitud.calificada);
      expect(find.text('Calificada'), findsWidgets);
      expect(find.byKey(const ValueKey('calificar')), findsNothing);
    });

    testWidgets('adjudicada y en ejecución: la acción es el seguimiento', (
      tester,
    ) async {
      await abrir(tester, '4102');
      expect(find.text('Ver seguimiento y chat'), findsOneWidget);
      expect(find.text('Marcelo Roca Vaca'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ver-seguimiento')));
      await asentar(tester, veces: 10);
      expect(find.byType(SeguimientoPantalla), findsOneWidget);
    });

    testWidgets('calificada: muestra estrellas y no ofrece acción', (
      tester,
    ) async {
      await abrir(tester, '4104');
      await bajarHasta(tester, find.text('Tu calificación'));
      expect(find.text('Tu calificación'), findsOneWidget);
      expect(find.byKey(const ValueKey('calificar')), findsNothing);
    });

    testWidgets('sin conexión al abrir ofrece reintentar', (tester) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await montar(
        tester,
        pantalla: const SolicitudDetallePantalla(solicitudId: '4101'),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      almacen.sinRed = false;
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(find.text('Tu precio propuesto'), findsOneWidget);
    });

    testWidgets('sin conexión al cambiar el precio no pierde el cambio', (
      tester,
    ) async {
      final a = await abrir(tester, '4101');
      await tester.tap(find.byKey(const ValueKey('cambiar-precio')));
      await asentar(tester);
      await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '99');
      await asentar(tester);
      a.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('hoja-precio-enviar')));
      await asentar(tester, veces: 8);
      expect(find.byKey(const ValueKey('aviso-accion')), findsOneWidget);
      expect(a.porId('4101')!.precioHaPropuesto, Decimal.fromInt(110));
    });
  });

  group('ofertas', () {
    testWidgets('compara y marca la de menor precio', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      expect(find.text('Bs 104/ha'), findsOneWidget);
      expect(find.text('Bs 110/ha'), findsOneWidget);
      expect(find.text('Bs 121/ha'), findsOneWidget);
      expect(find.text('Mejor precio'), findsOneWidget);
      expect(find.text('Acepta tu precio'), findsOneWidget);
      expect(find.textContaining('menos que tu precio'), findsOneWidget);
      expect(find.textContaining('más que tu precio'), findsOneWidget);
      // La de menor precio va primera.
      final primera = tester.getTopLeft(
        find.byKey(const ValueKey('oferta-of-4101-b')),
      );
      final segunda = tester.getTopLeft(
        find.byKey(const ValueKey('oferta-of-4101-a')),
      );
      expect(primera.dy, lessThan(segunda.dy));
    });

    testWidgets('cambiar el orden reordena las ofertas', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      await tester.tap(find.text('Mejor calificación'));
      await asentar(tester);
      final mejor = tester.getTopLeft(
        find.byKey(const ValueKey('oferta-of-4101-c')),
      );
      final otra = tester.getTopLeft(
        find.byKey(const ValueKey('oferta-of-4101-b')),
      );
      expect(mejor.dy, lessThan(otra.dy));
    });

    testWidgets('elegir pide confirmación y adjudica la solicitud', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
      await asentar(tester);
      expect(
        find.textContaining('Las demás ofertas se cierran'),
        findsOneWidget,
      );
      // Volver cancela: nada cambia.
      await tester.tap(find.text('Volver'));
      await asentar(tester);
      expect(almacen.porId('4101')!.estado, EstadoSolicitud.conOfertas);

      await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-aceptar')));
      await asentar(tester, veces: 10);
      final s = almacen.porId('4101')!;
      expect(s.estado, EstadoSolicitud.adjudicada);
      expect(s.precioHaAcordado, Decimal.fromInt(104));
      expect(find.byType(SeguimientoPantalla), findsOneWidget);
    });

    testWidgets(
      'contraofertar: valida el precio y deja a la oferta esperando',
      (tester) async {
        final almacen = almacenDePrueba();
        await montar(
          tester,
          pantalla: ofertas('4101'),
          dependencias: dependenciasDePrueba(almacen),
          variante: _alta,
        );
        await asentar(tester);
        await tester.tap(find.byKey(const ValueKey('contraofertar-of-4101-c')));
        await asentar(tester);
        await tester.enterText(find.byKey(const ValueKey('hoja-precio')), '0');
        await asentar(tester);
        expect(find.text('El precio tiene que ser mayor a 0.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('hoja-precio')),
          '112,5',
        );
        await asentar(tester);
        await tester.enterText(
          find.byKey(const ValueKey('hoja-nota')),
          'Es mi tope',
        );
        await tester.tap(find.byKey(const ValueKey('hoja-precio-enviar')));
        await asentar(tester, veces: 10);

        final nueva = almacen
            .ofertasDe('4101')
            .firstWhere((o) => o.autor == AutorOferta.cliente);
        expect(nueva.precioHa, Decimal.parse('112.5'));
        expect(nueva.nota, 'Es mi tope');
        expect(find.byKey(const ValueKey('aviso-respuesta')), findsOneWidget);
        expect(find.textContaining('Esperando la respuesta'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('aceptar-${'of-4101-c'}')),
          findsNothing,
        );
      },
    );

    testWidgets('rechazar quita la oferta de las vigentes', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('rechazar-of-4101-c')));
      await asentar(tester, veces: 8);
      expect(find.byKey(const ValueKey('oferta-of-4101-c')), findsNothing);
      expect(find.text('Ofertas cerradas'), findsOneWidget);
      expect(find.text('Rechazada'), findsOneWidget);
    });

    testWidgets('la última ronda no permite contraofertar', (tester) async {
      final almacen = almacenDePrueba();
      var o = almacen.ofertaPorId('of-4101-b')!;
      o = almacen.contraofertar(o, AutorOferta.cliente, Decimal.parse('100'));
      o = almacen.contraofertar(o, AutorOferta.proveedor, Decimal.parse('103'));
      o = almacen.contraofertar(o, AutorOferta.cliente, Decimal.parse('101'));
      final ultima = almacen.contraofertar(
        o,
        AutorOferta.proveedor,
        Decimal.parse('102'),
      );
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      expect(ultima.esDefinitiva, isTrue);
      expect(find.byKey(ValueKey('contraofertar-${ultima.id}')), findsNothing);
      expect(find.byKey(ValueKey('aceptar-${ultima.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('rechazar-${ultima.id}')), findsOneWidget);
      expect(find.textContaining('Última ronda'), findsOneWidget);
    });

    testWidgets('una oferta retirada mientras decidía se explica', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      almacen.rechazarOferta(almacen.ofertaPorId('of-4101-b')!);
      await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-aceptar')));
      await asentar(tester, veces: 8);
      expect(find.textContaining('ya no está vigente'), findsOneWidget);
      expect(find.byKey(const ValueKey('oferta-of-4101-b')), findsNothing);
      expect(almacen.porId('4101')!.estado, EstadoSolicitud.conOfertas);
    });

    testWidgets('sin conexión al responder avisa y conserva las ofertas', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('rechazar-of-4101-c')));
      await asentar(tester, veces: 8);
      expect(find.textContaining('Sin conexión'), findsWidgets);
      expect(find.byKey(const ValueKey('oferta-of-4101-c')), findsOneWidget);
    });

    testWidgets('los botones miden al menos 48 dp y tienen etiqueta', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ofertas('4101'),
        dependencias: dependenciasDePrueba(almacen),
        variante: _alta,
      );
      await asentar(tester);
      for (final k in [
        'aceptar-of-4101-b',
        'contraofertar-of-4101-b',
        'rechazar-of-4101-b',
      ]) {
        final alto = tester.getSize(find.byKey(ValueKey(k))).height;
        expect(
          alto,
          greaterThanOrEqualTo(ObjetivoTactilCampo.minimo),
          reason: k,
        );
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantica.dispose();
    });
  });

  group('seguimiento', () {
    Future<void> abrir(
      WidgetTester tester,
      AlmacenDemoCliente almacen,
      String id,
    ) async {
      await montar(
        tester,
        pantalla: SeguimientoPantalla(
          solicitudId: id,
          reloj: () => ahoraDePrueba,
          intervalo: null,
        ),
        dependencias: dependenciasDePrueba(almacen),
      );
      await precargarFotos(tester);
      await asentar(tester);
    }

    testWidgets('en ejecución muestra el avance, la ubicación y las fotos', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await abrir(tester, almacen, '4102');
      expect(find.text('61 %'), findsOneWidget);
      expect(find.textContaining('52 ha de 85,5 ha'), findsWidgets);
      expect(
        find.textContaining('Última ubicación hace 1 min'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('foto-f1')), findsOneWidget);
      expect(find.byKey(const ValueKey('foto-f2')), findsOneWidget);
      // Solo un punto: sin ruta, estela ni tiempo estimado.
      expect(find.textContaining('tiempo estimado'), findsNothing);
      expect(find.textContaining('ETA'), findsNothing);
    });

    testWidgets('una foto se abre a pantalla completa y se cierra', (
      tester,
    ) async {
      await abrir(tester, almacenDePrueba(), '4102');
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('foto-f1')),
        find.byType(ListView).first,
        const Offset(0, -150),
      );
      await tester.tap(find.byKey(const ValueKey('foto-f1')));
      await asentar(tester);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await asentar(tester);
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('adjudicada: todavía no empezó y no hay ubicación', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      almacen.adjudicar(almacen.ofertaPorId('of-4101-a')!);
      await abrir(tester, almacen, '4101');
      expect(find.textContaining('todavía no empezó'), findsOneWidget);
      expect(
        find.textContaining('comparte su ubicación cuando empieza'),
        findsOneWidget,
      );
      expect(find.textContaining('Todavía no hay fotos'), findsOneWidget);
    });

    testWidgets('terminada: muestra el precio final y quita la ubicación', (
      tester,
    ) async {
      await abrir(tester, almacenDePrueba(), '4103');
      expect(
        find.byKey(const ValueKey('seguimiento-precio-final')),
        findsOneWidget,
      );
      expect(find.text('Dónde está el piloto'), findsNothing);
    });

    testWidgets('el chat se abre desde el seguimiento', (tester) async {
      await abrir(tester, almacenDePrueba(), '4102');
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('abrir-chat')),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const ValueKey('abrir-chat')));
      await asentar(tester, veces: 10);
      expect(find.byType(ChatPantalla), findsOneWidget);
    });

    testWidgets('sin conexión al abrir ofrece reintentar', (tester) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await abrir(tester, almacen, '4102');
      expect(find.text('Sin conexión'), findsOneWidget);
      almacen.sinRed = false;
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(find.text('61 %'), findsOneWidget);
    });
  });

  group('chat', () {
    Future<AlmacenDemoCliente> abrir(WidgetTester tester, String id) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ChatPantalla(solicitudId: id, intervalo: null),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      return almacen;
    }

    testWidgets('muestra la conversación y envía un mensaje', (tester) async {
      final almacen = await abrir(tester, '4102');
      expect(
        find.textContaining('Empezamos por el lado oeste'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-campo')),
        'Perfecto, nos vemos mañana.',
      );
      await tester.tap(find.byKey(const ValueKey('chat-enviar')));
      await asentar(tester, veces: 8);
      expect(find.text('Perfecto, nos vemos mañana.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-campo')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        almacen.mensajesDe('4102').last.texto,
        'Perfecto, nos vemos mañana.',
      );
    });

    testWidgets('sin conexión el texto queda en el campo para reintentar', (
      tester,
    ) async {
      final almacen = await abrir(tester, '4102');
      await tester.enterText(
        find.byKey(const ValueKey('chat-campo')),
        'Llego a las 7.',
      );
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('chat-enviar')));
      await asentar(tester, veces: 8);
      expect(find.byKey(const ValueKey('chat-fallo')), findsOneWidget);
      expect(find.text('Llego a las 7.'), findsOneWidget);
      almacen.sinRed = false;
      await tester.tap(find.byKey(const ValueKey('chat-enviar')));
      await asentar(tester, veces: 8);
      expect(find.byKey(const ValueKey('chat-fallo')), findsNothing);
      expect(
        almacen.mensajesDe('4102').where((m) => m.texto == 'Llego a las 7.'),
        hasLength(1),
      );
    });

    testWidgets('cerrado el plazo se lee pero no se escribe', (tester) async {
      await abrir(tester, '4104');
      expect(find.byKey(const ValueKey('chat-solo-lectura')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-campo')), findsNothing);
    });

    testWidgets('chat vacío orienta a escribir', (tester) async {
      final almacen = almacenDePrueba();
      almacen.adjudicar(almacen.ofertaPorId('of-4101-a')!);
      await montar(
        tester,
        pantalla: ChatPantalla(solicitudId: '4101', intervalo: null),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.text('Todavía no hay mensajes'), findsOneWidget);
    });
  });

  group('calificar', () {
    Future<AlmacenDemoCliente> abrirHoja(WidgetTester tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('4103')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
      return almacen;
    }

    testWidgets('las etiquetas y el comentario viajan con la calificación', (
      tester,
    ) async {
      final almacen = await abrirHoja(tester);
      await tester.tap(find.bySemanticsLabel('2 estrellas'));
      await asentar(tester);
      expect(find.text('¿Qué se puede mejorar?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('etiqueta-comunicacion')));
      await tester.enterText(
        find.byKey(const ValueKey('comentario-calificacion')),
        'Avisaron tarde el cambio de hora.',
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('enviar-calificacion')));
      await asentar(tester);
      final c = almacen.calificaciones['4103']!;
      expect(c.puntaje, 2);
      expect(c.etiquetas, {EtiquetaCalificacion.comunicacion});
      expect(c.comentario, 'Avisaron tarde el cambio de hora.');
    });

    testWidgets('sin conexión la hoja conserva lo elegido y deja reintentar', (
      tester,
    ) async {
      final almacen = await abrirHoja(tester);
      await tester.tap(find.bySemanticsLabel('5 estrellas'));
      await asentar(tester);
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('enviar-calificacion')));
      await asentar(tester);
      expect(
        find.textContaining('Tu calificación no se envió'),
        findsOneWidget,
      );
      expect(find.text('Excelente'), findsOneWidget);
      almacen.sinRed = false;
      // La hoja se desplaza: el botón puede quedar bajo el pliegue.
      await tester.ensureVisible(find.text('Reintentar'));
      await asentar(tester);
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(almacen.porId('4103')!.puntajeDelCliente, 5);
    });

    testWidgets('cada estrella y cada etiqueta miden al menos 48 dp', (
      tester,
    ) async {
      await abrirHoja(tester);
      await tester.tap(find.bySemanticsLabel('3 estrellas'));
      await asentar(tester);
      for (final f in [
        find.bySemanticsLabel('1 estrella'),
        find.byKey(const ValueKey('etiqueta-puntualidad')),
        find.byKey(const ValueKey('enviar-calificacion')),
      ]) {
        expect(
          tester.getSize(f).height,
          greaterThanOrEqualTo(ObjetivoTactilCampo.minimo),
          reason: '$f',
        );
      }
    });
  });

  group('reportar problema', () {
    testWidgets(
      'exige motivo y detalle, envía y deja la solicitud en disputa',
      (tester) async {
        final almacen = almacenDePrueba();
        await montar(
          tester,
          pantalla: const SolicitudDetallePantalla(solicitudId: '4103'),
          dependencias: dependenciasDePrueba(almacen),
        );
        await asentar(tester);
        await bajarHasta(tester, find.text('Reportar un problema'));
        await tester.tap(find.text('Reportar un problema'));
        await asentar(tester);
        expect(find.byType(ReportarProblemaPantalla), findsOneWidget);

        final enviar = find.descendant(
          of: find.byKey(const ValueKey('enviar-reporte')),
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(enviar).onPressed, isNull);
        await tester.tap(
          find.byKey(const ValueKey('motivo-coberturaIncompleta')),
        );
        await asentar(tester, veces: 2);
        expect(tester.widget<FilledButton>(enviar).onPressed, isNull);
        await bajarHasta(
          tester,
          find.byKey(const ValueKey('detalle-problema')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('detalle-problema')),
          'Quedó sin aplicar la franja del borde norte.',
        );
        await asentar(tester, veces: 2);
        expect(tester.widget<FilledButton>(enviar).onPressed, isNotNull);
        await tester.tap(enviar);
        await asentar(tester);

        expect(find.text('Recibimos tu reporte'), findsOneWidget);
        expect(find.text('Caso C-2041 · Cobertura incompleta'), findsOneWidget);
        expect(almacen.problemas['4103']!.detalle, contains('borde norte'));
        expect(almacen.porId('4103')!.estado, EstadoSolicitud.disputada);

        await tester.tap(find.text('Volver al servicio'));
        await asentar(tester);
        expect(find.byType(SolicitudDetallePantalla), findsOneWidget);
        expect(find.byType(ReportarProblemaPantalla), findsNothing);
        await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
        await asentar(tester);
        expect(
          find.textContaining('Reportaste un problema: Cobertura incompleta'),
          findsOneWidget,
        );
        // Con un reclamo abierto ya no se califica ni se reporta de nuevo.
        expect(find.byKey(const ValueKey('calificar')), findsNothing);
        expect(find.text('Reportar un problema'), findsNothing);
      },
    );

    testWidgets('sin conexión conserva el formulario', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ReportarProblemaPantalla(servicio: almacen.porId('4103')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('motivo-equipoAusente')));
      await bajarHasta(tester, find.byKey(const ValueKey('detalle-problema')));
      await tester.enterText(
        find.byKey(const ValueKey('detalle-problema')),
        'El equipo se fue antes de terminar.',
      );
      await asentar(tester, veces: 2);
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('enviar-reporte')));
      await asentar(tester);
      expect(find.textContaining('El reporte no se envió'), findsOneWidget);
      expect(find.text('El equipo se fue antes de terminar.'), findsOneWidget);
      expect(almacen.problemas, isEmpty);
    });
  });
}
