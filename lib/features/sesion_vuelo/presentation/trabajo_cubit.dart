import 'package:bloc/bloc.dart';
import 'package:decimal/decimal.dart';

import '../data/trabajo_repository.dart';
import '../../../features/ordenes/domain/orden_vigente.dart';
import 'trabajo_estado.dart';

/// Adaptador delgado entre `TrabajoRepository` (sin BLoC) y la pantalla de
/// apertura de trabajo — traduce cada invocación async de `abrirTrabajo` a un
/// `TrabajoEstado`.
class TrabajoCubit extends Cubit<TrabajoEstado> {
  TrabajoCubit(this._repositorio) : super(const TrabajoInicial());

  final TrabajoRepository _repositorio;

  /// Abre un trabajo basado en una orden vigente (HU-05, Etapa 3) — emite
  /// cargando y luego exitoso o error. [orden] contiene `id`, `loteId`,
  /// `nroAplicacion` que se necesitan; la pantalla lo tiene completo porque
  /// viene de `OrdenDetallePantalla`.
  Future<void> abrir({required OrdenVigente orden}) async {
    emit(const TrabajoCargando());
    try {
      final trabajo = await _repositorio.abrirTrabajo(
        ordenId: orden.id,
        loteId: orden.loteId,
        nroAplicacion: orden.nroAplicacion,
        hectareasDeclaradas: orden.loteHectareas ?? Decimal.parse('0'),
        inicio: DateTime.now(),
      );
      emit(TrabajoExitoso(trabajo));
    } catch (e) {
      emit(TrabajoError('Error al abrir trabajo: ${e.toString()}'));
    }
  }
}
