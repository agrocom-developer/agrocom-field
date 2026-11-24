import '../dominio/dominio.dart';

/// Recorrido de vuelo ficticio sobre un lote: pasadas paralelas de este a
/// oeste y de oeste a este (boustrophedon) dentro de la caja envolvente del
/// polígono. Solo para la demo del seguimiento y del servicio asignado.
class RecorridoDemo {
  RecorridoDemo._(this.puntos);

  factory RecorridoDemo.paraLote(Lote lote, {int pasadas = 12}) {
    final lats = lote.poligono.map((p) => p.latitud);
    final lngs = lote.poligono.map((p) => p.longitud);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    // Margen para que las pasadas queden dentro del polígono irregular.
    final mLat = (maxLat - minLat) * 0.06;
    final mLng = (maxLng - minLng) * 0.06;
    final puntos = <GeoPunto>[];
    for (var i = 0; i < pasadas; i++) {
      final f = pasadas == 1 ? 0.5 : i / (pasadas - 1);
      final lat = minLat + mLat + (maxLat - minLat - 2 * mLat) * f;
      final izquierdaADerecha = i.isEven;
      final a = GeoPunto(lat, minLng + mLng);
      final b = GeoPunto(lat, maxLng - mLng);
      puntos
        ..add(izquierdaADerecha ? a : b)
        ..add(izquierdaADerecha ? b : a);
    }
    return RecorridoDemo._(puntos);
  }

  final List<GeoPunto> puntos;

  /// Posición a lo largo del recorrido para un avance de 0 a 1.
  GeoPunto en(double avance) {
    final t = avance.clamp(0.0, 1.0) * (puntos.length - 1);
    final i = t.floor();
    if (i >= puntos.length - 1) return puntos.last;
    final f = t - i;
    final a = puntos[i];
    final b = puntos[i + 1];
    return GeoPunto(
      a.latitud + (b.latitud - a.latitud) * f,
      a.longitud + (b.longitud - a.longitud) * f,
    );
  }

  /// Puntos ya recorridos hasta [avance], incluida la posición actual.
  List<GeoPunto> trazadoHasta(double avance) {
    final t = avance.clamp(0.0, 1.0) * (puntos.length - 1);
    final i = t.floor();
    return [...puntos.take(i + 1), en(avance)];
  }
}
