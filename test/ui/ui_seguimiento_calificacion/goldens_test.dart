// Goldens de las pantallas del cliente para seguir, revisar, calificar y
// reportar un servicio. Cada pantalla principal se captura en claro y
// oscuro, a 360x640 y 412x915, con el texto al 100 % y al 200 %; los
// estados secundarios (carga, vacío, error, sin señal, éxito) se capturan
// una vez. Un desborde de layout hace fallar la prueba antes de comparar.
//
// Se regeneran con
// `flutter test --update-goldens test/ui/ui_seguimiento_calificacion`.
// Solo corren en macOS (el render de texto difiere en Linux).

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/conformidad/presentation/acta_pantalla.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/problema/presentation/reportar_problema_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento_repositorio.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_pantalla.dart';
import 'package:agrocom_field/cliente/servicios/domain/servicios_cliente_repositorio.dart';
import 'package:agrocom_field/cliente/servicios/presentation/historial_pantalla.dart';
import 'package:agrocom_field/cliente/servicios/presentation/servicio_detalle_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/recorrido_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

import 'ayudas.dart';

/// Seguimiento detenido en un fotograma, opcionalmente seguido de un corte.
class _SeguimientoFijo implements SeguimientoRepositorio {
  _SeguimientoFijo(this.almacen, {this.hectareas, this.falla});

  final AlmacenDemoCliente almacen;

  /// Hectáreas cubiertas del único fotograma; sin ellas no emite ninguno.
  final String? hectareas;
  final Object? falla;

  @override
  Stream<SeguimientoVivo> observar(String servicioId) {
    final servicio = almacen.porId(servicioId)!;
    final control = StreamController<SeguimientoVivo>();
    if (hectareas != null) {
      control.add(
        RecorridoDemo.paraLote(
          servicio.lote,
        ).fotograma(servicio, Decimal.parse(hectareas!)),
      );
    }
    if (falla != null) control.addError(falla!);
    return control.stream;
  }
}

/// Servicios que nunca llegan (carga) o que llegan vacíos.
class _ServiciosFijos implements ServiciosClienteRepositorio {
  _ServiciosFijos(this.lista);

  final List<Servicio>? lista;

  @override
  Stream<List<Servicio>> observar() =>
      lista == null ? const Stream.empty() : Stream.value(lista!);

  @override
  Future<Servicio?> porId(String id) async => null;
}

Widget _historial() => Scaffold(
  body: SafeArea(child: HistorialPantalla(reloj: () => ahoraDePrueba)),
);

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

  group('historial', () {
    matriz('historial', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await asentar(tester);
    });

    unica('historial_cargando', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(
          almacen,
          servicios: _ServiciosFijos(null),
        ),
        variante: v,
        reducirMovimiento: true,
      );
      await tester.pump();
    });

    unica('historial_vacio', (tester, v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(
          almacen,
          servicios: _ServiciosFijos(const []),
        ),
        variante: v,
      );
      await asentar(tester);
    });

    unica('historial_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await montar(
        tester,
        pantalla: _historial(),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await asentar(tester);
    });
  });

  group('detalle', () {
    Future<void> detalle(WidgetTester tester, Variante v, String id) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ServicioDetallePantalla(servicioId: id),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await asentar(tester);
    }

    matriz('detalle_en_ejecucion', (t, v) => detalle(t, v, 'srv-1042'));
    matriz('detalle_por_confirmar', (t, v) => detalle(t, v, 'srv-1036'));
    unica('detalle_buscando_proveedor', (t, v) => detalle(t, v, 'srv-1047'));
    unica('detalle_cancelado', (t, v) => detalle(t, v, 'srv-1020'));

    unica('detalle_calificado', (tester, v) async {
      await detalle(tester, v, 'srv-1039');
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await asentar(tester);
    });

    unica('detalle_sin_conexion', (tester, v) async {
      final almacen = almacenDePrueba()..sinRed = true;
      await montar(
        tester,
        pantalla: const ServicioDetallePantalla(servicioId: 'srv-1036'),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await asentar(tester);
    });
  });

  group('seguimiento', () {
    Future<void> seguimiento(
      WidgetTester tester,
      Variante v, {
      String? hectareas,
      Object? falla,
    }) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: SeguimientoPantalla(servicio: almacen.porId('srv-1042')!),
        dependencias: dependenciasDePrueba(
          almacen,
          seguimiento: _SeguimientoFijo(
            almacen,
            hectareas: hectareas,
            falla: falla,
          ),
        ),
        variante: v,
        reducirMovimiento: hectareas == null,
      );
      await asentar(tester);
    }

    matriz('seguimiento', (t, v) => seguimiento(t, v, hectareas: '46.8'));
    unica('seguimiento_cargando', seguimiento);
    unica(
      'seguimiento_terminado',
      (t, v) => seguimiento(t, v, hectareas: '120'),
    );
    unica(
      'seguimiento_sin_senal',
      (t, v) => seguimiento(t, v, hectareas: '63', falla: const SinConexion()),
    );
    unica(
      'seguimiento_sin_conexion',
      (t, v) => seguimiento(t, v, falla: const SinConexion()),
    );

    unica('seguimiento_hoja_expandida', (tester, v) async {
      await seguimiento(tester, v, hectareas: '46.8');
      await tester.drag(
        find.byKey(const ValueKey('hectareas-cubiertas')),
        const Offset(0, -400),
      );
      await asentar(tester);
    });
  });

  group('acta', () {
    Future<void> acta(WidgetTester tester, Variante v, String id) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: ActaPantalla(servicio: almacen.porId(id)!),
        dependencias: dependenciasDePrueba(almacen),
        variante: v,
      );
      await precargarFotos(tester);
      await asentar(tester);
    }

    matriz('acta_pendiente', (t, v) => acta(t, v, 'srv-1036'));
    unica('acta_firmada_antes', (t, v) => acta(t, v, 'srv-1039'));
    unica('acta_en_ejecucion', (t, v) => acta(t, v, 'srv-1042'));

    unica('acta_confirmar', (tester, v) async {
      await acta(tester, v, 'srv-1036');
      await tester.tap(find.byKey(const ValueKey('dar-conformidad')));
      await asentar(tester);
    });

    unica('acta_recien_firmada', (tester, v) async {
      await acta(tester, v, 'srv-1036');
      await tester.tap(find.byKey(const ValueKey('dar-conformidad')));
      await asentar(tester);
      await tester.tap(find.byKey(const ValueKey('confirmar-conformidad')));
      await asentar(tester);
    });

    unica('acta_evidencias', (tester, v) async {
      await acta(tester, v, 'srv-1036');
      await tester.drag(find.byType(ListView), const Offset(0, -420));
      await asentar(tester);
    });
  });

  group('calificar', () {
    Future<void> hoja(WidgetTester tester, Variante v) async {
      final almacen = almacenDePrueba();
      await montar(
        tester,
        pantalla: AbreHojaCalificar(almacen.porId('srv-1036')!),
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
        pantalla: ReportarProblemaPantalla(
          servicio: almacen.porId('srv-1036')!,
        ),
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
