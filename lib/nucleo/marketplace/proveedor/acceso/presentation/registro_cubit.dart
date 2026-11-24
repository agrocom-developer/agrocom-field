import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../camara/selector_imagen.dart';
import '../../../../evidencias/compresor_adaptativo.dart';
import '../../../../evidencias/compresor_evidencia.dart';
import '../../../dominio/falla.dart';
import '../domain/acceso_proveedor.dart';

/// En qué paso del alta se quedó el envío.
enum PasoRegistro { cuenta, sesion, dron, fotos, listo }

class RegistroEstado {
  const RegistroEstado({
    this.fotos = const {},
    this.enviando = false,
    this.paso = PasoRegistro.cuenta,
    this.mensaje,
    this.erroresPorCampo = const {},
    this.fotoCargando,
    this.fotoError,
  });

  /// Fotos elegidas, ya comprimidas a menos de 300 KB, por tipo.
  final Map<TipoFotoDron, Uint8List> fotos;
  final bool enviando;

  /// El próximo paso a hacer: si el envío falla a medias, se retoma ahí y no
  /// se vuelve a crear lo que ya se creó.
  final PasoRegistro paso;
  final String? mensaje;
  final Map<String, String> erroresPorCampo;
  final TipoFotoDron? fotoCargando;
  final String? fotoError;

  bool get fotosObligatoriasListas => TipoFotoDron.values
      .where((t) => t.obligatoria)
      .every((t) => fotos.containsKey(t));

  bool get terminado => paso == PasoRegistro.listo;

  RegistroEstado copiarCon({
    Map<TipoFotoDron, Uint8List>? fotos,
    bool? enviando,
    PasoRegistro? paso,
    String? Function()? mensaje,
    Map<String, String>? erroresPorCampo,
    TipoFotoDron? Function()? fotoCargando,
    String? Function()? fotoError,
  }) => RegistroEstado(
    fotos: fotos ?? this.fotos,
    enviando: enviando ?? this.enviando,
    paso: paso ?? this.paso,
    mensaje: mensaje != null ? mensaje() : this.mensaje,
    erroresPorCampo: erroresPorCampo ?? this.erroresPorCampo,
    fotoCargando: fotoCargando != null ? fotoCargando() : this.fotoCargando,
    fotoError: fotoError != null ? fotoError() : this.fotoError,
  );
}

/// El alta del proveedor independiente: cuenta → sesión → dron → fotos del
/// dron. Cada paso se hace una sola vez: si la red se corta en el tercero,
/// reintentar retoma desde ahí y no crea la cuenta ni el dron dos veces.
/// Termina con el proveedor `pendiente` de aprobación de un administrador.
class RegistroCubit extends Cubit<RegistroEstado> {
  RegistroCubit({
    required AccesoProveedorRepositorio acceso,
    required RegistroDronesRepositorio drones,
    required SelectorImagen selector,
    CompresorEvidencia? compresor,
  }) : _acceso = acceso,
       _drones = drones,
       _selector = selector,
       _compresor = compresor ?? CompresorEvidenciaAdaptativo(),
       super(const RegistroEstado());

  final AccesoProveedorRepositorio _acceso;
  final RegistroDronesRepositorio _drones;
  final SelectorImagen _selector;
  final CompresorEvidencia _compresor;

  int? _dronId;
  final _subidas = <TipoFotoDron>{};

  /// Elige o toma una foto, la comprime y la deja lista para enviar.
  Future<void> elegirFoto(TipoFotoDron tipo, {required bool deGaleria}) async {
    if (state.fotoCargando != null) return;
    final original = deGaleria
        ? await _selector.elegirDeGaleria()
        : await _selector.tomarFoto();
    if (original == null) return;
    emit(state.copiarCon(fotoCargando: () => tipo, fotoError: () => null));
    try {
      final comprimida = await _compresor.comprimir(original);
      emit(
        state.copiarCon(
          fotos: {...state.fotos, tipo: comprimida},
          fotoCargando: () => null,
        ),
      );
    } on Object {
      emit(
        state.copiarCon(
          fotoCargando: () => null,
          fotoError: () =>
              'No pudimos achicar esa foto. Prueba con otra o tómala de '
              'nuevo.',
        ),
      );
    }
  }

  void quitarFoto(TipoFotoDron tipo) {
    final fotos = {...state.fotos}..remove(tipo);
    emit(state.copiarCon(fotos: fotos));
  }

  Future<void> enviar(DatosPersona persona, DatosDron dron) async {
    if (state.enviando || state.terminado) return;
    emit(
      state.copiarCon(
        enviando: true,
        mensaje: () => null,
        erroresPorCampo: const {},
      ),
    );
    try {
      if (state.paso == PasoRegistro.cuenta) {
        await _acceso.registrar(persona);
        emit(state.copiarCon(paso: PasoRegistro.sesion));
      }
      if (state.paso == PasoRegistro.sesion) {
        await _acceso.iniciarSesion(
          usuario: persona.usuario,
          contrasena: persona.contrasena,
        );
        emit(state.copiarCon(paso: PasoRegistro.dron));
      }
      if (state.paso == PasoRegistro.dron) {
        _dronId = await _drones.registrarDron(dron);
        emit(state.copiarCon(paso: PasoRegistro.fotos));
      }
      if (state.paso == PasoRegistro.fotos) {
        for (final e in state.fotos.entries) {
          if (_subidas.contains(e.key)) continue;
          await _drones.subirFoto(_dronId!, FotoDronLista(e.key, e.value));
          _subidas.add(e.key);
        }
        emit(state.copiarCon(paso: PasoRegistro.listo));
      }
      emit(state.copiarCon(enviando: false));
    } on AccesoProveedorExcepcion catch (e) {
      emit(
        state.copiarCon(
          enviando: false,
          mensaje: () => _mensajeAcceso(e),
          erroresPorCampo: e.porCampo,
        ),
      );
    } on SinConexion {
      emit(
        state.copiarCon(
          enviando: false,
          mensaje: () =>
              'Sin conexión. Lo que escribiste se conserva: reintenta con '
              'señal y seguimos donde quedó.',
        ),
      );
    } on OperacionRechazada catch (e) {
      emit(state.copiarCon(enviando: false, mensaje: () => e.mensaje));
    }
  }

  static String _mensajeAcceso(AccesoProveedorExcepcion e) =>
      switch (e.motivo) {
        MotivoFalloAcceso.sinConexion =>
          'Sin conexión. Lo que escribiste se conserva: reintenta con señal.',
        MotivoFalloAcceso.credencialesInvalidas =>
          'Tu cuenta quedó creada, pero no pudimos entrar. Vuelve al ingreso '
              'e inicia sesión.',
        MotivoFalloAcceso.validacion =>
          e.mensaje ?? 'Revisa los datos marcados e intenta de nuevo.',
        _ => e.mensaje ?? 'No pudimos completar el registro. Intenta de nuevo.',
      };
}
