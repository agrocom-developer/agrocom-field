import 'dart:typed_data';

import 'package:bloc/bloc.dart';

import '../../../nucleo/camara/selector_foto.dart';
import '../data/incidencia_repository.dart';
import '../domain/reglas_incidencia.dart';
import '../domain/tipo_incidencia.dart';
import 'incidencia_estado.dart';

/// Adaptador delgado entre `IncidenciaRepository`/`SelectorFoto` y la
/// pantalla de incidencia — vive en el contexto de UNA sesión activa, cuyo
/// `uuid_cliente` se pasa al construirlo (mismo criterio que `SesionBloc`
/// con `trabajoUuidCliente`).
///
/// [tomarFoto] es un simple passthrough a [SelectorFoto] — NO cambia el
/// estado del Cubit: la foto es un dato de FORMULARIO (como el tipo o la
/// descripción), la pantalla la guarda en su propio `State` hasta que el
/// piloto confirma el envío con [registrar]. Mismo criterio que
/// `SesionVueloVista`, que tampoco delega al Bloc los campos de formulario
/// que todavía no se enviaron.
class IncidenciaCubit extends Cubit<IncidenciaEstado> {
  IncidenciaCubit({
    required IncidenciaRepository incidenciaRepositorio,
    required SelectorFoto selectorFoto,
    required String sesionUuidCliente,
  }) : _incidenciaRepositorio = incidenciaRepositorio,
       _selectorFoto = selectorFoto,
       _sesionUuidCliente = sesionUuidCliente,
       super(const IncidenciaInicial());

  final IncidenciaRepository _incidenciaRepositorio;
  final SelectorFoto _selectorFoto;
  final String _sesionUuidCliente;

  /// Devuelve `null` si el piloto cancela la captura — la pantalla decide
  /// qué hacer con eso (no tocar la foto ya elegida antes, si había una).
  Future<Uint8List?> tomarFoto() => _selectorFoto.tomarFoto();

  /// Registra la incidencia (HU-08) — [bytesFoto] YA es obligatoria acá: la
  /// pantalla bloquea el botón de envío mientras no haya foto, así que este
  /// método no vuelve a validar esa precondición de UI, solo traduce el
  /// resultado de `IncidenciaRepository.registrarIncidencia` a
  /// [IncidenciaEstado].
  Future<void> registrar({
    required TipoIncidencia tipo,
    String? descripcion,
    required Uint8List bytesFoto,
  }) async {
    emit(const IncidenciaEnviando());

    try {
      final incidencia = await _incidenciaRepositorio.registrarIncidencia(
        sesionUuidCliente: _sesionUuidCliente,
        tipo: tipo,
        descripcion: descripcion,
        hora: DateTime.now(),
        bytesFoto: bytesFoto,
      );
      emit(IncidenciaExitosa(incidencia));
    } on SesionInexistenteExcepcion {
      emit(
        const IncidenciaError(
          'La sesión ya no existe localmente. Recargá la pantalla.',
        ),
      );
    } on SesionCerradaExcepcion {
      emit(
        const IncidenciaError(
          'La sesión ya está cerrada — no se puede registrar una incidencia.',
        ),
      );
    } catch (e) {
      emit(
        IncidenciaError('Error al registrar la incidencia: ${e.toString()}'),
      );
    }
  }
}
