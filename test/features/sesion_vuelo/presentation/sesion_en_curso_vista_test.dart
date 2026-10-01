// Tarea 27: `SesionVueloPantalla` arranca en lo que hay en `drift` para su
// trabajo — con la sesión que quedó abierta la muestra activa y se cierra
// con ESE `uuid_cliente`; sin sesión, desde `SesionInicial` se cierra el
// trabajo; y el formulario de apertura no deja confirmar una sesión nueva
// cuando algo lo bloquea, con el motivo a la vista.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/auxiliar.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_apertura.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/reglas_condiciones.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/sesion.dart';
import 'package:agrocom_field/features/sesion_vuelo/domain/trabajo.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_bloc.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import 'package:agrocom_field/features/sesion_vuelo/presentation/trabajo_cubit.dart';
import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SesionRepositoryFalso extends Mock implements SesionRepository {}

class _TrabajoRepositoryFalso extends Mock implements TrabajoRepository {}

class _PersonaOperativaStoreFalso extends Mock
    implements PersonaOperativaStore {}

class _EvidenciaRepositoryFalso extends Mock implements EvidenciaRepository {}

class _SelectorFotoFalso extends Mock implements SelectorFoto {}

const _trabajoUuid = 'uuid-trabajo-1';

// PNG 1x1 real: `Image.memory` del preview decodifica de verdad (mismo
// fixture que `sesion_vuelo_vista_test.dart`).
final _bytesFoto = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42Y'
  'AAAAASUVORK5CYII=',
);

Sesion _sesion({EstadoSesion estado = EstadoSesion.abierta}) => Sesion(
  uuidCliente: 'uuid-sesion-que-quedo-abierta',
  trabajoUuidCliente: _trabajoUuid,
  secuencia: 3,
  pilotoId: 7,
  hectareasDeclaradas: Decimal.zero,
  inicio: DateTime.utc(2026, 10, 1, 9, 30),
  estado: estado,
  fin: estado == EstadoSesion.cerrada ? DateTime.utc(2026, 10, 1, 11) : null,
  motivoCierre: estado == EstadoSesion.cerrada ? 'completado' : null,
  hectareasDeclaradasCierre: estado == EstadoSesion.cerrada
      ? Decimal.parse('12.5')
      : null,
);

