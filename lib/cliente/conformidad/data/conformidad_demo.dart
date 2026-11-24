import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../demo/almacen_demo_cliente.dart';
import '../domain/conformidad_repositorio.dart';

/// Expedientes ficticios: los servicios completados tienen acta y cinco
/// evidencias; el que está en ejecución, las fotos previas al vuelo. El
/// servicio completado y sin calificar espera la firma del cliente.
class ConformidadDemo implements ConformidadRepositorio {
  ConformidadDemo(
    this._almacen, {
    this.latencia = const Duration(milliseconds: 350),
  });

  final AlmacenDemoCliente _almacen;
  final Duration latencia;

  static const _imagenes = {
    TipoEvidencia.fotoAntes: 'assets/imagenes/fondo_equipo_dron.jpg',
    TipoEvidencia.fotoMezcla: 'assets/imagenes/fondo_dron_agras_t50.jpg',
    TipoEvidencia.fotoCondiciones: 'assets/imagenes/fondo_dron_sobre_agua.jpg',
    TipoEvidencia.fotoDespues: 'assets/imagenes/fondo_dron_pulverizando.jpg',
    TipoEvidencia.registroVuelo:
        'assets/imagenes/fondo_dron_pulverizando_vertical.jpg',
  };

  static const _notas = {
    TipoEvidencia.fotoAntes: 'Lote señalizado y equipo listo en la cabecera.',
    TipoEvidencia.fotoMezcla: 'Caldo preparado según la receta pactada.',
    TipoEvidencia.fotoCondiciones: 'Viento y temperatura dentro del límite.',
    TipoEvidencia.fotoDespues: 'Última pasada sobre el borde este.',
    TipoEvidencia.registroVuelo: 'Recorrido completo exportado del dron.',
  };

  @override
  Future<ExpedienteServicio> expediente(String servicioId) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final servicio = _almacen.porId(servicioId);
    if (servicio == null) return ExpedienteServicio.vacio;
    return switch (servicio.estado) {
      EstadoServicio.completado => ExpedienteServicio(
        acta: _acta(servicio),
        evidencias: _evidencias(servicio, TipoEvidencia.values),
      ),
      EstadoServicio.enEjecucion => ExpedienteServicio(
        acta: null,
        evidencias: _evidencias(servicio, const [
          TipoEvidencia.fotoAntes,
          TipoEvidencia.fotoMezcla,
          TipoEvidencia.fotoCondiciones,
        ]),
      ),
      _ => ExpedienteServicio.vacio,
    };
  }

  @override
  Future<ActaConformidad> firmar({
    required String servicioId,
    required String claveIdempotencia,
  }) async {
    await Future<void>.delayed(latencia);
    _almacen.exigirRed();
    final servicio = _almacen.porId(servicioId);
    if (servicio == null || servicio.estado != EstadoServicio.completado) {
      throw const OperacionRechazada('Este servicio todavía no tiene acta.');
    }
    final acta = _acta(servicio);
    if (acta.estado == EstadoActa.firmada) return acta;
    if (acta.estado == EstadoActa.observada) {
      throw const OperacionRechazada(
        'Ya reportaste un problema en este servicio. Soporte lo está '
        'revisando.',
      );
    }
    final firmada = acta.copiarCon(
      estado: EstadoActa.firmada,
      firmadaEn: _almacen.datos.ahora,
    );
    _almacen.actas[servicioId] = firmada;
    return firmada;
  }

  ActaConformidad _acta(Servicio s) {
    final guardada = _almacen.actas[s.id];
    if (guardada != null) return guardada;
    final inicio = DateTime(
      s.fechaDeseada.year,
      s.fechaDeseada.month,
      s.fechaDeseada.day,
      6,
      40,
    );
    final fin = inicio.add(const Duration(hours: 3, minutes: 25));
    // El completado sin calificar es el que espera la firma del cliente.
    final pendiente = s.puntajeDelCliente == null;
    return ActaConformidad(
      servicioId: s.id,
      // Reportar un problema en lugar de firmar deja el acta observada.
      estado: !pendiente
          ? EstadoActa.firmada
          : _almacen.problemas.containsKey(s.id)
          ? EstadoActa.observada
          : EstadoActa.pendiente,
      hectareasConfirmadas: s.hectareasCubiertas,
      litrosAplicados: s.dosisLitrosPorHectarea * s.hectareasCubiertas,
      inicio: inicio,
      fin: fin,
      resumen:
          'Aplicación de ${s.producto} sobre ${s.lote.nombre} '
          '(${s.lote.zona}), sin incidencias registradas.',
      venceConformidad: pendiente
          ? _almacen.datos.ahora.add(const Duration(hours: 41))
          : fin.add(const Duration(hours: 72)),
      condiciones: const CondicionesVuelo(
        vientoKmH: 9,
        temperaturaC: 24,
        humedadPorcentaje: 62,
      ),
      firmadaEn: pendiente ? null : fin.add(const Duration(hours: 5)),
    );
  }

  List<EvidenciaServicio> _evidencias(Servicio s, List<TipoEvidencia> tipos) {
    final base = DateTime(
      s.fechaDeseada.year,
      s.fechaDeseada.month,
      s.fechaDeseada.day,
      6,
      20,
    );
    return [
      for (var i = 0; i < tipos.length; i++)
        EvidenciaServicio(
          id: '${s.id}-ev-${i + 1}',
          tipo: tipos[i],
          tomadaEn: base.add(Duration(minutes: 50 * i)),
          imagenRef: _imagenes[tipos[i]]!,
          nota: _notas[tipos[i]],
        ),
    ];
  }
}
