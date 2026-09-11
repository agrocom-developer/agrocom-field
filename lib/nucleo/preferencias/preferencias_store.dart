import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../flavor.dart';

/// Preferencias de UI (tema, idioma, último flavor usado) — TE-16 del plan
/// de sprints (Sprint 15). Deliberadamente ajeno a `drift`/`OutboxRepository`:
/// ninguna preferencia de UI compite con datos de sync. Si algo acá empezara
/// a necesitar sincronizarse, ya no es una preferencia de UI y no va en este
/// store.
abstract class PreferenciasStore {
  Future<ThemeMode> leerTema();
  Future<void> guardarTema(ThemeMode tema);

  Future<String?> leerIdioma();
  Future<void> guardarIdioma(String? idioma);

  Future<Flavor?> leerUltimoFlavor();
  Future<void> guardarUltimoFlavor(Flavor flavor);
}

class PreferenciasStoreLocal implements PreferenciasStore {
  PreferenciasStoreLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencias;

  static const _claveTema = 'preferencias_tema';
  static const _claveIdioma = 'preferencias_idioma';
  static const _claveUltimoFlavor = 'preferencias_ultimo_flavor';

  @override
  Future<ThemeMode> leerTema() async {
    final prefs = await _preferencias;
    final valor = prefs.getString(_claveTema);
    return ThemeMode.values.asNameMap()[valor] ?? ThemeMode.system;
  }

  @override
  Future<void> guardarTema(ThemeMode tema) async {
    final prefs = await _preferencias;
    await prefs.setString(_claveTema, tema.name);
  }

  @override
  Future<String?> leerIdioma() async {
    final prefs = await _preferencias;
    return prefs.getString(_claveIdioma);
  }

  @override
  Future<void> guardarIdioma(String? idioma) async {
    final prefs = await _preferencias;
    if (idioma == null) {
      await prefs.remove(_claveIdioma);
    } else {
      await prefs.setString(_claveIdioma, idioma);
    }
  }

  @override
  Future<Flavor?> leerUltimoFlavor() async {
    final prefs = await _preferencias;
    final valor = prefs.getString(_claveUltimoFlavor);
    return Flavor.values.asNameMap()[valor];
  }

  @override
  Future<void> guardarUltimoFlavor(Flavor flavor) async {
    final prefs = await _preferencias;
    await prefs.setString(_claveUltimoFlavor, flavor.name);
  }
}
