// HU-08: widget test de `IncidenciaVista` — selector de tipo (6 opciones),
// descripción opcional, foto SIEMPRE obligatoria (el botón de envío queda
// deshabilitado sin ella), y el camino feliz/error contra un
// `IncidenciaCubit` real conectado a `IncidenciaRepository`/`SelectorFoto`
// mockeados.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/features/incidencias/data/incidencia_repository.dart';
import 'package:agrocom_field/features/incidencias/domain/incidencia.dart';
import 'package:agrocom_field/features/incidencias/domain/reglas_incidencia.dart';
import 'package:agrocom_field/features/incidencias/domain/tipo_incidencia.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_cubit.dart';
import 'package:agrocom_field/features/incidencias/presentation/incidencia_vista.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _IncidenciaRepositoryFalso extends Mock implements IncidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

// PNG 1x1 real (no bytes arbitrarios): `Image.memory` en el preview decodifica
// de verdad — bytes inválidos hacen que el widget test falle por la
// excepción asincrónica del decodificador de imagen, no por el fixture.
final _bytesFotoValidos = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42Y'
  'AAAAASUVORK5CYII=',
);

Incidencia _incidencia() => Incidencia(
  uuidCliente: 'uuid-incidencia-1',
  sesionUuidCliente: 'uuid-sesion-1',
  tipo: TipoIncidencia.mecanica,
  hora: DateTime.utc(2026, 9, 11, 10),
  evidenciaFotoUuidCliente: 'uuid-evidencia-1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime.now());
    registerFallbackValue(TipoIncidencia.otro);
  });

  late _IncidenciaRepositoryFalso repositorio;
  late _SelectorFotoFalso selectorFoto;

  setUp(() {
    repositorio = _IncidenciaRepositoryFalso();
    selectorFoto = _SelectorFotoFalso();
  });

  Future<void> bombear(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<IncidenciaCubit>(
        create: (_) => IncidenciaCubit(
          incidenciaRepositorio: repositorio,
          selectorFoto: selectorFoto,
          sesionUuidCliente: 'uuid-sesion-1',
        ),
        child: const IncidenciaVista(),
      ),
    ),
  );

  Finder botonGuardar() => find.byKey(const Key('boton_guardar_incidencia'));

  // El selector de tipo es una fila desplazable (modo campo, ADR 0008): la
  // opción puede quedar fuera de pantalla hasta desplazarla.
  Future<void> elegirTipo(WidgetTester tester, String etiqueta) async {
    await tester.ensureVisible(find.text(etiqueta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(etiqueta));
  }

  // `BotonPrimarioCampo` (modo campo, ADR 0008) envuelve el botón de
  // Material que se habilita o no: el criterio se verifica sobre ese.
  FilledButton botonGuardarMaterial(WidgetTester tester) =>
      tester.widget<FilledButton>(
        find.descendant(
          of: botonGuardar(),
          matching: find.byType(FilledButton),
        ),
      );

  testWidgets('muestra las 6 opciones del selector de tipo', (tester) async {
    await bombear(tester);
    await tester.pumpAndSettle();

    expect(find.text('Caldo / mezcla'), findsOneWidget);
    expect(find.text('ESC'), findsOneWidget);
    expect(find.text('Batería'), findsOneWidget);
    expect(find.text('Mecánica'), findsOneWidget);
    expect(find.text('Clima'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);
  });

  testWidgets(
    'botón guardar deshabilitado sin foto, incluso con tipo elegido',
    (tester) async {
      await bombear(tester);

      await elegirTipo(tester, 'Mecánica');
      await tester.pumpAndSettle();

      final boton = botonGuardarMaterial(tester);
      expect(boton.onPressed, isNull);
      verifyNever(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      );
    },
  );

  testWidgets('botón guardar deshabilitado con foto pero sin tipo elegido', (
    tester,
  ) async {
    when(
      () => selectorFoto.tomarFoto(),
    ).thenAnswer((_) async => _bytesFotoValidos);
    await bombear(tester);

    await tester.tap(find.byKey(const Key('boton_tomar_foto')));
    await tester.pumpAndSettle();

    final boton = botonGuardarMaterial(tester);
    expect(boton.onPressed, isNull);
  });

  testWidgets(
    'con tipo y foto, guardar llama a registrarIncidencia y ante éxito '
    'cierra la pantalla',
    (tester) async {
      final bytesFoto = _bytesFotoValidos;
      when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => bytesFoto);
      when(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: any(named: 'sesionUuidCliente'),
          tipo: any(named: 'tipo'),
          descripcion: any(named: 'descripcion'),
          hora: any(named: 'hora'),
          bytesFoto: any(named: 'bytesFoto'),
        ),
      ).thenAnswer((_) async => _incidencia());

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => BlocProvider<IncidenciaCubit>(
                create: (_) => IncidenciaCubit(
                  incidenciaRepositorio: repositorio,
                  selectorFoto: selectorFoto,
                  sesionUuidCliente: 'uuid-sesion-1',
                ),
                child: const IncidenciaVista(),
              ),
            ),
          ),
        ),
      );

      await elegirTipo(tester, 'Batería');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_tomar_foto')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_foto')), findsOneWidget);

      final boton = botonGuardarMaterial(tester);
      expect(boton.onPressed, isNotNull);

      await tester.tap(botonGuardar());
      await tester.pumpAndSettle();

      verify(
        () => repositorio.registrarIncidencia(
          sesionUuidCliente: 'uuid-sesion-1',
          tipo: TipoIncidencia.bateria,
          descripcion: null,
          hora: any(named: 'hora'),
          bytesFoto: bytesFoto,
        ),
      ).called(1);
      // La pantalla se cerró (Navigator hizo pop): IncidenciaVista ya no
      // está en el árbol.
      expect(find.byType(IncidenciaVista), findsNothing);
    },
  );

  testWidgets('error del repositorio muestra SnackBar y no cierra la '
      'pantalla', (tester) async {
    when(
      () => selectorFoto.tomarFoto(),
    ).thenAnswer((_) async => _bytesFotoValidos);
    when(
      () => repositorio.registrarIncidencia(
        sesionUuidCliente: any(named: 'sesionUuidCliente'),
        tipo: any(named: 'tipo'),
        descripcion: any(named: 'descripcion'),
        hora: any(named: 'hora'),
        bytesFoto: any(named: 'bytesFoto'),
      ),
    ).thenThrow(const SesionCerradaExcepcion('uuid-sesion-1'));

    await bombear(tester);

    await elegirTipo(tester, 'Otro');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton_tomar_foto')));
    await tester.pumpAndSettle();

    await tester.tap(botonGuardar());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('ya está cerrada'), findsOneWidget);
    expect(find.byType(IncidenciaVista), findsOneWidget);
  });

  testWidgets('descripción con texto se envía trimeada; vacía se envía null', (
    tester,
  ) async {
    when(
      () => selectorFoto.tomarFoto(),
    ).thenAnswer((_) async => _bytesFotoValidos);
    when(
      () => repositorio.registrarIncidencia(
        sesionUuidCliente: any(named: 'sesionUuidCliente'),
        tipo: any(named: 'tipo'),
        descripcion: any(named: 'descripcion'),
        hora: any(named: 'hora'),
        bytesFoto: any(named: 'bytesFoto'),
      ),
    ).thenAnswer((_) async => _incidencia());

    await bombear(tester);

    await elegirTipo(tester, 'Caldo / mezcla');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo_descripcion')),
      '  Caldo mal mezclado  ',
    );
    await tester.tap(find.byKey(const Key('boton_tomar_foto')));
    await tester.pumpAndSettle();

    await tester.tap(botonGuardar());
    await tester.pumpAndSettle();

    verify(
      () => repositorio.registrarIncidencia(
        sesionUuidCliente: 'uuid-sesion-1',
        tipo: TipoIncidencia.caldo,
        descripcion: 'Caldo mal mezclado',
        hora: any(named: 'hora'),
        bytesFoto: any(named: 'bytesFoto'),
      ),
    ).called(1);
  });

  testWidgets('modo campo: tema campo, sin AppBar, tipo con selector '
      'segmentado y la foto en ámbar hasta tomarla', (tester) async {
    when(
      () => selectorFoto.tomarFoto(),
    ).thenAnswer((_) async => _bytesFotoValidos);
    await bombear(tester);
    await tester.pumpAndSettle();

    final contexto = tester.element(botonGuardar());
    expect(Theme.of(contexto).extension<TemaCampo>(), isNotNull);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(EncabezadoCampo), findsOneWidget);

    final selector = tester.widget<SelectorSegmentadoCampo<TipoIncidencia?>>(
      find.byKey(const Key('selector_tipo_incidencia')),
    );
    expect(selector.seleccionado, isNull);
    expect(selector.desplazable, isTrue);

    await elegirTipo(tester, 'Clima');
    await tester.pump();
    expect(
      tester
          .widget<SelectorSegmentadoCampo<TipoIncidencia?>>(
            find.byKey(const Key('selector_tipo_incidencia')),
          )
          .seleccionado,
      TipoIncidencia.clima,
    );

    BotonAgregarPunteadoCampo slotFoto() => tester.widget(
      find.byKey(const Key('boton_tomar_foto'), skipOffstage: false),
    );
    expect(slotFoto().alerta, isTrue);
    expect(botonGuardarMaterial(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('boton_tomar_foto')));
    await tester.pumpAndSettle();

    expect(slotFoto().alerta, isFalse);
    expect(find.byKey(const Key('preview_foto')), findsOneWidget);
    expect(botonGuardarMaterial(tester).onPressed, isNotNull);
  });
}
