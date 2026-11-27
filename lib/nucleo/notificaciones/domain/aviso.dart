import 'canal_aviso.dart';

/// Un aviso de la cuenta, tal como lo entrega `GET /api/notificaciones`. El
/// texto llega ya armado en español.
class Aviso {
  const Aviso({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.recursoTipo,
    required this.recursoId,
    required this.leida,
    required this.creadaEn,
  });

  final int id;
  final String tipo;
  final String titulo;

  /// Qué recurso abre el aviso (`solicitud`, `oferta`, `proveedor`...).
  final String recursoTipo;
  final int recursoId;
  final bool leida;
  final DateTime creadaEn;

  CanalAviso get canal => CanalAviso.deTipo(tipo);

  Aviso comoLeida() => Aviso(
    id: id,
    tipo: tipo,
    titulo: titulo,
    recursoTipo: recursoTipo,
    recursoId: recursoId,
    leida: true,
    creadaEn: creadaEn,
  );

  /// Lee un aviso del JSON del servidor; `null` si le falta lo esencial.
  static Aviso? deJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final creada = DateTime.tryParse('${json['creada_en']}');
    if (id is! int || creada == null) return null;
    return Aviso(
      id: id,
      tipo: '${json['tipo']}',
      titulo: '${json['titulo'] ?? ''}',
      recursoTipo: '${json['recurso_tipo'] ?? ''}',
      recursoId: (json['recurso_id'] as num?)?.toInt() ?? 0,
      leida: json['leida'] == true,
      creadaEn: creada,
    );
  }
}

/// Lo que devuelve la bandeja: los avisos más recientes (los no leídos
/// primero) y cuántos hay pendientes en total, aunque no entren en la lista.
class Bandeja {
  const Bandeja({this.avisos = const [], this.noLeidas = 0});

  final List<Aviso> avisos;
  final int noLeidas;

  List<Aviso> delCanal(CanalAviso? canal) => canal == null
      ? avisos
      : [
          for (final a in avisos)
            if (a.canal == canal) a,
        ];

  int noLeidasDelCanal(CanalAviso canal) =>
      avisos.where((a) => !a.leida && a.canal == canal).length;

  Bandeja conLeida(int id) {
    final marcado = [
      for (final a in avisos) a.id == id && !a.leida ? a.comoLeida() : a,
    ];
    final cambio = avisos.any((a) => a.id == id && !a.leida);
    return Bandeja(
      avisos: marcado,
      noLeidas: cambio && noLeidas > 0 ? noLeidas - 1 : noLeidas,
    );
  }

  static Bandeja deJson(Map<String, dynamic> json) {
    final datos = json['data'];
    final avisos = <Aviso>[
      if (datos is List)
        for (final d in datos) ?Aviso.deJson(d),
    ];
    return Bandeja(
      avisos: avisos,
      noLeidas:
          (json['no_leidas'] as num?)?.toInt() ??
          avisos.where((a) => !a.leida).length,
    );
  }
}

/// Lectura de los avisos propios y marca de leído. Requiere red: la bandeja
/// vive en el servidor.
abstract interface class BandejaRepositorio {
  Future<Bandeja> leer();

  Future<void> marcarLeida(int id);
}
