// Comportamiento de las pantallas del cliente para seguir, revisar,
// calificar y reportar un servicio, contra los repositorios demo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/conformidad/presentation/acta_pantalla.dart';
import 'package:agrocom_field/cliente/conformidad/presentation/galeria_evidencias.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_pantalla.dart';
import 'package:agrocom_field/cliente/servicios/presentation/historial_pantalla.dart';
import 'package:agrocom_field/cliente/servicios/presentation/servicio_detalle_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tokens_campo.dart';

import '../../nucleo/marketplace/ayudas_prueba.dart';
import 'ayudas.dart';

void main() {
  Widget historial() => Scaffold(
    body: SafeArea(child: HistorialPantalla(reloj: () => ahoraDePrueba)),
  );

  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) async {
    await tester.dragUntilVisible(
      objetivo,
      find.byType(ListView).first,
      const Offset(0, -250),
    );
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
      expect(find.byType(EsqueletoCampo), findsWidgets);
      await asentar(tester);
      expect(find.byType(EsqueletoCampo), findsNothing);
      expect(find.text('359,5 ha'), findsOneWidget);
      expect(find.text('en 3 servicios'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Hectáreas fumigadas por mes: .*Nov 295,5 ha'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Activos'));
      await asentar(tester);
      expect(find.byKey(const ValueKey('servicio-srv-1042')), findsOneWidget);
      expect(find.byKey(const ValueKey('servicio-srv-1039')), findsNothing);

      await tester.tap(find.text('Listos'));
      await asentar(tester);
      expect(find.byKey(const ValueKey('servicio-srv-1042')), findsNothing);
      expect(find.byKey(const ValueKey('servicio-srv-1039')), findsOneWidget);
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
      expect(find.text('Sin conexión'), findsNothing);
      expect(find.text('Mis servicios'), findsOneWidget);
      expect(find.byKey(const ValueKey('servicio-srv-1042')), findsOneWidget);
    });

    testWidgets('abre el detalle del servicio tocado', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: historial(),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('servicio-srv-1042')));
      await asentar(tester);
      expect(find.byType(ServicioDetallePantalla), findsOneWidget);
      expect(find.text('Seguir en vivo'), findsOneWidget);
    });
  });

  group('detalle', () {
    Future<void> abrir(WidgetTester tester, String id) async {
      await montar(
        tester,
        pantalla: ServicioDetallePantalla(servicioId: id),
        dependencias: dependenciasDePrueba(almacenDePrueba()),
      );
      await asentar(tester);
    }

    testWidgets('en ejecución: la única acción es seguir en vivo', (
      tester,
    ) async {
      await abrir(tester, 'srv-1042');
      expect(find.text('Seguir en vivo'), findsOneWidget);
      expect(find.text('Calificar al proveedor'), findsNothing);
      expect(find.text('Revisar y dar conformidad'), findsNothing);
      expect(
        find.text('46,8 ha de 120 ha · faltan 1 h 14 min'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Fumigación del lote, en curso')),
        findsOneWidget,
      );
      await tester.tap(find.text('Seguir en vivo'));
      await asentar(tester);
      expect(find.byType(SeguimientoPantalla), findsOneWidget);
    });

    testWidgets(
      'buscando proveedor: explica la asignación y no ofrece acción',
      (tester) async {
        await abrir(tester, 'srv-1047');
        expect(find.byType(FilledButton), findsNothing);
        expect(
          find.bySemanticsLabel(
            RegExp('Buscando proveedor, en curso.*flota de Agrocom'),
          ),
          findsOneWidget,
        );
        expect(find.text('Reportar un problema'), findsNothing);
      },
    );

    testWidgets('cancelado: lo dice y no ofrece acción ni reporte', (
      tester,
    ) async {
      await abrir(tester, 'srv-1020');
      expect(find.textContaining('Este servicio se canceló'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Reportar un problema'), findsNothing);
    });

    testWidgets('ya calificado: muestra estrellas y etiquetas, sin acción', (
      tester,
    ) async {
      await abrir(tester, 'srv-1039');
      expect(find.byType(FilledButton), findsNothing);
      await bajarHasta(tester, find.text('Tu calificación'));
      expect(find.text('Puntualidad · Cobertura pareja'), findsOneWidget);
      expect(find.bySemanticsLabel('Calificación: 5 de 5'), findsWidgets);
      // Firmada el acta, el plazo para reportar ya cerró.
      expect(find.text('Reportar un problema'), findsNothing);
    });

    testWidgets('sin conexión al abrir ofrece reintentar', (tester) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await montar(
        tester,
        pantalla: const ServicioDetallePantalla(servicioId: 'srv-1036'),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      almacen.sinRed = false;
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(find.text('Trigo Okinawa'), findsOneWidget);
    });
  });

  group('conformidad y calificación', () {
    testWidgets('revisar, dar conformidad y calificar en una pasada', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: const ServicioDetallePantalla(servicioId: 'srv-1036'),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(
        find.bySemanticsLabel(RegExp('Tu conformidad, en curso')),
        findsOneWidget,
      );

      await tester.tap(find.text('Revisar y dar conformidad'));
      await asentar(tester);
      expect(find.byType(ActaPantalla), findsOneWidget);
      expect(find.text('210 ha confirmadas'), findsOneWidget);
      expect(find.text('Falta tu conformidad'), findsOneWidget);
      expect(find.textContaining('25 nov a las 02:00'), findsOneWidget);

      // La firma pide una confirmación: no se puede deshacer.
      await tester.tap(find.byKey(const ValueKey('dar-conformidad')));
      await asentar(tester);
      expect(almacen.actas, isEmpty);
      await tester.tap(find.byKey(const ValueKey('confirmar-conformidad')));
      await asentar(tester);
      expect(almacen.actas['srv-1036']!.estado, EstadoActa.firmada);
      expect(find.textContaining('Conformidad registrada'), findsOneWidget);
      expect(find.text('Conforme'), findsOneWidget);

      // Calificar son dos toques: estrella y enviar.
      await tester.tap(find.text('Calificar al proveedor'));
      await asentar(tester);
      expect(find.text('Tocá una estrella'), findsOneWidget);
      final enviar = find.byKey(const ValueKey('enviar-calificacion'));
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(of: enviar, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.bySemanticsLabel('4 estrellas'));
      await asentar(tester);
      expect(find.text('Muy buena'), findsOneWidget);
      await tester.tap(enviar);
      await asentar(tester);

      expect(almacen.porId('srv-1036')!.puntajeDelCliente, 4);
      expect(find.text('Gracias por calificar el servicio'), findsOneWidget);
      // Vuelve al detalle, ya sin acción pendiente.
      expect(find.byType(ActaPantalla), findsNothing);
      expect(find.byType(ServicioDetallePantalla), findsOneWidget);
      expect(find.text('Revisar y dar conformidad'), findsNothing);
      expect(find.text('Calificar al proveedor'), findsNothing);
    });

    testWidgets('las etiquetas y el comentario viajan con la calificación', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('srv-1036')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
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
      final c = almacen.calificaciones['srv-1036']!;
      expect(c.puntaje, 2);
      expect(c.etiquetas, {EtiquetaCalificacion.comunicacion});
      expect(c.comentario, 'Avisaron tarde el cambio de hora.');
    });

    testWidgets('sin conexión la hoja conserva lo elegido y deja reintentar', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('srv-1036')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
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
      await tester.tap(find.text('Reintentar'));
      await asentar(tester);
      expect(almacen.porId('srv-1036')!.puntajeDelCliente, 5);
    });

    testWidgets('cada estrella y cada etiqueta miden al menos 48 dp', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('srv-1036')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      await tester.tap(find.text('Abrir'));
      await asentar(tester);
      await tester.tap(find.bySemanticsLabel('3 estrellas'));
      await asentar(tester);
      for (final f in [
        find.bySemanticsLabel('1 estrella'),
        find.byKey(const ValueKey('etiqueta-puntualidad')),
        find.byKey(const ValueKey('enviar-calificacion')),
      ]) {
        final tamano = tester.getSize(f);
        expect(
          tamano.height,
          greaterThanOrEqualTo(ObjetivoTactilCampo.minimo),
          reason: '$f',
        );
      }
    });

    testWidgets('una evidencia se abre a pantalla completa con su leyenda', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ActaPantalla(servicio: almacen.porId('srv-1039')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      // Ya firmada: no pide conformidad.
      expect(find.byKey(const ValueKey('dar-conformidad')), findsNothing);
      expect(find.text('Conforme'), findsOneWidget);
      await bajarHasta(
        tester,
        find.byKey(const ValueKey('evidencia-srv-1039-ev-2')),
      );
      await tester.tap(find.byKey(const ValueKey('evidencia-srv-1039-ev-2')));
      await asentar(tester);
      expect(find.byType(VisorEvidencias), findsOneWidget);
      expect(find.text('2 de 5'), findsOneWidget);
      expect(find.textContaining('Caldo preparado'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await asentar(tester);
      expect(find.byType(VisorEvidencias), findsNothing);
    });

    testWidgets('si la firma falla sin red, el acta sigue en pantalla', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ActaPantalla(servicio: almacen.porId('srv-1036')!),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      almacen.sinRed = true;
      await tester.tap(find.byKey(const ValueKey('dar-conformidad')));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-conformidad')));
      await asentar(tester);
      expect(find.textContaining('Tu conformidad no se envió'), findsOneWidget);
      expect(find.text('210 ha confirmadas'), findsOneWidget);
      expect(almacen.actas, isEmpty);
    });
  });

  group('reportar problema', () {
    testWidgets('exige motivo y detalle, envía y deja el acta observada', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: const ServicioDetallePantalla(servicioId: 'srv-1036'),
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
      await bajarHasta(tester, find.byKey(const ValueKey('detalle-problema')));
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
      expect(almacen.problemas['srv-1036']!.detalle, contains('borde norte'));

      await tester.tap(find.text('Volver al servicio'));
      await asentar(tester);
      expect(find.byType(ServicioDetallePantalla), findsOneWidget);
      expect(find.byType(ReportarProblemaPantalla), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await asentar(tester);
      expect(
        find.textContaining('Reportaste un problema: Cobertura incompleta'),
        findsOneWidget,
      );
      // Con un problema abierto ya no se firma ni se califica desde acá.
      expect(find.text('Revisar y dar conformidad'), findsNothing);
      expect(find.text('Calificar al proveedor'), findsNothing);
      expect(find.text('Reportar un problema'), findsNothing);
    });

    testWidgets('sin conexión conserva el formulario', (tester) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ReportarProblemaPantalla(
          servicio: almacen.porId('srv-1042')!,
        ),
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

  group('seguimiento en vivo', () {
    Future<void> abrir(
      WidgetTester tester, {
      bool reducirMovimiento = false,
    }) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: SeguimientoPantalla(servicio: almacen.porId('srv-1042')!),
        dependencias: dependenciasDePrueba(
          almacen,
          seguimiento: SeguimientoDemo(
            almacen,
            intervalo: const Duration(seconds: 2),
            pasoHectareas: '36.6',
          ),
        ),
        reducirMovimiento: reducirMovimiento,
      );
      await tester.pump();
      await tester.pump();
    }

    final dron = find.descendant(
      of: find.byType(MapaLote),
      matching: find.byIcon(Icons.flight_rounded),
    );

    String hectareas(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('hectareas-cubiertas')))
        .data!;

    testWidgets('avanza con cada fotograma hasta ofrecer el acta', (
      tester,
    ) async {
      await abrir(tester);
      expect(hectareas(tester), '46,8 ha');
      expect(find.text('Faltan 1 h 14 min'), findsOneWidget);
      expect(dron, findsOneWidget);
      expect(find.text('Ver evidencias y acta'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(hectareas(tester), '83,4 ha');
      expect(find.text('Faltan 37 min'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(hectareas(tester), '120 ha');
      expect(find.text('Completado'), findsOneWidget);
      expect(find.text('Ver evidencias y acta'), findsOneWidget);
      // Con la hoja expandida, la línea de tiempo dice qué sigue.
      await tester.drag(
        find.byKey(const ValueKey('hectareas-cubiertas')),
        const Offset(0, -500),
      );
      await asentar(tester);
      expect(
        find.bySemanticsLabel(RegExp('Tu conformidad, en curso')),
        findsOneWidget,
      );
    });

    testWidgets('el dron se desliza entre posiciones y no salta', (
      tester,
    ) async {
      await abrir(tester);
      final marcador = dron;
      final inicio = tester.getCenter(marcador);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      // Recién llegó el fotograma nuevo: el marcador todavía no se movió.
      expect(tester.getCenter(marcador), inicio);
      await tester.pump(const Duration(milliseconds: 600));
      final medio = tester.getCenter(marcador);
      await tester.pump(const Duration(milliseconds: 700));
      final fin = tester.getCenter(marcador);
      expect(medio, isNot(inicio));
      expect(medio, isNot(fin));
      expect((medio - inicio).distance, lessThan((fin - inicio).distance));
    });

    testWidgets('con «reducir movimiento» el dron salta a la posición nueva', (
      tester,
    ) async {
      await abrir(tester, reducirMovimiento: true);
      final marcador = dron;
      final inicio = tester.getCenter(marcador);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      final fin = tester.getCenter(marcador);
      expect(fin, isNot(inicio));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(tester.getCenter(marcador), fin);
    });

    testWidgets('las hectáreas mostradas salen del decimal exacto', (
      tester,
    ) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: SeguimientoPantalla(servicio: almacen.porId('srv-1042')!),
        dependencias: dependenciasDePrueba(
          almacen,
          seguimiento: SeguimientoDemo(
            almacen,
            intervalo: const Duration(seconds: 2),
            pasoHectareas: '0.1',
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
      }
      // 46,8 + 0,1 × 3 = 47,1 exacto (con `double` daría 47,099999…).
      expect(hectareas(tester), '47,1 ha');
    });
  });

  testWidgets('desde el inicio, «Calificar» abre la hoja', (tester) async {
    final almacen = almacenDePrueba();
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(dependencias: dependenciasDePrueba(almacen)),
    );
    // La splash cede el paso al inicio al terminar su animación.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await asentar(tester);
    await tester.ensureVisible(find.text('Calificar'));
    await asentar(tester, veces: 2);
    await tester.tap(find.text('Calificar'));
    await asentar(tester);
    expect(find.text('¿Cómo fue el servicio de Marcelo?'), findsOneWidget);
  });
}
