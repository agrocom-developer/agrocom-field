// Etapa 2 de HU-62: `AvisosLocalesWatcher` contra un `Stream` controlado a
// mano (fake de `OrdenesRepository`, mismo patrón que
// `ordenes_cubit_test.dart`) y un fake de `NotificadorLocal` — el criterio
// de aceptación central de la tarea: la primera emisión nunca dispara
// notificaciones, y una orden nueva sí, exactamente una vez.

import 'dart:async';

import 'package:agrocom_field/features/avisos_locales/data/avisos_locales_watcher.dart';
import 'package:agrocom_field/features/avisos_locales/data/ids_vistos_store.dart';
import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/nucleo/notificaciones/notificador_local.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OrdenesRepositoryFalso extends Mock implements OrdenesRepository {}

class _NotificadorLocalFalso extends Mock implements NotificadorLocal {}

OrdenVigente _orden(int id) => OrdenVigente(
  id: id,
  contratoId: 1,
  loteId: 1,
  nroAplicacion: 1,
  litrosHa: Decimal.parse('10.00'),
  fechaEmision: '2026-08-26',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 8, 26, 12),
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late StreamController<List<OrdenVigente>> controlador;
  late _OrdenesRepositoryFalso repositorio;
  late _NotificadorLocalFalso notificador;
  late AvisosLocalesWatcher watcher;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controlador = StreamController<List<OrdenVigente>>.broadcast();
    repositorio = _OrdenesRepositoryFalso();
    notificador = _NotificadorLocalFalso();
    when(
      () => repositorio.ordenesVigentes(),
    ).thenAnswer((_) => controlador.stream);
    when(
      () => notificador.mostrar(
        id: any(named: 'id'),
        titulo: any(named: 'titulo'),
        cuerpo: any(named: 'cuerpo'),
      ),
    ).thenAnswer((_) async {});
    watcher = AvisosLocalesWatcher(
      ordenesRepositorio: repositorio,
      notificador: notificador,
      idsVistosStore: IdsVistosStoreLocal(),
    );
  });

  tearDown(() async {
    await watcher.detener();
    await controlador.close();
  });

  test('la primera emisión no dispara ninguna notificación', () async {
    await watcher.iniciar();

    controlador.add([_orden(1), _orden(2)]);
    await _flush();

    verifyNever(
      () => notificador.mostrar(
        id: any(named: 'id'),
        titulo: any(named: 'titulo'),
        cuerpo: any(named: 'cuerpo'),
      ),
    );
  });

  test(
    'una orden nueva tras la línea de base dispara mostrar una vez',
    () async {
      await watcher.iniciar();
      controlador.add([_orden(1)]);
      await _flush();

      controlador.add([_orden(1), _orden(2)]);
      await _flush();

      verify(
        () => notificador.mostrar(
          id: 2,
          titulo: any(named: 'titulo'),
          cuerpo: any(named: 'cuerpo'),
        ),
      ).called(1);
      verifyNever(
        () => notificador.mostrar(
          id: 1,
          titulo: any(named: 'titulo'),
          cuerpo: any(named: 'cuerpo'),
        ),
      );
    },
  );

  test(
    'varias órdenes nuevas en la misma emisión disparan mostrar por cada una',
    () async {
      await watcher.iniciar();
      controlador.add(const []);
      await _flush();

      controlador.add([_orden(1), _orden(2)]);
      await _flush();

      verify(
        () => notificador.mostrar(
          id: 1,
          titulo: any(named: 'titulo'),
          cuerpo: any(named: 'cuerpo'),
        ),
      ).called(1);
      verify(
        () => notificador.mostrar(
          id: 2,
          titulo: any(named: 'titulo'),
          cuerpo: any(named: 'cuerpo'),
        ),
      ).called(1);
    },
  );

  test(
    'la misma orden no se reenvía en una emisión posterior sin cambios en el set de ids vistos',
    () async {
      await watcher.iniciar();
      controlador.add([_orden(1)]);
      await _flush();

      controlador.add([_orden(1), _orden(2)]);
      await _flush();
      controlador.add([_orden(1), _orden(2)]);
      await _flush();

      verify(
        () => notificador.mostrar(
          id: 2,
          titulo: any(named: 'titulo'),
          cuerpo: any(named: 'cuerpo'),
        ),
      ).called(1);
    },
  );

  test('persiste los ids vistos en el store entre emisiones', () async {
    final store = IdsVistosStoreLocal();
    watcher = AvisosLocalesWatcher(
      ordenesRepositorio: repositorio,
      notificador: notificador,
      idsVistosStore: store,
    );
    await watcher.iniciar();
    controlador.add([_orden(1)]);
    await _flush();

    controlador.add([_orden(1), _orden(2)]);
    await _flush();

    expect(await store.leerVistos(), {1, 2});
  });
}
