import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preparacion.dart';

/// La lista de preparación en `shared_preferences`: es una guía del aparato,
/// no un dato del lote, así que no pasa por `drift` ni por el outbox.
class PreparacionLocal implements PreparacionStore {
  PreparacionLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencias;

  static String _clave(int? servicioId) => servicioId == null
      ? 'preparacion_equipo'
      : 'preparacion_equipo_$servicioId';

  @override
  Future<ChecklistPreparacion> leer({int? servicioId}) async {
    final lista = (await _preferencias).getStringList(_clave(servicioId));
    return lista == null
        ? const ChecklistPreparacion()
        : ChecklistPreparacion.deJson(lista);
  }

  @override
  Future<void> guardar(ChecklistPreparacion lista, {int? servicioId}) async {
    await (await _preferencias).setStringList(
      _clave(servicioId),
      lista.aJson(),
    );
  }
}
