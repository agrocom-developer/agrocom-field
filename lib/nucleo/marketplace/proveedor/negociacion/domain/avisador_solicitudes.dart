import 'package:shared_preferences/shared_preferences.dart';

import '../../../../notificaciones/notificador_local.dart';
import '../../../ui/formato_marketplace.dart';
import 'negociacion.dart';
import 'negociacion_repositorios.dart';

/// Las solicitudes que el piloto ya vio, para avisar solo de las nuevas.
abstract interface class SolicitudesVistasStore {
  /// `null` si nunca se guardó nada (primer uso).
  Future<Set<int>?> leer();

  Future<void> guardar(Set<int> ids);
}

class SolicitudesVistasMemoria implements SolicitudesVistasStore {
  Set<int>? _ids;

  @override
  Future<Set<int>?> leer() async => _ids;

  @override
  Future<void> guardar(Set<int> ids) async => _ids = {...ids};
}

class SolicitudesVistasLocal implements SolicitudesVistasStore {
  SolicitudesVistasLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencias;
  static const _clave = 'piloto_solicitudes_vistas';

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

/// Avisa con una notificación local cuando aparecen solicitudes nuevas en
/// las zonas que el piloto pidió seguir. Corre al abrir o refrescar el mapa:
/// no hay un servicio en segundo plano ni una cuenta de push (ADR 0016).
///
/// La primera vez solo registra lo que ya hay, para no avisar de todo el
/// mercado de golpe.
class AvisadorSolicitudesNuevas {
  AvisadorSolicitudesNuevas({
    required MercadoRepositorio mercado,
    required AvisosRepositorio avisos,
    required NotificadorLocal notificador,
    required SolicitudesVistasStore vistas,
  }) : _mercado = mercado,
       _avisos = avisos,
       _notificador = notificador,
       _vistas = vistas;

  final MercadoRepositorio _mercado;
  final AvisosRepositorio _avisos;
  final NotificadorLocal _notificador;
  final SolicitudesVistasStore _vistas;

  static const _idNotificacion = 7001;

  /// Consulta el mercado completo, avisa de lo nuevo que encaja con las
  /// preferencias y devuelve cuántas solicitudes avisó.
  Future<int> revisar() async {
    final preferencias = await _avisos.leer();
    final pagina = await _mercado.solicitudes(const FiltrosMapa());
    final actuales = {for (final s in pagina.solicitudes) s.id};
    final anteriores = await _vistas.leer();
    await _vistas.guardar(actuales);
    if (anteriores == null || !preferencias.nuevasSolicitudes) return 0;
    final nuevas = [
      for (final s in pagina.solicitudes)
        if (!anteriores.contains(s.id) && preferencias.aplicaA(s)) s,
    ];
    if (nuevas.isEmpty) return 0;
    if (nuevas.length == 1) {
      final s = nuevas.first;
      await _notificador.mostrar(
        id: _idNotificacion,
        titulo: 'Nueva solicitud en ${s.zona ?? 'tu zona'}',
        cuerpo:
            '${FormatoMarketplace.hectareas(s.hectareas)} · '
            '${FormatoMarketplace.bs(s.precioHaPropuesto)} por ha. '
            'Ábrela y ofrece tu precio.',
      );
    } else {
      final hectareas = nuevas.fold(
        nuevas.first.hectareas - nuevas.first.hectareas,
        (a, s) => a + s.hectareas,
      );
      await _notificador.mostrar(
        id: _idNotificacion,
        titulo: '${nuevas.length} solicitudes nuevas',
        cuerpo:
            '${FormatoMarketplace.hectareas(hectareas)} en total. '
            'Mira el mapa y ofrece tu precio.',
      );
    }
    return nuevas.length;
  }
}
