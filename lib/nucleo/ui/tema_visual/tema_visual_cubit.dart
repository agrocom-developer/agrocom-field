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

/// El tema que eligió la persona (Claro o Oscuro). `null` es «sin
/// elegir»: los dos flavors arrancan en claro.
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

  /// Con [elegido] nulo se usa [predeterminado]; el tema es siempre el
  /// mismo para `theme` y `darkTheme`: no se sigue el modo oscuro del sistema.
  factory ConfiguracionTema.de({
    required ModoVisualCampo? elegido,
    required ModoVisualCampo predeterminado,
  }) {
    final tema = AgrocomThemeCampo.construir(modo: elegido ?? predeterminado);
    return ConfiguracionTema(claro: tema, oscuro: tema, modo: ThemeMode.light);
  }
}
