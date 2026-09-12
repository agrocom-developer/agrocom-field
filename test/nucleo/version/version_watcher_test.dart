// Etapa 2 de HU-20: `VersionWatcher` — polling en primer plano contra
// `VersionRepository`/`VersionInstalada` mockeados (mocktail). Usa
// `testWidgets` en vez de `test` puro únicamente para aprovechar la zona de
// tiempo virtual que arma `flutter_test`: sin ella, `Timer.periodic`
// correría en tiempo real y el test tendría que esperar minutos de verdad
// — mismo recurso que ya usa `orden_detalle_pantalla_test.dart` para drenar
// un `Future.delayed` sin esperarlo de verdad.

import 'package:agrocom_field/nucleo/version/estado_version.dart';
import 'package:agrocom_field/nucleo/version/version_apk.dart';
import 'package:agrocom_field/nucleo/version/version_instalada.dart';
import 'package:agrocom_field/nucleo/version/version_repository.dart';
import 'package:agrocom_field/nucleo/version/version_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _VersionRepositoryFalso extends Mock implements VersionRepository {}

class _VersionInstaladaFalsa extends Mock implements VersionInstalada {}

void main() {
  late _VersionRepositoryFalso repositorio;
  late _VersionInstaladaFalsa instalada;

  setUp(() {
    repositorio = _VersionRepositoryFalso();
    instalada = _VersionInstaladaFalsa();
    when(() => instalada.versionCode()).thenAnswer((_) async => 100);
  });

  testWidgets('al iniciar, lee el version_code una vez y consulta el estado', (
    tester,
  ) async {
    when(
      () => repositorio.consultarEstado(100),
    ).thenAnswer((_) async => const VersionPermitida());

    final watcher = VersionWatcher(
      repositorio: repositorio,
      versionInstalada: instalada,
    );
    addTearDown(watcher.dispose);

    final emisiones = <EstadoVersion>[];
    final suscripcion = watcher.estado.listen(emisiones.add);
    addTearDown(suscripcion.cancel);

    await watcher.iniciar();
    // `StreamController.broadcast()` sin `sync: true` entrega los eventos
    // en un microtask aparte del que llamó `add` — este `pump()` lo drena
    // antes de mirar `emisiones` (mismo motivo por el que el resto del
    // repo usa `pumpAndSettle` tras acciones asíncronas).
    await tester.pump();

    verify(() => instalada.versionCode()).called(1);
    verify(() => repositorio.consultarEstado(100)).called(1);
    expect(emisiones, [const VersionPermitida()]);

    // `flutter_test` verifica que no queden timers pendientes apenas
    // termina el cuerpo del test — antes de que corran los `addTearDown`
    // — así que el `Timer.periodic` del watcher hay que cancelarlo acá.
    watcher.detener();
  });

  testWidgets(
    'repite la consulta en cada intervalo, sin releer el version_code',
    (tester) async {
      when(
        () => repositorio.consultarEstado(100),
      ).thenAnswer((_) async => const VersionPermitida());

      final watcher = VersionWatcher(
        repositorio: repositorio,
        versionInstalada: instalada,
        intervalo: const Duration(minutes: 15),
      );
      addTearDown(watcher.dispose);

      final emisiones = <EstadoVersion>[];
      final suscripcion = watcher.estado.listen(emisiones.add);
      addTearDown(suscripcion.cancel);

      await watcher.iniciar();
      await tester.pump();
      expect(emisiones.length, 1);

      await tester.pump(const Duration(minutes: 15));
      expect(emisiones.length, 2);

      await tester.pump(const Duration(minutes: 15));
      expect(emisiones.length, 3);

      verify(() => instalada.versionCode()).called(1);
      verify(() => repositorio.consultarEstado(100)).called(3);

      watcher.detener();
    },
  );

  testWidgets(
    'detener cancela el timer: no vuelve a consultar tras el intervalo',
    (tester) async {
      when(
        () => repositorio.consultarEstado(100),
      ).thenAnswer((_) async => const VersionPermitida());

      final watcher = VersionWatcher(
        repositorio: repositorio,
        versionInstalada: instalada,
        intervalo: const Duration(minutes: 15),
      );
      addTearDown(watcher.dispose);

      await watcher.iniciar();
      watcher.detener();

      await tester.pump(const Duration(minutes: 30));

      verify(() => repositorio.consultarEstado(100)).called(1);
    },
  );

  testWidgets('propaga VersionBloqueada tal cual la devuelve el repositorio', (
    tester,
  ) async {
    const minima = VersionApk(
      version: '2.0.0',
      versionCode: 200,
      urlDescarga: 'https://example.com/2.0.0.apk',
    );
    when(
      () => repositorio.consultarEstado(100),
    ).thenAnswer((_) async => const VersionBloqueada(minima));

    final watcher = VersionWatcher(
      repositorio: repositorio,
      versionInstalada: instalada,
    );
    addTearDown(watcher.dispose);

    final emisiones = <EstadoVersion>[];
    final suscripcion = watcher.estado.listen(emisiones.add);
    addTearDown(suscripcion.cancel);

    await watcher.iniciar();
    await tester.pump();
    watcher.detener();

    expect(emisiones, [const VersionBloqueada(minima)]);
  });
}
