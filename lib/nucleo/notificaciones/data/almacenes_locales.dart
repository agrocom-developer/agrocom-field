import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferencias_canales.dart';
import '../domain/presentador_avisos.dart';

/// Preferencias de canal en `shared_preferences`: son del aparato, no
/// compiten con los datos de sync ni son sensibles.
class PreferenciasCanalesLocal implements PreferenciasCanalesStore {
  PreferenciasCanalesLocal([Future<SharedPreferences>? preferencias])
    : _inyectadas = preferencias;

  final Future<SharedPreferences>? _inyectadas;

  /// Se abre al primer uso, no al construir: así crear las dependencias no
  /// exige que el motor de la plataforma esté listo.
  Future<SharedPreferences> get _preferencias =>
      _inyectadas ?? SharedPreferences.getInstance();
  static const _clave = 'avisos_preferencias_canales';

  @override
  Future<PreferenciasCanales> leer() async {
    final texto = (await _preferencias).getString(_clave);
    if (texto == null) return const PreferenciasCanales();
    try {
      return PreferenciasCanales.deJson(jsonDecode(texto));
    } on FormatException {
      return const PreferenciasCanales();
    }
  }

  @override
  Future<void> guardar(PreferenciasCanales preferencias) async {
    await (await _preferencias).setString(
      _clave,
      jsonEncode(preferencias.aJson()),
    );
  }
}

/// Los avisos ya presentados, para no repetir una notificación.
class AvisosPresentadosLocal implements AvisosPresentadosStore {
  AvisosPresentadosLocal([Future<SharedPreferences>? preferencias])
    : _inyectadas = preferencias;

  final Future<SharedPreferences>? _inyectadas;

  /// Se abre al primer uso, igual que en [PreferenciasCanalesLocal].
  Future<SharedPreferences> get _preferencias =>
      _inyectadas ?? SharedPreferences.getInstance();
  static const _clave = 'avisos_presentados';

  @override
  Future<Set<int>?> leer() async {
    final lista = (await _preferencias).getStringList(_clave);
    return lista == null ? null : {for (final s in lista) ?int.tryParse(s)};
  }

  @override
  Future<void> guardar(Set<int> ids) async {
    await (await _preferencias).setStringList(_clave, [
      for (final id in ids) '$id',
    ]);
  }
}
