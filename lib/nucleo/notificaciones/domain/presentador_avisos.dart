import 'dart:async';

import '../../../l10n/app_localizations_es.dart';
import '../notificador_local.dart';
import '../presentation/textos_canal.dart';
import '../remotas/notificaciones_remotas.dart';
import 'aviso.dart';
import 'canal_aviso.dart';
import 'preferencias_canales.dart';

/// Los avisos que ya se presentaron como notificación, para no repetirlos.
abstract interface class AvisosPresentadosStore {
  /// `null` si nunca se guardó nada (primer uso).
  Future<Set<int>?> leer();

  Future<void> guardar(Set<int> ids);
}

class AvisosPresentadosMemoria implements AvisosPresentadosStore {
  Set<int>? _ids;

  @override
  Future<Set<int>?> leer() async => _ids;

  @override
  Future<void> guardar(Set<int> ids) async => _ids = {...ids};
}

/// Convierte los avisos del servidor en notificaciones del sistema, con la
/// lógica de presentación completa aunque Firebase esté apagado: sale de la
/// bandeja (`GET /api/notificaciones`) y de [NotificacionesRemotas] cuando
/// haya un proveedor de push. Respeta el canal, el silencio y el horario de
/// cada canal en este teléfono.
///
/// No calcula a quién avisar ni qué solicitudes encajan: eso lo decide el
/// servidor (ADR 0023). La primera vez solo registra lo que ya hay, para no
/// avisar de golpe de todo el historial.
class PresentadorAvisos {
  PresentadorAvisos({
    required NotificadorLocal notificador,
    required PreferenciasCanalesStore preferencias,
    required AvisosPresentadosStore presentados,
    DateTime Function()? reloj,
    this.maximoPorRevision = 3,
  }) : _notificador = notificador,
       _preferencias = preferencias,
       _presentados = presentados,
       _reloj = reloj ?? DateTime.now;

  final NotificadorLocal _notificador;
  final PreferenciasCanalesStore _preferencias;
  final AvisosPresentadosStore _presentados;
  final DateTime Function() _reloj;

  /// Más avisos que esto en una revisión se agrupan en una sola notificación.
  final int maximoPorRevision;

  static const _tope = 200;
  static const _idResumen = 7100;

  /// Presenta los avisos no leídos que todavía no se mostraron. Devuelve
  /// cuántos presentó.
  Future<int> presentar(Bandeja bandeja) async {
    final anteriores = await _presentados.leer();
    final actuales = {for (final a in bandeja.avisos) a.id};
    final guardados = {...?anteriores, ...actuales};
    await _presentados.guardar(_recortar(guardados));
    if (anteriores == null) return 0;

    final prefs = await _preferencias.leer();
    final ahora = _reloj();
    final nuevos = [
      for (final a in bandeja.avisos)
        if (!a.leida &&
            !anteriores.contains(a.id) &&
            prefs.permite(a.canal, ahora))
          a,
    ];
    if (nuevos.isEmpty) return 0;
    final textos = AppLocalizationsEs();
    if (nuevos.length > maximoPorRevision) {
      await _notificador.mostrar(
        id: _idResumen,
        titulo: textos.avisosTitulo,
        cuerpo: textos.avisosVariosNuevos(nuevos.length),
        canal: CanalAviso.cuenta,
      );
      return nuevos.length;
    }
    for (final a in nuevos) {
      await _notificador.mostrar(
        id: a.id,
        titulo: a.canal.nombre(textos),
        cuerpo: a.titulo,
        canal: a.canal,
        carga: '${a.recursoTipo}:${a.recursoId}',
      );
    }
    return nuevos.length;
  }

  /// Presenta un aviso que llegó por push con la app abierta.
  Future<void> presentarRemoto(AvisoRemoto aviso, {CanalAviso? canal}) async {
    final c = canal ?? CanalAviso.cuenta;
    final prefs = await _preferencias.leer();
    if (!prefs.permite(c, _reloj())) return;
    await _notificador.mostrar(
      id: aviso.hashCode & 0x7fffffff,
      titulo: aviso.titulo,
      cuerpo: aviso.cuerpo,
      canal: c,
      carga: aviso.solicitudId == null
          ? null
          : 'solicitud:${aviso.solicitudId}',
    );
  }

  /// Escucha los avisos del puerto de push. Con el puerto nulo, el flujo está
  /// vacío y no hace nada.
  StreamSubscription<AvisoRemoto> escuchar(NotificacionesRemotas remotas) =>
      remotas.avisos.listen((a) => unawaited(presentarRemoto(a)));

  Set<int> _recortar(Set<int> ids) {
    if (ids.length <= _tope) return ids;
    final ordenados = ids.toList()..sort();
    return ordenados.skip(ids.length - _tope).toSet();
  }
}
