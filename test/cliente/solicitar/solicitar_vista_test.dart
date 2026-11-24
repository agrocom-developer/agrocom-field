import 'dart:async';

import 'package:agrocom_field/cliente/solicitar/presentation/mapa_solicitud.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_estado.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_pantalla.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_solicitar.dart';

const _telefono = Size(390, 844);
const _ipad = Size(1194, 834);

const _continuar = ValueKey('solicitar-continuar');

/// Trae [objetivo] a la vista dentro del paso y lo toca.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.scrollUntilVisible(
    objetivo,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

void main() {
  late RepositorioEspia repo;
  late SolicitarCubit cubit;
  Solicitud? solicitado;

  setUp(() {
    repo = RepositorioEspia();
    cubit = crearCubit(repo);
    solicitado = null;
  });
  tearDown(() => cubit.close());

  Widget vista({double escalaTexto = 1, bool sinAnimaciones = false}) =>
      envolver(
        repositorio: repo,
        escalaTexto: escalaTexto,
        sinAnimaciones: sinAnimaciones,
        child: BlocProvider.value(
          value: cubit,
          child: SolicitarVista(alSolicitado: (s) => solicitado = s),
        ),
      );

  bool botonHabilitado(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(_continuar)).onPressed != null;

  testWidgets('recorre los cuatro pasos y confirma con un solo botón', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    await tester.pumpWidget(vista());
    unawaited(cubit.cargar());
    await tester.pumpAndSettle();

    expect(find.text('Publicar solicitud'), findsOneWidget);
    expect(find.text('Paso 1 de 4 · Lote'), findsOneWidget);
    expect(find.byType(MapaSolicitud), findsOneWidget);
    expect(botonHabilitado(tester), isFalse);

    await tester.tap(find.text('Maíz La Curva'));
    await tester.pumpAndSettle();
    expect(find.text('85,5 ha'), findsOneWidget, reason: 'insignia del mapa');
    await tester.tap(find.byKey(_continuar));
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 4 · Aplicación'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('solicitar-hectareas')))
          .controller!
          .text,
      '85,5',
    );
    expect(botonHabilitado(tester), isFalse, reason: 'falta el producto');
    await tocar(tester, find.text('Insecticida piretroide'));
    await tester.tap(find.byKey(_continuar));
    await tester.pumpAndSettle();

    expect(find.text('Paso 3 de 4 · Cuándo'), findsOneWidget);
    expect(botonHabilitado(tester), isFalse, reason: 'falta la fecha');
    await tester.tap(find.byKey(const ValueKey('fecha-2')));
    await tester.pumpAndSettle();
    await tocar(tester, find.byKey(const ValueKey('solicitar-observaciones')));
    await tester.enterText(
      find.byKey(const ValueKey('solicitar-observaciones')),
      'Hay una línea eléctrica al sur',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_continuar));
    await tester.pumpAndSettle();

    expect(find.text('Paso 4 de 4 · Precio'), findsOneWidget);
    expect(find.text('Publicar solicitud'), findsWidgets);
    expect(botonHabilitado(tester), isFalse, reason: 'falta el precio');
    await tester.enterText(
      find.byKey(const ValueKey('solicitar-precio')),
      '120',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bs 10.260'), findsWidgets);
    expect(botonHabilitado(tester), isTrue);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.byKey(_continuar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(solicitado, isNotNull);
    expect(solicitado!.estado, EstadoSolicitud.abierta);
    expect(solicitado!.precioHaPropuesto.toString(), '120');
    expect(repo.clavesEnviadas, hasLength(1));
    expect(
      repo.enviadas.single.observaciones,
      'Hay una línea eléctrica al sur',
    );
  });

  testWidgets('doble toque en confirmar envía una sola solicitud', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    await completarHastaPrecio(cubit);
    cubit.cambiarPrecio('120');
    await tester.pumpWidget(vista());
    await tester.pumpAndSettle();
    final antes = repo.almacen.solicitudes.length;

    await tester.tap(find.byKey(_continuar));
    await tester.tap(find.byKey(_continuar), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(repo.clavesEnviadas, hasLength(1));
    expect(repo.almacen.solicitudes.length, antes + 1);
  });

  testWidgets('sin red: avisa, conserva el resumen y deja reintentar', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    await completarHastaPrecio(cubit);
    cubit.cambiarPrecio('120');
    repo.demo.sinConexion = true;
    await tester.pumpWidget(vista());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_continuar));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-sin-conexion')), findsOneWidget);
    expect(find.text('Reintentar publicación'), findsOneWidget);
    expect(find.text('Paso 4 de 4 · Precio'), findsOneWidget);
    expect(find.text('Insecticida piretroide'), findsOneWidget);
    expect(find.text('Bs 10.260'), findsWidgets);
    expect(solicitado, isNull);

    repo.demo.sinConexion = false;
    await tester.tap(find.byKey(_continuar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(solicitado, isNotNull);
    expect(repo.clavesEnviadas, ['clave-1', 'clave-1']);
  });

  testWidgets('dibujar: cada toque en el mapa marca una esquina', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    await tester.pumpWidget(vista());
    unawaited(cubit.cargar());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('modo-dibujo')));
    await tester.pumpAndSettle();
    expect(cubit.state.modoLote, ModoLote.dibujo);
    expect(find.textContaining('Toca el mapa'), findsOneWidget);

    final mapa = tester.getRect(find.byType(MapaSolicitud));
    for (final toque in [
      mapa.center + const Offset(-80, -60),
      mapa.center + const Offset(80, -60),
      mapa.center + const Offset(80, 60),
    ]) {
      await tester.tapAt(toque);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpAndSettle();

    expect(cubit.state.vertices, hasLength(3));
    expect(cubit.state.contornoCerrado, isTrue);
    expect(find.textContaining('Contorno listo'), findsOneWidget);
    expect(botonHabilitado(tester), isTrue);
    expect(
      find.descendant(
        of: find.byType(MapaSolicitud),
        matching: find.textContaining(' ha'),
      ),
      findsOneWidget,
      reason: 'la superficie se ve en grande sobre el mapa',
    );

    await tocar(tester, find.byKey(const ValueKey('dibujo-deshacer')));
    expect(cubit.state.vertices, hasLength(2));
    expect(botonHabilitado(tester), isFalse);

    await tocar(tester, find.byKey(const ValueKey('dibujo-borrar')));
    expect(cubit.state.vertices, isEmpty);
  });

  testWidgets('arrastrar una esquina la mueve a ella y no al mapa', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    await cubit.cargar();
    cubit.cambiarModoLote(ModoLote.dibujo);
    contornoDePrueba.forEach(cubit.agregarVertice);
    await tester.pumpWidget(vista());
    await tester.pumpAndSettle();

    final esquina = find.byKey(const ValueKey('vertice-0'));
    final otra = find.byKey(const ValueKey('vertice-2'));
    final posicionOtra = tester.getCenter(otra);
    final antes = cubit.state.vertices.first;
    final areaAntes = cubit.state.hectareas!;

    // La esquina 0 es la del suroeste: hacia la izquierda agranda el lote.
    await tester.drag(esquina, const Offset(-40, 0));
    await tester.pumpAndSettle();

    final despues = cubit.state.vertices.first;
    expect(despues.longitud, lessThan(antes.longitud));
    expect(despues.latitud, closeTo(antes.latitud, 0.0005));
    expect(cubit.state.vertices.sublist(1), contornoDePrueba.sublist(1));
    expect(cubit.state.hectareas, greaterThan(areaAntes));
    expect(tester.getCenter(otra), posicionOtra, reason: 'el mapa no se movió');
  });

  testWidgets('tocar un lote en el mapa lo elige', (tester) async {
    prepararPantalla(tester, _telefono);
    final unico = RepositorioEspia(
      lotes: [RepositorioEspia().almacen.datos.lotes[1]],
    );
    final c = crearCubit(unico);
    addTearDown(c.close);
    await c.cargar();
    await tester.pumpWidget(
      envolver(
        repositorio: unico,
        child: BlocProvider.value(
          value: c,
          child: SolicitarVista(alSolicitado: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(c.state.loteGuardado, isNull);

    await tester.tapAt(tester.getCenter(find.byType(MapaSolicitud)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(c.state.loteGuardado?.nombre, 'Maíz La Curva');
  });

  testWidgets('el paso anterior conserva lo escrito', (tester) async {
    prepararPantalla(tester, _telefono);
    await completarHastaPrecio(cubit);
    await tester.pumpWidget(vista());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('solicitar-atras')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 4 · Cuándo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('solicitar-atras')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 4 · Aplicación'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('solicitar-hectareas')))
          .controller!
          .text,
      '85,5',
    );

    await tester.enterText(
      find.byKey(const ValueKey('solicitar-hectareas')),
      '0',
    );
    await tester.pumpAndSettle();
    expect(find.text('La superficie tiene que ser mayor a 0.'), findsOneWidget);
    expect(botonHabilitado(tester), isFalse);
  });

  testWidgets('carga: esqueleto, y si falla, error con reintento', (
    tester,
  ) async {
    prepararPantalla(tester, _telefono);
    repo.fallaLaCarga = true;
    await tester.pumpWidget(vista(sinAnimaciones: true));
    expect(find.bySemanticsLabel('Cargando'), findsWidgets);

    await cubit.cargar();
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus lotes'), findsOneWidget);

    repo.fallaLaCarga = false;
    await tester.tap(find.byKey(const ValueKey('solicitar-reintentar-carga')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 4 · Lote'), findsOneWidget);
  });

  testWidgets('sin lotes guardados orienta a dibujar', (tester) async {
    prepararPantalla(tester, _telefono);
    final vacio = RepositorioEspia(lotes: const []);
    final c = crearCubit(vacio);
    addTearDown(c.close);
    await c.cargar();
    await tester.pumpWidget(
      envolver(
        repositorio: vacio,
        child: BlocProvider.value(
          value: c,
          child: SolicitarVista(alSolicitado: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Toca el mapa'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('modo-guardado')));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no tienes lotes guardados'), findsOneWidget);
  });

  testWidgets('iPad horizontal: mapa y formulario lado a lado en cada paso', (
    tester,
  ) async {
    prepararPantalla(tester, _ipad);
    await tester.pumpWidget(vista());
    unawaited(cubit.cargar());
    await tester.pumpAndSettle();

    Rect mapa() => tester.getRect(find.byType(MapaSolicitud));
    final titulo = tester.getRect(find.text('Publicar solicitud'));
    expect(mapa().height, greaterThan(700));
    expect(mapa().right, lessThanOrEqualTo(titulo.left));

    await tester.tap(find.text('Maíz La Curva'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_continuar));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 4 · Aplicación'), findsOneWidget);
    expect(find.byType(MapaSolicitud), findsOneWidget);
    expect(mapa().width, greaterThan(600));
  });

  testWidgets('texto al 200 % en un teléfono chico: ningún paso desborda', (
    tester,
  ) async {
    prepararPantalla(tester, const Size(360, 640));
    await tester.pumpWidget(vista(escalaTexto: 2));
    unawaited(cubit.cargar());
    await tester.pumpAndSettle();
    cubit
      ..elegirLote(cubit.state.lotes[1])
      ..elegirProducto('Fungicida triazol + estrobilurina');
    await tester.pumpAndSettle();
    for (final paso in PasoSolicitud.values.skip(1)) {
      if (paso == PasoSolicitud.precio) {
        cubit.elegirFecha(cubit.state.fechas.first);
      }
      unawaited(cubit.avanzar());
      await tester.pumpAndSettle();
      expect(cubit.state.paso, paso);
      expect(tester.takeException(), isNull, reason: 'paso ${paso.name}');
    }
    cubit.cambiarModoLote(ModoLote.dibujo);
    contornoDePrueba.forEach(cubit.agregarVertice);
    cubit
      ..retroceder()
      ..retroceder()
      ..retroceder();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('los controles tienen semántica y objetivo táctil de 48', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    prepararPantalla(tester, _telefono);
    await tester.pumpWidget(vista());
    unawaited(cubit.cargar());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    cubit
      ..elegirLote(cubit.state.lotes[1])
      ..elegirProducto('Insecticida piretroide');
    for (var i = 0; i < 3; i++) {
      if (i == 2) cubit.elegirFecha(cubit.state.fechas[2]);
      unawaited(cubit.avanzar());
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    semantica.dispose();
  });
}
