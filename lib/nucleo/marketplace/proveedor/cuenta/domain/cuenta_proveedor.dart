import 'dart:typed_data';

import '../../../dominio/dominio.dart' show EstadoAprobacion;

/// Los tipos de documento que el contrato acepta (`POST /api/proveedores/documentos`).
enum TipoDocumentoProveedor {
  identidad('identidad'),
  licenciaPiloto('licencia_piloto', exigeVencimiento: true),
  habilitacionDron('habilitacion_dron', exigeVencimiento: true),
  seguroResponsabilidad('seguro_responsabilidad', exigeVencimiento: true),
  registroDron('registro_dron'),
  certificadoFumigacion('certificado_fumigacion'),
  antecedentes('antecedentes'),
  otro('otro');

  const TipoDocumentoProveedor(this.codigo, {this.exigeVencimiento = false});

  final String codigo;

  /// Licencia, seguro y habilitación piden fecha de vencimiento: el servidor
  /// avisa a los 30 y 7 días y suspende si vence.
  final bool exigeVencimiento;

  static TipoDocumentoProveedor? deCodigo(String? codigo) {
    for (final t in values) {
      if (t.codigo == codigo) return t;
    }
    return null;
  }
}

enum EstadoDocumentoEnviado {
  enRevision,
  aprobado,
  rechazado,
  vencido;

  static EstadoDocumentoEnviado deCodigo(String? c) => switch (c) {
    'aprobado' => aprobado,
    'rechazado' => rechazado,
    'vencido' => vencido,
    _ => enRevision,
  };
}

/// Un documento que el servidor ya recibió. El archivo no se descarga.
class DocumentoEnviado {
  const DocumentoEnviado({
    required this.id,
    required this.tipo,
    required this.estado,
    this.venceEn,
    this.motivoRechazo,
  });

  final int id;
  final TipoDocumentoProveedor tipo;
  final EstadoDocumentoEnviado estado;
  final DateTime? venceEn;
  final String? motivoRechazo;
}

/// Interruptor manual de la cuenta (`ocupado` y `en_trabajo` no reciben avisos).
enum Disponibilidad {
  disponible('disponible'),
  ocupado('ocupado'),
  enTrabajo('en_trabajo');

  const Disponibilidad(this.codigo);
  final String codigo;

  static Disponibilidad deCodigo(String? c) => switch (c) {
    'ocupado' => ocupado,
    'en_trabajo' => enTrabajo,
    _ => disponible,
  };
}

class EstadoDisponibilidad {
  const EstadoDisponibilidad({
    required this.valor,
    this.cambiadaEn,
    this.cambiadaPorPropia,
  });

  final Disponibilidad valor;
  final DateTime? cambiadaEn;

  /// `false` si la movió otra cuenta (el encargado de la empresa); `null` si
  /// nunca se movió.
  final bool? cambiadaPorPropia;

  /// «Tu empresa te marcó como ocupado»: la cambió otra cuenta y no estás
  /// disponible.
  bool get laCambioLaEmpresa =>
      cambiadaPorPropia == false && valor != Disponibilidad.disponible;
}

/// Lo que `GET /api/proveedores/mi` dice de la cuenta.
class EstadoCuentaProveedor {
  const EstadoCuentaProveedor({
    required this.proveedorId,
    required this.aprobacion,
    required this.documentosFaltantes,
    required this.aptoParaOfertas,
    required this.disponibilidad,
    required this.disponibilidadEmpresa,
    this.motivo,
  });

  final int proveedorId;
  final EstadoAprobacion aprobacion;

  /// Motivo del último rechazo o suspensión.
  final String? motivo;
  final List<TipoDocumentoProveedor> documentosFaltantes;

  /// Aprobado y con al menos un equipo apto.
  final bool aptoParaOfertas;
  final EstadoDisponibilidad disponibilidad;
  final EstadoDisponibilidad disponibilidadEmpresa;

  /// Solo un proveedor aprobado ve el mapa de solicitudes (CLAUDE.md,
  /// «Alta de proveedores»): mientras no, la app queda en solo lectura. El
  /// servidor decide; la app no replica reglas más finas.
  bool get puedeVerMapa => aprobacion == EstadoAprobacion.aprobado;
}

/// Un documento ya comprimido (<300 KB), solo en memoria hasta subirlo.
class DocumentoPorSubir {
  const DocumentoPorSubir({
    required this.tipo,
    required this.bytes,
    this.venceEn,
  });

  final TipoDocumentoProveedor tipo;
  final Uint8List bytes;
  final DateTime? venceEn;
}

/// Estado de la cuenta del proveedor, sus documentos y su disponibilidad.
/// Requiere red: son trámites de alta y de operación en línea, sin outbox
/// (ADR 0024).
abstract interface class CuentaProveedorRepositorio {
  Future<EstadoCuentaProveedor> estado();

  Future<List<DocumentoEnviado>> documentos(int proveedorId);

  /// Sube un documento (HTTPS, multipart). Queda `en_revision`.
  Future<DocumentoEnviado> subirDocumento(
    int proveedorId,
    DocumentoPorSubir documento,
  );

  /// Tras un rechazo, vuelve a la cola de revisión.
  Future<void> reenviarARevision();

  Future<EstadoDisponibilidad> cambiarDisponibilidad(Disponibilidad valor);
}
