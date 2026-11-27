import '../../../api/marketplace_http.dart';
import '../domain/bandeja_repositorio.dart';
import '../domain/notificacion.dart';

/// Contra la API: `GET /api/notificaciones` y
/// `POST /api/notificaciones/{id}/leida`.
///
/// El contrato solo trae avisos del sistema (título ya armado, sin cuerpo ni
/// remitente), así que todos salen con [OrigenSistema]; los mensajes entre
/// cliente y piloto no llegan por aquí (ver
/// `docs/gestion/solicitud-api-bandeja-notificaciones.md`). El contrato no
/// tiene «marcar todas»: se marcan una por una las no leídas.
class BandejaRed implements BandejaRepositorio {
  BandejaRed(this._http);

  final MarketplaceHttp _http;

  List<Notificacion> _ultimas = const [];

  @override
  Future<List<Notificacion>> listar() async {
    final r = await _http.obtener('/api/notificaciones');
    final datos = r['data'];
    final lista = <Notificacion>[
      if (datos is List)
        for (final d in datos)
          if (d is Map) _aviso(Map<String, dynamic>.from(d)),
    ];
    _ultimas = lista;
    return lista;
  }

  static Notificacion _aviso(Map<String, dynamic> j) {
    final tipo = j['recurso_tipo'];
    final id = j['recurso_id'];
    return Notificacion(
      id: (j['id'] as num).toInt(),
      origen: const OrigenSistema(),
      titulo: '${j['titulo'] ?? ''}',
      fecha: DateTime.parse('${j['creada_en']}').toLocal(),
      leida: j['leida'] == true,
      destino: tipo is String && id is num
          ? DestinoNotificacion(tipo, id.toInt())
          : null,
    );
  }

  @override
  Future<void> marcarLeida(int id) async {
    await _http.enviar('/api/notificaciones/$id/leida');
  }

  @override
  Future<void> marcarTodasLeidas() async {
    for (final n in _ultimas.where((n) => !n.leida)) {
      await marcarLeida(n.id);
    }
  }
}
