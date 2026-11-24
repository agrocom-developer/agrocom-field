/// Foto del estado de un terreno. [url] es firmada y de corta vida
/// (15 minutos): se pide de nuevo junto con el terreno.
class FotoTerreno {
  const FotoTerreno({required this.id, required this.url, this.descripcion});

  factory FotoTerreno.desdeJson(Map<String, dynamic> j) => FotoTerreno(
    id: (j['id'] as num).toInt(),
    url: '${j['url']}',
    descripcion: j['descripcion'] as String?,
  );

  /// Las fotos de un terreno tal como vienen en `terreno.fotos`; ignora lo
  /// que no sea un objeto.
  static List<FotoTerreno> lista(Object? valor) => [
    if (valor is List)
      for (final f in valor)
        if (f is Map) FotoTerreno.desdeJson(Map<String, dynamic>.from(f)),
  ];

  final int id;
  final String url;
  final String? descripcion;
}
