import 'package:bloc/bloc.dart';

import '../../../nucleo/auth/persona_operativa_store.dart';
import '../data/sesion_repository.dart';
import '../domain/reglas_sesion.dart';
import 'sesion_estado.dart';
import 'sesion_evento.dart';

/// Adaptador delgado entre `SesionRepository` (sin BLoC) y la pantalla de
/// sesión de vuelo — modela el ciclo de apertura, actividad y cierre de una
/// sesión, con validación previa del `persona_id` (piloto) antes de proceder.
/// Es `Bloc`, no `Cubit` (ADR 0005 de `agrocom-api`, regla 4: "sesión" es el
/// caso nombrado de "flujo con secuencia y transiciones").
///
/// Vive en el contexto de UN trabajo abierto — su `uuid_cliente` se pasa al
/// construirlo. El estado "activa" persiste en memoria del Bloc, no se relee
/// reactivamente de `drift` (SesionRepository no expone Stream — por diseño,
/// ver HU-05).
class SesionBloc extends Bloc<SesionEvento, SesionEstado> {
  SesionBloc({
    required SesionRepository sesionRepositorio,
    required PersonaOperativaStore personaOperativaStore,
    required String trabajoUuidCliente,
  }) : _sesionRepositorio = sesionRepositorio,
       _personaOperativaStore = personaOperativaStore,
       _trabajoUuidCliente = trabajoUuidCliente,
       super(const SesionInicial()) {
    // Un solo `on<SesionEvento>` (no uno por subtipo), con transformer
    // secuencial explícito: el default de `package:bloc` procesa eventos
    // CONCURRENTEMENTE (ver `Bloc.transformer`, doc: "by default all events
    // are processed concurrently"), lo que dejaría que un `cerrar` agregado
    // antes de que `abrir` termine lea el estado viejo y compita con el
    // `emit` de `abrir` — acá sí importa el orden (regla 5 de CLAUDE.md,
    // orden causal explícito), así que se fuerza FIFO con `asyncExpand` en
    // vez de sumar la dependencia `bloc_concurrency` para un solo uso.
    on<SesionEvento>(
      _alRecibirEvento,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final SesionRepository _sesionRepositorio;
  final PersonaOperativaStore _personaOperativaStore;
  final String _trabajoUuidCliente;

  Future<void> _alRecibirEvento(
    SesionEvento evento,
    Emitter<SesionEstado> emit,
  ) => switch (evento) {
    SesionAbrirSolicitada() => _alAbrirSolicitada(evento, emit),
    SesionCerrarSolicitada() => _alCerrarSolicitada(evento, emit),
  };

  /// Abre una sesión de vuelo (HU-05, Etapa 3) — valida que el piloto
  /// (persona operativa) esté asignado al usuario ANTES de escribir nada en
  /// la base (regla: precondición previa, no error del repositorio). Emite
  /// abriendo → activa, o directo a error si el persona_id es null.
  Future<void> _alAbrirSolicitada(
    SesionAbrirSolicitada evento,
    Emitter<SesionEstado> emit,
  ) async {
    emit(const SesionAbriendo());

    final pilotoId = await _personaOperativaStore.leerPersonaId();
    if (pilotoId == null) {
      emit(
        const SesionError(
          'Tu usuario no tiene una persona operativa asignada — '
          'no se puede abrir sesión. Contactá a Agrocom.',
        ),
      );
      return;
    }

    try {
      final sesion = await _sesionRepositorio.abrirSesion(
        trabajoUuidCliente: _trabajoUuidCliente,
        pilotoId: pilotoId,
        hectareasDeclaradas: evento.hectareasDeclaradas,
        inicio: DateTime.now(),
      );
      emit(SesionActiva(sesion));
    } on TrabajoInexistenteExcepcion catch (e) {
      emit(
        SesionError(
          'El trabajo ya no existe localmente: ${e.trabajoUuidCliente}. '
          'Recargá la pantalla.',
        ),
      );
    } catch (e) {
      emit(SesionError('Error al abrir sesión: ${e.toString()}'));
    }
  }

  /// Cierra una sesión de vuelo — solo tiene sentido si hay sesión activa
  /// (el estado actual es SesionActiva). Si no, es responsabilidad de la
  /// pantalla validar esto; acá no se agrega una precondición porque el flujo
  /// UI garantiza que el botón de cierre no existe sin sesión activa.
  Future<void> _alCerrarSolicitada(
    SesionCerrarSolicitada evento,
    Emitter<SesionEstado> emit,
  ) async {
    final estadoActual = state;
    if (estadoActual is! SesionActiva) {
      emit(
        const SesionError(
          'No hay sesión abierta para cerrar. Estado actual inválido.',
        ),
      );
      return;
    }

    emit(const SesionCerrando());

    try {
      final sesionCerrada = await _sesionRepositorio.cerrarSesion(
        sesionUuidCliente: estadoActual.sesion.uuidCliente,
        fin: DateTime.now(),
        motivoCierre: evento.motivoCierre,
        hectareasDeclaradas: evento.hectareasDeclaradas,
        litrosConsumidos: evento.litrosConsumidos,
      );
      emit(SesionCerrada(sesionCerrada));
    } catch (e) {
      emit(SesionError('Error al cerrar sesión: ${e.toString()}'));
    }
  }
}
