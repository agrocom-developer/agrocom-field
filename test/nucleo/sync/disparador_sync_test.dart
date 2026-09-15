// Etapa 2 de TE-19: `DisparadorSync` contra los tres motores mockeados
// (mocktail, mismo patrón que `avisos_locales_watcher_test.dart`) y un
// `StreamController<List<ConnectivityResult>>` controlado a mano en vez de
// `Connectivity()` real — el criterio central de la tarea: un ciclo completo
// al iniciar, un ciclo completo por cada transición sin-señal → con-señal,
// y ningún otro cambio de conectividad dispara nada.

import 'dart:async';

import 'package:agrocom_field/nucleo/api/api_excepcion.dart';
import 'package:agrocom_field/nucleo/catalogo/catalogo_repository.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_sync_engine.dart';
import 'package:agrocom_field/nucleo/sync/disparador_sync.dart';
import 'package:agrocom_field/nucleo/sync/sync_engine.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CatalogoRepositoryFalso extends Mock implements CatalogoRepository {}

class _SyncEngineFalso extends Mock implements SyncEngine {}

class _EvidenciaSyncEngineFalso extends Mock implements EvidenciaSyncEngine {}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late StreamController<List<ConnectivityResult>> controlador;
  late _CatalogoRepositoryFalso catalogo;
  late _SyncEngineFalso syncEngine;
  late _EvidenciaSyncEngineFalso evidenciaSyncEngine;
  late DisparadorSync disparador;
  late List<String> orden;

  setUp(() {
    controlador = StreamController<List<ConnectivityResult>>.broadcast();
    catalogo = _CatalogoRepositoryFalso();
    syncEngine = _SyncEngineFalso();
    evidenciaSyncEngine = _EvidenciaSyncEngineFalso();
    orden = [];

    when(() => catalogo.pull()).thenAnswer((_) async {
      orden.add('pull');
      return false;
    });
    when(() => syncEngine.sincronizar()).thenAnswer((_) async {
      orden.add('sync');
    });
    when(() => evidenciaSyncEngine.sincronizar()).thenAnswer((_) async {
      orden.add('evidencias');
    });

    disparador = DisparadorSync(
      catalogoRepositorio: catalogo,
      syncEngine: syncEngine,
      evidenciaSyncEngine: evidenciaSyncEngine,
      cambiosConectividad: controlador.stream,
    );
  });

  tearDown(() async {
    await disparador.detener();
    await controlador.close();
  });

  test('iniciar() agota el catálogo en loop y recién después sincroniza el '
      'outbox y las evidencias, en ese orden', () async {
    var llamadosPull = 0;
    when(() => catalogo.pull()).thenAnswer((_) async {
      llamadosPull++;
      orden.add('pull');
      return llamadosPull < 3;
    });

    await disparador.iniciar();

    expect(llamadosPull, 3);
    expect(orden, ['pull', 'pull', 'pull', 'sync', 'evidencias']);
  });

  test('un error del catálogo (servidor, o respuesta mal formada) no impide '
      'que el outbox y las evidencias sincronicen en el mismo ciclo', () async {
    when(
      () => catalogo.pull(),
    ).thenThrow(const ApiExcepcionServidor(500, null));

    await disparador.iniciar();

    expect(orden, ['sync', 'evidencias']);
  });

  test('sincronizarAhora() dispara un ciclo completo sin tocar la suscripción '
      'de conectividad — llamarlo dos veces no la duplica', () async {
    await disparador.iniciar();
    orden.clear();

    await disparador.sincronizarAhora();
    expect(orden, ['pull', 'sync', 'evidencias']);

    orden.clear();
    controlador.add([ConnectivityResult.none]);
    await _flush();
    controlador.add([ConnectivityResult.wifi]);
    await _flush();

    expect(
      orden,
      ['pull', 'sync', 'evidencias'],
      reason: 'una sola suscripción activa: un solo ciclo por la transición',
    );
  });

  test('la primera emisión de conectividad tras iniciar() no cuenta como '
      'transición: no dispara un ciclo extra', () async {
    await disparador.iniciar();
    orden.clear();

    controlador.add([ConnectivityResult.wifi]);
    await _flush();

    expect(orden, isEmpty);
  });

  test('la transición sin-conectividad → con-conectividad dispara un ciclo '
      'completo', () async {
    await disparador.iniciar();
    orden.clear();

    controlador.add([ConnectivityResult.none]);
    await _flush();
    expect(orden, isEmpty, reason: 'la primera emisión es línea de base');

    controlador.add([ConnectivityResult.wifi]);
    await _flush();

    expect(orden, ['pull', 'sync', 'evidencias']);
  });

  test(
    'con-conectividad → sin-conectividad no dispara un ciclo nuevo',
    () async {
      await disparador.iniciar();
      orden.clear();

      controlador.add([ConnectivityResult.wifi]);
      await _flush();
      expect(orden, isEmpty, reason: 'la primera emisión es línea de base');

      controlador.add([ConnectivityResult.none]);
      await _flush();

      expect(orden, isEmpty);
    },
  );

  test('con-conectividad → con-conectividad de otro tipo no dispara un ciclo '
      'nuevo', () async {
    await disparador.iniciar();
    orden.clear();

    controlador.add([ConnectivityResult.wifi]);
    await _flush();
    expect(orden, isEmpty, reason: 'la primera emisión es línea de base');

    controlador.add([ConnectivityResult.mobile]);
    await _flush();

    expect(orden, isEmpty);
  });

  test(
    'sin-conectividad → sin-conectividad no dispara un ciclo nuevo',
    () async {
      await disparador.iniciar();
      orden.clear();

      controlador.add([ConnectivityResult.none]);
      await _flush();
      expect(orden, isEmpty, reason: 'la primera emisión es línea de base');

      controlador.add([ConnectivityResult.none]);
      await _flush();

      expect(orden, isEmpty);
    },
  );

  test('detener() cancela la suscripción: conectividad recuperada después ya '
      'no dispara nada', () async {
    await disparador.iniciar();
    orden.clear();

    controlador.add([ConnectivityResult.none]);
    await _flush();

    await disparador.detener();

    controlador.add([ConnectivityResult.wifi]);
    await _flush();

    expect(orden, isEmpty);
  });
}
