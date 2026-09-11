import 'package:shared_preferences/shared_preferences.dart';

/// Ids de `OrdenCatalogo` ya notificados por `avisos_locales` — estado
/// propio de esta feature, deliberadamente distinto de
/// `PreferenciasStore` (TE-16, solo tema/idioma/último flavor). Ninguna
/// preferencia de UI compite con "qué ya se avisó"; si un día
/// `PreferenciasStore` empezara a guardar esto, dejaría de ser una
/// preferencia de UI.
abstract class IdsVistosStore {
  Future<Set<int>> leerVistos();
  Future<void> guardarVistos(Set<int> ids);
}

class IdsVistosStoreLocal implements IdsVistosStore {
  IdsVistosStoreLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencias;
  static const _clave = 'avisos_locales_ids_vistos';

  @override
  Future<Set<int>> leerVistos() async {
    final prefs = await _preferencias;
    final valores = prefs.getStringList(_clave) ?? const <String>[];
    return valores.map(int.parse).toSet();
  }

  @override
  Future<void> guardarVistos(Set<int> ids) async {
    final prefs = await _preferencias;
    await prefs.setStringList(_clave, ids.map((id) => id.toString()).toList());
  }
}
