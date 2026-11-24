import 'conformidad.dart';
import 'servicio.dart';

/// Etapas que el cliente ve en la línea de tiempo de su servicio.
enum EtapaServicio {
  solicitado,
  asignacion,
  ejecucion,
  conformidad,
  completado,
}

enum EstadoHito { hecho, actual, pendiente }

/// Un punto de la línea de tiempo: qué etapa es, si ya pasó y qué decirle al
/// cliente sobre ella.
class HitoServicio {
  const HitoServicio({
    required this.etapa,
    required this.estado,
    required this.titulo,
    required this.detalle,
    this.momento,
  });

  final EtapaServicio etapa;
  final EstadoHito estado;
  final String titulo;

  /// Una línea que cuenta qué pasa ahora o qué sigue.
  final String detalle;

  /// Cuándo ocurrió, si el dato existe.
  final DateTime? momento;

  @override
  String toString() => 'HitoServicio(${etapa.name}, ${estado.name})';
}

/// Arma la línea de tiempo de un servicio a partir de su estado y de su acta.
///
/// [estadoVivo] es el estado que informa el seguimiento en vivo, que puede ir
/// por delante del servicio que la pantalla recibió al abrirse.
///
/// Un servicio completado sin [acta] a la vista se da por conforme, salvo
/// que [faltaConformidad] diga que el cliente todavía tiene que revisarlo
/// (el dron acaba de terminar y el acta aún no se cargó).
List<HitoServicio> lineaDeTiempo(
  Servicio servicio, {
  EstadoServicio? estadoVivo,
  ActaConformidad? acta,
  bool faltaConformidad = false,
}) {
  final estado = estadoVivo ?? servicio.estado;
  final proveedor = servicio.proveedor?.nombre;
  final conforme = acta == null
      ? !faltaConformidad
      : acta.estado == EstadoActa.firmada;

  // Posición de la etapa en curso; las anteriores están hechas. Un servicio
  // cancelado no tiene etapa en curso: se detiene donde quedó.
  final int enCurso;
  final bool detenido;
  switch (estado) {
    case EstadoServicio.buscandoProveedor:
    case EstadoServicio.asignado:
      enCurso = 1;
      detenido = false;
    case EstadoServicio.enEjecucion:
      enCurso = 2;
      detenido = false;
    case EstadoServicio.completado:
      enCurso = conforme ? 5 : 3;
      detenido = false;
    case EstadoServicio.cancelado:
      enCurso = proveedor == null ? 1 : 2;
      detenido = true;
  }

  EstadoHito de(int posicion) {
    if (posicion < enCurso) return EstadoHito.hecho;
    if (posicion == enCurso && !detenido) return EstadoHito.actual;
    return EstadoHito.pendiente;
  }

  return [
    HitoServicio(
      etapa: EtapaServicio.solicitado,
      estado: EstadoHito.hecho,
      titulo: 'Solicitud recibida',
      detalle: 'Recibimos tu pedido para ${servicio.lote.nombre}.',
      momento: servicio.solicitadoEn,
    ),
    HitoServicio(
      etapa: EtapaServicio.asignacion,
      estado: de(1),
      titulo: proveedor == null ? 'Buscando proveedor' : 'Proveedor asignado',
      detalle: switch (estado) {
        EstadoServicio.buscandoProveedor =>
          'Lo ofrecemos primero a la flota de Agrocom y después a '
              'proveedores de la zona.',
        EstadoServicio.asignado =>
          '$proveedor tomó el servicio y llega en la fecha pactada.',
        _ =>
          proveedor == null
              ? 'Ningún proveedor llegó a tomarlo.'
              : '$proveedor tomó el servicio.',
      },
    ),
    HitoServicio(
      etapa: EtapaServicio.ejecucion,
      estado: de(2),
      titulo: de(2) == EstadoHito.hecho
          ? 'Fumigación terminada'
          : 'Fumigación del lote',
      detalle: switch (de(2)) {
        EstadoHito.actual => 'El dron está aplicando sobre tu lote.',
        EstadoHito.hecho => 'El equipo terminó la aplicación.',
        EstadoHito.pendiente => 'Vas a poder seguir el dron en vivo.',
      },
      momento: de(2) == EstadoHito.hecho ? acta?.fin : null,
    ),
    HitoServicio(
      etapa: EtapaServicio.conformidad,
      estado: de(3),
      titulo: 'Tu conformidad',
      detalle: switch (acta?.estado) {
        EstadoActa.firmada => 'Diste tu conformidad.',
        EstadoActa.observada => 'Reportaste un problema; soporte lo revisa.',
        EstadoActa.pendiente =>
          'Revisa las evidencias y firma el acta de conformidad.',
        null => switch (de(3)) {
          EstadoHito.hecho => 'El servicio quedó conforme.',
          EstadoHito.actual =>
            'Revisa las evidencias y firma el acta de conformidad.',
          EstadoHito.pendiente =>
            'Al terminar revisas las evidencias y firmas el acta.',
        },
      },
      momento: acta?.firmadaEn,
    ),
    HitoServicio(
      etapa: EtapaServicio.completado,
      estado: enCurso >= 5 ? EstadoHito.hecho : EstadoHito.pendiente,
      titulo: 'Servicio completado',
      detalle: enCurso >= 5
          ? 'Gracias por fumigar con Agrocom.'
          : 'Después podés calificar al proveedor.',
    ),
  ];
}
