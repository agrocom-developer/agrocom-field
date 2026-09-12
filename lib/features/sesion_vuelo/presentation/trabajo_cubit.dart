import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:decimal/decimal.dart';

import '../../../nucleo/camara/selector_foto.dart';
import '../../../nucleo/evidencias/evidencia_repository.dart';
import '../data/trabajo_repository.dart';
import '../../../features/ordenes/domain/orden_vigente.dart';
import 'trabajo_estado.dart';

/// Adaptador delgado entre `TrabajoRepository` (sin BLoC) y las pantallas de
/// apertura/cierre de trabajo — traduce cada invocación async a un
/// `TrabajoEstado`.
class TrabajoCubit extends Cubit<TrabajoEstado> {
  TrabajoCubit(
    this._repositorio, {
    required EvidenciaRepository evidenciaRepositorio,
    required SelectorFoto selectorFoto,
  }) : _evidenciaRepositorio = evidenciaRepositorio,
       _selectorFoto = selectorFoto,
       super(const TrabajoInicial());

  final TrabajoRepository _repositorio;
  final EvidenciaRepository _evidenciaRepositorio;
  final SelectorFoto _selectorFoto;

  /// Abre un trabajo basado en una orden vigente (HU-05, Etapa 3) — emite
  /// cargando y luego exitoso o error. [orden] contiene `id`, `loteId`,
  /// `nroAplicacion` que se necesitan; la pantalla lo tiene completo porque
  /// viene de `OrdenDetallePantalla`.
  ///
  /// No pasa `hectareasDeclaradas`: ese campo es lo que el piloto CUBRIÓ, no
  /// la superficie del lote (`orden.loteHectareas`) — a la apertura el
  /// piloto todavía no sabe cuánto va a cubrir (mismo criterio que
  /// `AperturaSesion.hectareasDeclaradas` del lado servidor), así que se deja
  /// en el default `'0'` de `TrabajoRepository.abrirTrabajo`.
  Future<void> abrir({required OrdenVigente orden}) async {
    emit(const TrabajoCargando());
    try {
      final trabajo = await _repositorio.abrirTrabajo(
        ordenId: orden.id,
        loteId: orden.loteId,
        nroAplicacion: orden.nroAplicacion,
        inicio: DateTime.now(),
      );
      emit(TrabajoExitoso(trabajo));
    } catch (e) {
      emit(TrabajoError('Error al abrir trabajo: ${e.toString()}'));
    }
  }

  /// Passthrough a [SelectorFoto] — mismo criterio que
  /// `IncidenciaCubit.tomarFoto`: NO cambia el estado del Cubit, la foto es
  /// un dato de FORMULARIO hasta que el piloto confirma el cierre con
  /// [cerrar]. Devuelve `null` si el piloto cancela la captura.
  Future<Uint8List?> tomarFotoCampo() => _selectorFoto.tomarFoto();

  /// Cierra un trabajo (HU-09) — [bytesFoto] YA es obligatoria acá: la
  /// pantalla bloquea el botón de envío mientras no haya foto, así que este
  /// método no vuelve a validar esa precondición de UI. Captura la evidencia
  /// (`tipo: 'imagen_campo'`) ANTES de llamar a
  /// `TrabajoRepository.cerrarTrabajo`, mismo orden que pide el prompt de
  /// esta tarea: la captura vive en la capa de presentación/bloc, el
  /// repositorio recibe el `uuid_cliente` ya persistido.
  Future<void> cerrar({
    required String trabajoUuidCliente,
    Decimal? litrosSobrante,
    required Uint8List bytesFoto,
  }) async {
    emit(const TrabajoCerrando());
    try {
      final evidenciaImagenCampoUuidCliente = await _evidenciaRepositorio
          .capturarEvidencia(
            bytesOriginales: bytesFoto,
            tipo: 'imagen_campo',
            fecha: DateTime.now(),
          );
      final trabajo = await _repositorio.cerrarTrabajo(
        trabajoUuidCliente: trabajoUuidCliente,
        fin: DateTime.now(),
        litrosSobrante: litrosSobrante,
        evidenciaImagenCampoUuidCliente: evidenciaImagenCampoUuidCliente,
      );
      emit(TrabajoCerrado(trabajo));
    } catch (e) {
      emit(TrabajoError('Error al cerrar trabajo: ${e.toString()}'));
    }
  }
}
