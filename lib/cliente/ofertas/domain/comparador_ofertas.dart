import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/proveedor.dart';
import 'oferta_recibida.dart';

/// Cómo ordena el servidor las ofertas del comparador. `recomendado` pone
/// primero a los pilotos propios de Agrocom, luego la mayor calificación, el
/// menor precio y la oferta más antigua.
enum OrdenOfertas {
  recomendado('recomendado'),
  precio('precio'),
  calificacion('calificacion'),
  reciente('reciente');

  const OrdenOfertas(this.codigo);

  /// Valor del parámetro `orden` de la API.
  final String codigo;
}

/// Tipo de proveedor tal como lo nombra la API (`propio`, `independiente`,
/// `tercero`).
extension CodigoTipoProveedor on TipoProveedor {
  String get codigo => switch (this) {
    TipoProveedor.propioAgrocom => 'propio',
    TipoProveedor.independiente => 'independiente',
    TipoProveedor.duenoDeDrones => 'tercero',
  };

  static TipoProveedor? deCodigo(String? codigo) => switch (codigo) {
    'propio' => TipoProveedor.propioAgrocom,
    'independiente' => TipoProveedor.independiente,
    'tercero' => TipoProveedor.duenoDeDrones,
    _ => null,
  };
}

/// El orden y los filtros del comparador. Todos son opcionales y solo
/// reducen u ordenan la lista: nunca agregan datos.
class FiltrosOfertas {
  const FiltrosOfertas({
    this.orden = OrdenOfertas.recomendado,
    this.precioHaMin,
    this.precioHaMax,
    this.montoMax,
    this.calificacionMin,
    this.tipoProveedor,
    this.capacidadTanqueMin,
  });

  final OrdenOfertas orden;
  final Decimal? precioHaMin;
  final Decimal? precioHaMax;

  /// Total estimado máximo.
  final Decimal? montoMax;

  /// Calificación promedio mínima del proveedor, de 0 a 5.
  final Decimal? calificacionMin;
  final TipoProveedor? tipoProveedor;

  /// Litros mínimos del tanque del dron.
  final Decimal? capacidadTanqueMin;

  /// Cuántos filtros (sin contar el orden) están activos.
  int get activos => [
    precioHaMin,
    precioHaMax,
    montoMax,
    calificacionMin,
    tipoProveedor,
    capacidadTanqueMin,
  ].where((f) => f != null).length;

  bool get hayFiltros => activos > 0;

  /// Parámetros de consulta de `GET /api/solicitudes/{id}/ofertas`.
  Map<String, dynamic> aConsulta() => {
    'orden': orden.codigo,
    if (precioHaMin != null) 'precio_ha_min': '$precioHaMin',
    if (precioHaMax != null) 'precio_ha_max': '$precioHaMax',
    if (montoMax != null) 'monto_max': '$montoMax',
    if (calificacionMin != null) 'calificacion_min': '$calificacionMin',
    if (tipoProveedor != null) 'tipo_proveedor': tipoProveedor!.codigo,
    if (capacidadTanqueMin != null)
      'capacidad_tanque_min': '$capacidadTanqueMin',
  };

  FiltrosOfertas copiarCon({OrdenOfertas? orden}) => FiltrosOfertas(
    orden: orden ?? this.orden,
    precioHaMin: precioHaMin,
    precioHaMax: precioHaMax,
    montoMax: montoMax,
    calificacionMin: calificacionMin,
    tipoProveedor: tipoProveedor,
    capacidadTanqueMin: capacidadTanqueMin,
  );

  /// Quita los filtros y conserva el orden.
  FiltrosOfertas sinFiltros() => FiltrosOfertas(orden: orden);

  @override
  bool operator ==(Object other) =>
      other is FiltrosOfertas &&
      other.orden == orden &&
      other.precioHaMin == precioHaMin &&
      other.precioHaMax == precioHaMax &&
      other.montoMax == montoMax &&
      other.calificacionMin == calificacionMin &&
      other.tipoProveedor == tipoProveedor &&
      other.capacidadTanqueMin == capacidadTanqueMin;

  @override
  int get hashCode => Object.hash(
    orden,
    precioHaMin,
    precioHaMax,
    montoMax,
    calificacionMin,
    tipoProveedor,
    capacidadTanqueMin,
  );
}

/// Aplica el orden y los filtros del comparador en el dispositivo. Lo usa el
/// modo demo y la prueba de contrato: en producción lo hace el servidor.
abstract final class ComparadorOfertas {
  static List<OfertaRecibida> aplicar(
    Iterable<OfertaRecibida> ofertas,
    FiltrosOfertas f,
  ) {
    bool pasa(OfertaRecibida o) {
      final p = o.proveedor;
      if (f.precioHaMin != null && o.precioHa < f.precioHaMin!) return false;
      if (f.precioHaMax != null && o.precioHa > f.precioHaMax!) return false;
      if (f.montoMax != null && o.montoEstimado > f.montoMax!) return false;
      if (f.calificacionMin != null &&
          p.calificacion < f.calificacionMin!.toDouble()) {
        return false;
      }
      if (f.tipoProveedor != null && p.tipo != f.tipoProveedor) return false;
      if (f.capacidadTanqueMin != null) {
        final c = p.capacidadLitros;
        if (c == null || c < f.capacidadTanqueMin!) return false;
      }
      return true;
    }

    final lista = ofertas.where(pasa).toList();
    int vigentesPrimero(OfertaRecibida a, OfertaRecibida b) =>
        (a.estado == EstadoOferta.vigente ? 0 : 1) -
        (b.estado == EstadoOferta.vigente ? 0 : 1);
    DateTime fecha(OfertaRecibida o) =>
        o.creadaEn ?? DateTime.fromMillisecondsSinceEpoch(0);
    int porPrecio(OfertaRecibida a, OfertaRecibida b) =>
        a.precioHa.compareTo(b.precioHa);
    int porCalificacion(OfertaRecibida a, OfertaRecibida b) =>
        b.proveedor.calificacion.compareTo(a.proveedor.calificacion);

    lista.sort((a, b) {
      final v = vigentesPrimero(a, b);
      if (v != 0) return v;
      switch (f.orden) {
        case OrdenOfertas.precio:
          return porPrecio(a, b);
        case OrdenOfertas.calificacion:
          final c = porCalificacion(a, b);
          return c != 0 ? c : porPrecio(a, b);
        case OrdenOfertas.reciente:
          return fecha(b).compareTo(fecha(a));
        case OrdenOfertas.recomendado:
          final propio =
              (b.proveedor.tipo == TipoProveedor.propioAgrocom ? 1 : 0) -
              (a.proveedor.tipo == TipoProveedor.propioAgrocom ? 1 : 0);
          if (propio != 0) return propio;
          final c = porCalificacion(a, b);
          if (c != 0) return c;
          final p = porPrecio(a, b);
          return p != 0 ? p : fecha(a).compareTo(fecha(b));
      }
    });
    return lista;
  }
}

/// Lee los números que se escriben en la hoja de filtros («120», «120,5»).
abstract final class LecturaFiltro {
  /// `null` si el texto está vacío o no es un número positivo.
  static Decimal? leer(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    final valor = Decimal.tryParse(limpio);
    if (valor == null || valor < Decimal.zero) return null;
    return valor;
  }

  /// Vacío es válido (no hay filtro); lo escrito debe ser un número.
  static bool esValido(String texto) =>
      texto.trim().isEmpty || leer(texto) != null;
}
