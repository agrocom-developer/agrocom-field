import 'canal_aviso.dart';

/// Cómo presenta este teléfono los avisos de un canal: encendido o
/// silenciado y, si quiere, un horario de silencio. Es una preferencia del
/// aparato (qué suena y cuándo); lo que el servidor avisa o no lo deciden las
/// preferencias de `PUT /api/notificaciones/preferencias`.
class PreferenciaCanal {
  const PreferenciaCanal({
    this.activo = true,
    this.silencioDesde,
    this.silencioHasta,
  });

  final bool activo;

  /// Minutos desde la medianoche en que empieza el silencio; `null` sin
  /// horario.
  final int? silencioDesde;

  /// Minutos desde la medianoche en que termina el silencio.
  final int? silencioHasta;

  bool get tieneHorario => silencioDesde != null && silencioHasta != null;

  /// ¿[ahora] cae dentro del horario de silencio? Admite el cruce de
  /// medianoche (22:00 a 06:00).
  bool enSilencio(DateTime ahora) {
    if (!tieneHorario) return false;
    final minuto = ahora.hour * 60 + ahora.minute;
    final desde = silencioDesde!;
    final hasta = silencioHasta!;
    if (desde == hasta) return false;
    return desde < hasta
        ? minuto >= desde && minuto < hasta
        : minuto >= desde || minuto < hasta;
  }

  PreferenciaCanal copiarCon({
    bool? activo,
    int? Function()? silencioDesde,
    int? Function()? silencioHasta,
  }) => PreferenciaCanal(
    activo: activo ?? this.activo,
    silencioDesde: silencioDesde != null ? silencioDesde() : this.silencioDesde,
    silencioHasta: silencioHasta != null ? silencioHasta() : this.silencioHasta,
  );

  Map<String, Object?> aJson() => {
    'activo': activo,
    'silencio_desde': silencioDesde,
    'silencio_hasta': silencioHasta,
  };

  static PreferenciaCanal deJson(Object? json) {
    if (json is! Map) return const PreferenciaCanal();
    return PreferenciaCanal(
      activo: json['activo'] != false,
      silencioDesde: (json['silencio_desde'] as num?)?.toInt(),
      silencioHasta: (json['silencio_hasta'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PreferenciaCanal &&
      other.activo == activo &&
      other.silencioDesde == silencioDesde &&
      other.silencioHasta == silencioHasta;

  @override
  int get hashCode => Object.hash(activo, silencioDesde, silencioHasta);
}

/// Las preferencias de todos los canales de este teléfono.
class PreferenciasCanales {
  const PreferenciasCanales([this._porCanal = const {}]);

  final Map<CanalAviso, PreferenciaCanal> _porCanal;

  PreferenciaCanal de(CanalAviso canal) => canal.obligatorio
      ? const PreferenciaCanal()
      : _porCanal[canal] ?? const PreferenciaCanal();

  /// ¿Se presenta ahora un aviso de [canal] en este teléfono? Un canal
  /// obligatorio siempre se presenta.
  bool permite(CanalAviso canal, DateTime ahora) {
    if (canal.obligatorio) return true;
    final p = de(canal);
    return p.activo && !p.enSilencio(ahora);
  }

  PreferenciasCanales con(CanalAviso canal, PreferenciaCanal preferencia) =>
      PreferenciasCanales({..._porCanal, canal: preferencia});

  Map<String, Object?> aJson() => {
    for (final e in _porCanal.entries) e.key.codigo: e.value.aJson(),
  };

  static PreferenciasCanales deJson(Object? json) {
    if (json is! Map) return const PreferenciasCanales();
    return PreferenciasCanales({
      for (final e in json.entries)
        ?CanalAviso.deCodigo('${e.key}'): PreferenciaCanal.deJson(e.value),
    });
  }
}

/// Dónde se guardan las preferencias de canal del aparato.
abstract interface class PreferenciasCanalesStore {
  Future<PreferenciasCanales> leer();

  Future<void> guardar(PreferenciasCanales preferencias);
}

class PreferenciasCanalesMemoria implements PreferenciasCanalesStore {
  PreferenciasCanales _valor = const PreferenciasCanales();

  @override
  Future<PreferenciasCanales> leer() async => _valor;

  @override
  Future<void> guardar(PreferenciasCanales preferencias) async =>
      _valor = preferencias;
}
