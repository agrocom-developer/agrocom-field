import '../domain/aviso.dart';

/// Los avisos propios contra la API (`GET /api/notificaciones` y
/// `POST /api/notificaciones/{id}/leida`). Recibe las dos llamadas como
/// funciones para servir a los dos flavors, cada uno con su puerta HTTP.
class BandejaRed implements BandejaRepositorio {
  BandejaRed({
    required Future<Map<String, dynamic>> Function(String ruta) obtener,
    required Future<Map<String, dynamic>> Function(String ruta) enviar,
  }) : _obtener = obtener,
       _enviar = enviar;

  final Future<Map<String, dynamic>> Function(String ruta) _obtener;
  final Future<Map<String, dynamic>> Function(String ruta) _enviar;

  @override
  Future<Bandeja> leer() async =>
      Bandeja.deJson(await _obtener('/api/notificaciones'));

  @override
  Future<void> marcarLeida(int id) async {
    await _enviar('/api/notificaciones/$id/leida');
  }
}

/// Bandeja en memoria para el modo demo y las pruebas.
class BandejaDemo implements BandejaRepositorio {
  BandejaDemo(List<Aviso> avisos) : _avisos = [...avisos];

  final List<Aviso> _avisos;

  @override
  Future<Bandeja> leer() async => Bandeja(
    avisos: List.unmodifiable(_avisos),
    noLeidas: _avisos.where((a) => !a.leida).length,
  );

  @override
  Future<void> marcarLeida(int id) async {
    final i = _avisos.indexWhere((a) => a.id == id);
    if (i >= 0) _avisos[i] = _avisos[i].comoLeida();
  }
}
