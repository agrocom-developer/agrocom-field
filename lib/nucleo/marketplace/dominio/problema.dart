/// Motivos por los que el cliente reporta un problema con un servicio.
/// Catálogo cerrado de la política de disputas.
enum MotivoProblema {
  coberturaIncompleta(
    'Cobertura incompleta',
    'Quedaron partes del lote sin aplicar.',
  ),
  malaAplicacion('Mala aplicación', 'Franjas sin cubrir o con doble pasada.'),
  danoCultivos(
    'Daño a cultivos o a terceros',
    'La aplicación afectó tu cultivo o un lote vecino.',
  ),
  productoDistinto(
    'Producto distinto al pactado',
    'Se aplicó otro producto u otra dosis.',
  ),
  equipoAusente('El equipo no se presentó', 'Nadie llegó en la fecha pactada.'),
  evidenciaFaltante(
    'Faltan evidencias',
    'No están las fotos o el registro del vuelo.',
  ),
  cobroIndebido('Cobro indebido', 'El monto no coincide con lo estimado.'),
  tratoInadecuado(
    'Trato inadecuado',
    'Hubo una falta de respeto o de cuidado.',
  );

  const MotivoProblema(this.etiqueta, this.ayuda);
  final String etiqueta;
  final String ayuda;
}

/// Lo que el cliente envía al reportar. `claveIdempotencia` nace en el
/// dispositivo al abrir el formulario y se reutiliza en cada reintento.
class ReporteProblema {
  const ReporteProblema({
    required this.servicioId,
    required this.motivo,
    required this.detalle,
    required this.claveIdempotencia,
  });

  final String servicioId;
  final MotivoProblema motivo;
  final String detalle;
  final String claveIdempotencia;
}

enum EstadoProblema {
  abierto('Recibido'),
  enRevision('En revisión'),
  resuelto('Resuelto');

  const EstadoProblema(this.etiqueta);
  final String etiqueta;
}

/// Un problema ya registrado por soporte.
class ProblemaReportado {
  const ProblemaReportado({
    required this.numeroCaso,
    required this.servicioId,
    required this.motivo,
    required this.detalle,
    required this.abiertoEn,
    this.estado = EstadoProblema.abierto,
  });

  /// Identificador legible para hablar con soporte («C-2041»).
  final String numeroCaso;
  final String servicioId;
  final MotivoProblema motivo;
  final String detalle;
  final DateTime abiertoEn;
  final EstadoProblema estado;
}
