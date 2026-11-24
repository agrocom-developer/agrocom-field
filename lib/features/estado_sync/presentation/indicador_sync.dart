import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/sync/estado_sync.dart';
import '../../../nucleo/sync/sync_cubit.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';

/// Estado de sincronización del dispositivo, leído del `SyncCubit` que la
/// app provee sobre el `Navigator`. Solo lee: no dispara ciclos ni toca el
/// outbox.
///
/// Sin `SyncCubit` en el árbol (modo demo, un test de pantalla) muestra
/// «En el dispositivo»: lo único que la pantalla puede afirmar por sí sola
/// es que el registro quedó guardado localmente.
class IndicadorSync extends StatelessWidget {
  const IndicadorSync({super.key});

  static EstadoSyncVisibleCampo visibleDe(EstadoMotorSync? motor) =>
      switch (motor) {
        null => EstadoSyncVisibleCampo.guardadoLocal,
        // Un motor ocioso no garantiza una cola vacía: solo que no hay un
        // ciclo corriendo. La pantalla afirma lo que sabe.
        EstadoMotorSync.ocioso => EstadoSyncVisibleCampo.guardadoLocal,
        EstadoMotorSync.sincronizando => EstadoSyncVisibleCampo.sincronizando,
        EstadoMotorSync.error => EstadoSyncVisibleCampo.sinSincronizar,
      };

  @override
  Widget build(BuildContext context) {
    final motor = context.watch<SyncCubit?>()?.state;
    return EstadoSyncCampo(
      key: const Key('indicador_sync'),
      estado: visibleDe(motor),
    );
  }
}
