import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../paleta_campo.dart';
import '../tema_campo.dart';

/// Dónde se guarda el tema elegido. Es una preferencia de interfaz: no es un
/// secreto ni compite con los datos de sincronización (ver
/// `PreferenciasStore`), así que vive en `shared_preferences`.
abstract interface class AlmacenTemaVisual {
  /// El tema elegido, o `null` si la persona nunca eligió uno.
  Future<ModoVisualCampo?> leer();

  Future<void> guardar(ModoVisualCampo modo);
}

class AlmacenTemaVisualLocal implements AlmacenTemaVisual {
  AlmacenTemaVisualLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias;

  final Future<SharedPreferences>? _preferencias;

  static const _clave = 'tema_visual';

  Future<SharedPreferences> get _prefs =>
      _preferencias ?? SharedPreferences.getInstance();

  @override
  Future<ModoVisualCampo?> leer() async {
    final valor = (await _prefs).getString(_clave);
    return ModoVisualCampo.values.asNameMap()[valor];
  }

  @override
  Future<void> guardar(ModoVisualCampo modo) async {
    await (await _prefs).setString(_clave, modo.name);
  }
}

/// Almacén en memoria para la demo y las pruebas.
class AlmacenTemaVisualMemoria implements AlmacenTemaVisual {
  AlmacenTemaVisualMemoria([this.modo]);

  ModoVisualCampo? modo;

  @override
  Future<ModoVisualCampo?> leer() async => modo;

  @override
  Future<void> guardar(ModoVisualCampo nuevo) async => modo = nuevo;
}

/// El tema que eligió la persona (Claro, Oscuro o Campo AAA). `null` es «sin
/// elegir»: cada flavor aplica su predeterminado (el cliente sigue al
/// sistema; el piloto usa el modo campo).
class TemaVisualCubit extends Cubit<ModoVisualCampo?> {
  TemaVisualCubit(this._almacen) : super(null);

  final AlmacenTemaVisual _almacen;

  Future<void> cargar() async {
    try {
      final guardado = await _almacen.leer();
      if (!isClosed && guardado != null) emit(guardado);
    } on Object {
      // Sin preferencia legible, se queda el tema predeterminado.
    }
  }

  Future<void> elegir(ModoVisualCampo modo) async {
    emit(modo);
    try {
      await _almacen.guardar(modo);
    } on Object {
      // El tema ya cambió en pantalla; si no se pudo guardar, vuelve a
      // preguntarse la próxima vez.
    }
  }
}

/// Lo que recibe `MaterialApp` para un tema elegido.
class ConfiguracionTema {
  const ConfiguracionTema({
    required this.claro,
    required this.oscuro,
    required this.modo,
  });

  final ThemeData claro;
  final ThemeData oscuro;
  final ThemeMode modo;

  /// Con [elegido] nulo se usa [predeterminado]: `claro` sigue al sistema
  /// (claro u oscuro); `oscuro` y `campo` fijan ese tema.
  factory ConfiguracionTema.de({
    required ModoVisualCampo? elegido,
    required ModoVisualCampo predeterminado,
  }) {
    final modo = elegido ?? predeterminado;
    if (elegido == null && predeterminado == ModoVisualCampo.claro) {
      return ConfiguracionTema(
        claro: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        oscuro: AgrocomThemeCampo.construir(modo: ModoVisualCampo.oscuro),
        modo: ThemeMode.system,
      );
    }
    final tema = AgrocomThemeCampo.construir(modo: modo);
    return ConfiguracionTema(claro: tema, oscuro: tema, modo: ThemeMode.light);
  }
}
