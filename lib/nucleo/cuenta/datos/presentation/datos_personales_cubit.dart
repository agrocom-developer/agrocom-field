import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/dominio/falla.dart';
import '../domain/datos_personales.dart';
import '../domain/datos_personales_repositorio.dart';

enum FaseDatosPersonales { cargando, lista, guardando, error }

/// Por qué terminó la última acción, para que la pantalla muestre el aviso.
enum ResultadoDatosPersonales { guardado, edicionAgotada, falloGuardar }

class DatosPersonalesEstado {
  const DatosPersonalesEstado({
    this.fase = FaseDatosPersonales.cargando,
    this.datos,
    this.sinConexion = false,
    this.resultado,
  });

  final FaseDatosPersonales fase;
  final EstadoDatosPersonales? datos;
  final bool sinConexion;
  final ResultadoDatosPersonales? resultado;

  DatosPersonalesEstado copiarCon({
    FaseDatosPersonales? fase,
    EstadoDatosPersonales? datos,
    bool? sinConexion,
    ResultadoDatosPersonales? resultado,
    bool limpiarResultado = false,
  }) => DatosPersonalesEstado(
    fase: fase ?? this.fase,
    datos: datos ?? this.datos,
    sinConexion: sinConexion ?? this.sinConexion,
    resultado: limpiarResultado ? null : (resultado ?? this.resultado),
  );
}

/// Carga los datos personales y gasta la única edición. Todo va en línea:
/// un fallo deja los datos anteriores y permite reintentar.
class DatosPersonalesCubit extends Cubit<DatosPersonalesEstado> {
  DatosPersonalesCubit(this._repositorio)
    : super(const DatosPersonalesEstado());

  final DatosPersonalesRepositorio _repositorio;

  Future<void> cargar() async {
    emit(
      state.copiarCon(
        fase: FaseDatosPersonales.cargando,
        limpiarResultado: true,
      ),
    );
    try {
      final datos = await _repositorio.cargar();
      if (isClosed) return;
      emit(
        DatosPersonalesEstado(fase: FaseDatosPersonales.lista, datos: datos),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        DatosPersonalesEstado(
          fase: FaseDatosPersonales.error,
          sinConexion: e is SinConexion,
        ),
      );
    }
  }

  Future<void> guardar(DatosPersonales nuevos) async {
    emit(
      state.copiarCon(
        fase: FaseDatosPersonales.guardando,
        limpiarResultado: true,
      ),
    );
    try {
      final datos = await _repositorio.editarUnaVez(nuevos);
      if (isClosed) return;
      emit(
        DatosPersonalesEstado(
          fase: FaseDatosPersonales.lista,
          datos: datos,
          resultado: ResultadoDatosPersonales.guardado,
        ),
      );
    } on OperacionRechazada catch (e) {
      if (isClosed) return;
      if (e.codigo == 409) {
        // Otra sesión ya gastó la edición: se vuelve a leer el estado real.
        await _recargarCon(ResultadoDatosPersonales.edicionAgotada);
      } else {
        _volverALista(ResultadoDatosPersonales.falloGuardar);
      }
    } on Object catch (e) {
      if (isClosed) return;
      _volverALista(
        ResultadoDatosPersonales.falloGuardar,
        sinConexion: e is SinConexion,
      );
    }
  }

  Future<void> _recargarCon(ResultadoDatosPersonales resultado) async {
    try {
      final datos = await _repositorio.cargar();
      if (isClosed) return;
      emit(
        DatosPersonalesEstado(
          fase: FaseDatosPersonales.lista,
          datos: datos,
          resultado: resultado,
        ),
      );
    } on Object {
      if (!isClosed) _volverALista(resultado);
    }
  }

  void _volverALista(
    ResultadoDatosPersonales resultado, {
    bool sinConexion = false,
  }) => emit(
    state.copiarCon(
      fase: FaseDatosPersonales.lista,
      resultado: resultado,
      sinConexion: sinConexion,
    ),
  );

  /// Tras enviar una solicitud de cambio, se vuelve a leer para mostrarla.
  Future<void> recargar() => cargar();
}