void main() {
  late _SesionRepositoryFalso sesionRepositorio;
  late _TrabajoRepositoryFalso trabajoRepositorio;
  late _EvidenciaRepositoryFalso evidenciaRepositorio;
  late _SelectorFotoFalso selectorFoto;

  setUpAll(() {
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    sesionRepositorio = _SesionRepositoryFalso();
    trabajoRepositorio = _TrabajoRepositoryFalso();
    evidenciaRepositorio = _EvidenciaRepositoryFalso();
    selectorFoto = _SelectorFotoFalso();
    when(
      () => sesionRepositorio.sesionAbiertaDeTrabajo(any()),
    ).thenAnswer((_) async => null);
    when(
      () => sesionRepositorio.limitesCondiciones(any()),
    ).thenAnswer((_) async => LimitesCondiciones.porDefecto());
    when(
      () => sesionRepositorio.auxiliaresDisponibles(),
    ).thenAnswer((_) async => const <Auxiliar>[]);
    when(
      () => sesionRepositorio.restriccionAperturaDeTrabajo(any()),
    ).thenAnswer((_) async => RestriccionApertura.ninguna);
  });

  Future<void> bombear(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SesionVueloPantalla(
          crearBloc: () => SesionBloc(
            sesionRepositorio: sesionRepositorio,
            personaOperativaStore: _PersonaOperativaStoreFalso(),
            trabajoUuidCliente: _trabajoUuid,
          ),
          crearTrabajoCubit: () => TrabajoCubit(
            trabajoRepositorio,
            evidenciaRepositorio: evidenciaRepositorio,
            selectorFoto: selectorFoto,
          ),
          crearIncidenciaCubit: (_) =>
              throw UnimplementedError('no se invoca en este test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  VoidCallback? onPressedPrimario(WidgetTester tester, String key) =>
      tester.widget<BotonPrimarioCampo>(find.byKey(Key(key))).onPressed;

  testWidgets('volver a una sesión abierta: arranca activa con ESA sesión y '
      'el cierre va con su uuid_cliente', (tester) async {
    when(
      () => sesionRepositorio.sesionAbiertaDeTrabajo(_trabajoUuid),
    ).thenAnswer((_) async => _sesion());
    when(
      () => sesionRepositorio.cerrarSesion(
        sesionUuidCliente: any(named: 'sesionUuidCliente'),
        fin: any(named: 'fin'),
        motivoCierre: any(named: 'motivoCierre'),
        hectareasDeclaradas: any(named: 'hectareasDeclaradas'),
        hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
        litrosConsumidos: any(named: 'litrosConsumidos'),
      ),
    ).thenAnswer((_) async => _sesion(estado: EstadoSesion.cerrada));

    await bombear(tester);

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(
      tester
          .widget<StatChipCampo>(find.byKey(const Key('sesion_secuencia')))
          .valor,
      '3',
    );
    expect(find.byKey(const Key('boton_abrir_sesion')), findsNothing);

    await tester.tap(find.byKey(const Key('boton_cerrar_sesion')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cierre_hectareas')), '12.5');
    await tester.tap(find.byKey(const Key('cierre_motivo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_cierre')));
    await tester.pumpAndSettle();

    expect(find.text('Sesión cerrada'), findsOneWidget);
    verify(
      () => sesionRepositorio.cerrarSesion(
        sesionUuidCliente: 'uuid-sesion-que-quedo-abierta',
        fin: any(named: 'fin'),
        motivoCierre: 'completado',
        hectareasDeclaradas: Decimal.parse('12.5'),
        hectareaFinalAcumulada: any(named: 'hectareaFinalAcumulada'),
        litrosConsumidos: any(named: 'litrosConsumidos'),
      ),
    ).called(1);
    verifyNever(
      () => sesionRepositorio.abrirSesion(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        pilotoId: any(named: 'pilotoId'),
        inicio: any(named: 'inicio'),
        vientoKmh: any(named: 'vientoKmh'),
        temperaturaC: any(named: 'temperaturaC'),
        humedadPct: any(named: 'humedadPct'),
      ),
    );
  });

  testWidgets('volver a un trabajo abierto sin sesión: desde el inicio se '
      'cierra el trabajo, y ya no se abre otra sesión sobre él', (
    tester,
  ) async {
    when(() => selectorFoto.tomarFoto()).thenAnswer((_) async => _bytesFoto);
    when(
      () => evidenciaRepositorio.capturarEvidencia(
        bytesOriginales: any(named: 'bytesOriginales'),
        tipo: any(named: 'tipo'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer((_) async => 'uuid-evidencia-campo-1');
    when(
      () => trabajoRepositorio.cerrarTrabajo(
        trabajoUuidCliente: any(named: 'trabajoUuidCliente'),
        fin: any(named: 'fin'),
        litrosSobrante: any(named: 'litrosSobrante'),
        evidenciaImagenCampoUuidCliente: any(
          named: 'evidenciaImagenCampoUuidCliente',
        ),
      ),
    ).thenAnswer(
      (_) async => Trabajo(
        uuidCliente: _trabajoUuid,
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 1,
        hectareasDeclaradas: Decimal.zero,
        inicio: DateTime.utc(2026, 10, 1, 9),
        estado: EstadoTrabajo.cerrado,
      ),
    );

    await bombear(tester);

    expect(onPressedPrimario(tester, 'boton_abrir_sesion'), isNotNull);
    await tester.tap(find.byKey(const Key('boton_cerrar_trabajo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_tomar_foto_campo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_confirmar_cierre_trabajo')));
    await tester.pumpAndSettle();

    verify(
      () => trabajoRepositorio.cerrarTrabajo(
        trabajoUuidCliente: _trabajoUuid,
        fin: any(named: 'fin'),
        litrosSobrante: any(named: 'litrosSobrante'),
        evidenciaImagenCampoUuidCliente: 'uuid-evidencia-campo-1',
      ),
    ).called(1);
    expect(find.byKey(const Key('trabajo_cerrado')), findsOneWidget);
    expect(onPressedPrimario(tester, 'boton_abrir_sesion'), isNull);
  });

  testWidgets('con una restricción, el formulario muestra el motivo y no '
      'deja confirmar la apertura', (tester) async {
    when(
      () => sesionRepositorio.restriccionAperturaDeTrabajo(_trabajoUuid),
    ).thenAnswer(
      (_) async => const RestriccionApertura(bloqueo: 'motivo del bloqueo'),
    );

    await bombear(tester);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BannerAlertaCampo>(
            find.byKey(const Key('apertura_bloqueada')),
          )
          .texto,
      'motivo del bloqueo',
    );
    expect(onPressedPrimario(tester, 'boton_confirmar_apertura'), isNull);
  });

  testWidgets('sin restricción, el formulario no muestra bloqueo y deja '
      'confirmar', (tester) async {
    await bombear(tester);
    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apertura_bloqueada')), findsNothing);
    expect(onPressedPrimario(tester, 'boton_confirmar_apertura'), isNotNull);
  });

  testWidgets('trabajo dado_de_baja: aviso en la pantalla, apertura '
      'bloqueada con el motivo y el trabajo se puede cerrar', (tester) async {
    when(
      () => sesionRepositorio.restriccionAperturaDeTrabajo(_trabajoUuid),
    ).thenAnswer(
      (_) async => restriccionApertura(
        haySesionAbierta: false,
        motivoRetiroTrabajo: 'dado_de_baja',
      ),
    );

    await bombear(tester);

    expect(
      tester
          .widget<NotaInlineCampo>(find.byKey(const Key('sesion_aviso_retiro')))
          .texto,
      'El trabajo fue dado de baja desde el panel.',
    );
    expect(
      tester
          .widget<BotonSecundarioCampo>(
            find.byKey(const Key('boton_cerrar_trabajo')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BannerAlertaCampo>(
            find.byKey(const Key('apertura_bloqueada')),
          )
          .texto,
      contains('dado de baja'),
    );
    expect(onPressedPrimario(tester, 'boton_confirmar_apertura'), isNull);
  });

  testWidgets('trabajo dado_de_baja con la sesión YA abierta: se sigue '
      'pudiendo cerrar', (tester) async {
    when(
      () => sesionRepositorio.sesionAbiertaDeTrabajo(_trabajoUuid),
    ).thenAnswer((_) async => _sesion());
    when(
      () => sesionRepositorio.restriccionAperturaDeTrabajo(_trabajoUuid),
    ).thenAnswer(
      (_) async => restriccionApertura(
        haySesionAbierta: true,
        motivoRetiroTrabajo: 'dado_de_baja',
      ),
    );

    await bombear(tester);

    expect(find.byKey(const Key('sesion_aviso_retiro')), findsOneWidget);
    expect(onPressedPrimario(tester, 'boton_cerrar_sesion'), isNotNull);
  });

  for (final motivo in const [
    'reasignado',
    'cerrado',
    'orden_cerrada',
    'fuera_de_alcance',
  ]) {
    testWidgets('trabajo $motivo: aviso en la pantalla, pero la apertura '
        'no se bloquea', (tester) async {
      when(
        () => sesionRepositorio.restriccionAperturaDeTrabajo(_trabajoUuid),
      ).thenAnswer(
        (_) async => restriccionApertura(
          haySesionAbierta: false,
          motivoRetiroTrabajo: motivo,
        ),
      );

      await bombear(tester);

      expect(find.byKey(const Key('sesion_aviso_retiro')), findsOneWidget);
      await tester.tap(find.byKey(const Key('boton_abrir_sesion')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apertura_bloqueada')), findsNothing);
      expect(onPressedPrimario(tester, 'boton_confirmar_apertura'), isNotNull);
    });
  }

  testWidgets('trabajo vigente: sin aviso de retiro', (tester) async {
    await bombear(tester);

    expect(find.byKey(const Key('sesion_aviso_retiro')), findsNothing);
  });
}
