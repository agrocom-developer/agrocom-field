import '../../../../api/marketplace_http.dart';
import '../../../dominio/dominio.dart';
import '../../negociacion/data/mapeo_negociacion.dart';
import '../domain/drones_repositorio.dart';

/// Vida útil de batería con la que se dibuja el desgaste mientras el
/// contrato no la informe por dron.
const cicloMaximoBateriaPorDefecto = 1000;

/// Los drones del proveedor contra la API (`GET /api/proveedores/drones` y
/// `/{id}/fotos`). Una cuenta sin proveedor (rol `piloto`) recibe `403`: se
/// muestra la lista vacía, no un error.
class DronesRed implements DronesRepositorio {
  DronesRed(this._http);

  final MarketplaceHttp _http;

  @override
  Stream<List<Dron>> observar() => Stream.fromFuture(leer());

  Future<List<Dron>> leer() async {
    final Map<String, dynamic> cuerpo;
    try {
      cuerpo = await _http.obtener('/api/proveedores/drones');
    } on OperacionRechazada catch (e) {
      if (e.codigo == 403 || e.codigo == 404) return const [];
      rethrow;
    }
    final drones = <Dron>[];
    for (final d in (cuerpo['data'] as List? ?? const [])) {
      final j = Map<String, dynamic>.from(d as Map);
      drones.add(await _aDominio(j));
    }
    return drones;
  }

  Future<Dron> _aDominio(Map<String, dynamic> j) async {
    var fotos = const <FotoDelDron>[];
    try {
      final f = await _http.obtener('/api/proveedores/drones/${j['id']}/fotos');
      fotos = [
        for (final x in (f['fotos'] as List? ?? const []))
          FotoDelDron(
            id: (x as Map)['id'] as int,
            tipo: '${x['tipo']}',
            estado: switch (x['estado']) {
              'aprobada' => EstadoFotoDron.aprobada,
              'rechazada' => EstadoFotoDron.rechazada,
              _ => EstadoFotoDron.enRevision,
            },
            motivo: x['motivo'] as String?,
          ),
      ];
    } on OperacionRechazada {
      // Las fotos son un extra de la lista: sin ellas se muestra el dron.
    }
    return Dron(
      id: '${j['id']}',
      matricula: '${j['numero_serie']}',
      modelo: '${j['marca']} ${j['modelo']}',
      capacidadLitros: MapeoNegociacion.decimal(j['capacidad_tanque_l']),
      estado: EstadoDron.disponible,
      propiedad: j['origen'] == 'externo'
          ? PropiedadDron.tercero
          : PropiedadDron.agrocom,
      ciclosBateria: (j['ciclos_bateria'] as num?)?.toInt() ?? 0,
      cicloMaximoBateria: cicloMaximoBateriaPorDefecto,
      aprobacion: switch (j['estado']) {
        'aprobado' => EstadoAprobacion.aprobado,
        'suspendido' || 'baja' => EstadoAprobacion.suspendido,
        'rechazado' => EstadoAprobacion.rechazado,
        _ => EstadoAprobacion.pendiente,
      },
      fotos: fotos,
    );
  }
}
