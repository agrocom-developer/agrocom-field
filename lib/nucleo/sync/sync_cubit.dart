import 'dart:async';

import 'package:bloc/bloc.dart';

import 'estado_sync.dart';
import 'sync_engine.dart';

/// Expone el `Stream<EstadoMotorSync>` de un [SyncEngine] como estado de
/// Cubit para que la UI (`flutter-ui`) lo consuma con
/// `BlocBuilder`/`BlocListener`.
///
/// Este Cubit no contiene lógica de sync propia: es un adaptador delgado
/// entre el motor (`nucleo/sync`, sin BLoC) y la capa de presentación. Vive
/// acá porque `SyncEngine` es quien lo produce, pero quien lo instancia y
/// expone a los widgets es `flutter-ui`, no este archivo.
class SyncCubit extends Cubit<EstadoMotorSync> {
  SyncCubit(SyncEngine motor) : super(EstadoMotorSync.ocioso) {
    _suscripcion = motor.estado.listen(emit);
  }

  late final StreamSubscription<EstadoMotorSync> _suscripcion;

  @override
  Future<void> close() async {
    await _suscripcion.cancel();
    return super.close();
  }
}
