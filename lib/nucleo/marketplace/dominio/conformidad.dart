import 'package:decimal/decimal.dart';

/// Qué muestra una evidencia del servicio.
enum TipoEvidencia {
  fotoAntes('Antes de aplicar'),
  fotoMezcla('Mezcla del caldo'),
  fotoCondiciones('Condiciones de vuelo'),
  fotoDespues('Después de aplicar'),
  registroVuelo('Registro de vuelo');

  const TipoEvidencia(this.etiqueta);
  final String etiqueta;
}

/// Evidencia que el equipo capturó en el lote. El cliente solo la lee.
class EvidenciaServicio {
  const EvidenciaServicio({
    required this.id,
    required this.tipo,
    required this.tomadaEn,
    required this.imagenRef,
    this.nota,
  });

  final String id;
  final TipoEvidencia tipo;
  final DateTime tomadaEn;

  /// Referencia de la imagen: ruta de un recurso empaquetado (`assets/…`) o
  /// URL del archivo en el servidor.
  final String imagenRef;
  final String? nota;
}

enum EstadoActa {
  /// Espera la firma del cliente.
  pendiente('Falta tu conformidad'),

  /// El cliente dio su conformidad.
  firmada('Conforme'),

  /// El cliente reportó un problema en lugar de firmar.
  observada('Con observación');

  const EstadoActa(this.etiqueta);
  final String etiqueta;
}

/// Condiciones de vuelo registradas durante la aplicación. Son mediciones,
/// no dinero ni superficie.
class CondicionesVuelo {
  const CondicionesVuelo({
    required this.vientoKmH,
    required this.temperaturaC,
    required this.humedadPorcentaje,
  });

  final int vientoKmH;
  final int temperaturaC;
  final int humedadPorcentaje;
}

/// Acta de conformidad: el resumen del trabajo que el cliente firma. La firma
/// la escribe solo el cliente; el resto lo escribe el servidor al validar la
/// sesión de vuelo.
class ActaConformidad {
  const ActaConformidad({
    required this.servicioId,
    required this.estado,
    required this.hectareasConfirmadas,
    required this.litrosAplicados,
    required this.inicio,
    required this.fin,
    required this.resumen,
    required this.venceConformidad,
    this.condiciones,
    this.firmadaEn,
  });

  final String servicioId;
  final EstadoActa estado;

  /// Superficie que el servidor validó, decimal exacto.
  final Decimal hectareasConfirmadas;
  final Decimal litrosAplicados;
  final DateTime inicio;
  final DateTime fin;
  final String resumen;

  /// Pasado este momento sin observación, el servicio se da por conforme.
  final DateTime venceConformidad;
  final CondicionesVuelo? condiciones;
  final DateTime? firmadaEn;

  bool get pendiente => estado == EstadoActa.pendiente;

  ActaConformidad copiarCon({EstadoActa? estado, DateTime? firmadaEn}) =>
      ActaConformidad(
        servicioId: servicioId,
        estado: estado ?? this.estado,
        hectareasConfirmadas: hectareasConfirmadas,
        litrosAplicados: litrosAplicados,
        inicio: inicio,
        fin: fin,
        resumen: resumen,
        venceConformidad: venceConformidad,
        condiciones: condiciones,
        firmadaEn: firmadaEn ?? this.firmadaEn,
      );
}

/// Lo que el cliente revisa al terminar un servicio: el acta y sus
/// evidencias.
class ExpedienteServicio {
  const ExpedienteServicio({required this.acta, required this.evidencias});

  /// Nulo mientras el servidor no haya validado la sesión de vuelo.
  final ActaConformidad? acta;
  final List<EvidenciaServicio> evidencias;

  static const vacio = ExpedienteServicio(acta: null, evidencias: []);
}
