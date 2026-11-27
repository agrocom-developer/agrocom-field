import '../../../dominio/dominio.dart' show EstadoAprobacion;
import '../domain/cuenta_proveedor.dart';

/// En memoria (modo demo y pruebas). Por defecto: aprobado y disponible.
class CuentaProveedorDemo implements CuentaProveedorRepositorio {
  CuentaProveedorDemo({
    EstadoCuentaProveedor? estado,
    List<DocumentoEnviado>? documentos,
  }) : _estado =
           estado ??
           const EstadoCuentaProveedor(
             proveedorId: 1,
             aprobacion: EstadoAprobacion.aprobado,
             documentosFaltantes: [],
             aptoParaOfertas: true,
             disponibilidad: EstadoDisponibilidad(
               valor: Disponibilidad.disponible,
             ),
             disponibilidadEmpresa: EstadoDisponibilidad(
               valor: Disponibilidad.disponible,
             ),
           ),
       _documentos = [...?documentos];

  EstadoCuentaProveedor _estado;
  final List<DocumentoEnviado> _documentos;

  /// Lo que se subió, para que las pruebas lo vean.
  final List<DocumentoPorSubir> subidos = [];

  /// Si es un error, falla la próxima subida (y se limpia).
  Object? fallaProximaSubida;

  @override
  Future<EstadoCuentaProveedor> estado() async => _estado;

  @override
  Future<List<DocumentoEnviado>> documentos(int proveedorId) async =>
      List.of(_documentos);

  @override
  Future<DocumentoEnviado> subirDocumento(
    int proveedorId,
    DocumentoPorSubir documento,
  ) async {
    final falla = fallaProximaSubida;
    if (falla != null) {
      fallaProximaSubida = null;
      throw falla;
    }
    subidos.add(documento);
    final nuevo = DocumentoEnviado(
      id: 100 + subidos.length,
      tipo: documento.tipo,
      estado: EstadoDocumentoEnviado.enRevision,
      venceEn: documento.venceEn,
    );
    _documentos.insert(0, nuevo);
    _estado = EstadoCuentaProveedor(
      proveedorId: _estado.proveedorId,
      aprobacion: _estado.aprobacion,
      motivo: _estado.motivo,
      documentosFaltantes: [
        for (final t in _estado.documentosFaltantes)
          if (t != documento.tipo) t,
      ],
      aptoParaOfertas: _estado.aptoParaOfertas,
      disponibilidad: _estado.disponibilidad,
      disponibilidadEmpresa: _estado.disponibilidadEmpresa,
    );
    return nuevo;
  }

  @override
  Future<void> reenviarARevision() async {
    _estado = EstadoCuentaProveedor(
      proveedorId: _estado.proveedorId,
      aprobacion: EstadoAprobacion.pendiente,
      documentosFaltantes: _estado.documentosFaltantes,
      aptoParaOfertas: false,
      disponibilidad: _estado.disponibilidad,
      disponibilidadEmpresa: _estado.disponibilidadEmpresa,
    );
  }

  @override
  Future<EstadoDisponibilidad> cambiarDisponibilidad(
    Disponibilidad valor,
  ) async {
    final nueva = EstadoDisponibilidad(
      valor: valor,
      cambiadaEn: DateTime(2026, 11, 27, 9),
      cambiadaPorPropia: true,
    );
    _estado = EstadoCuentaProveedor(
      proveedorId: _estado.proveedorId,
      aprobacion: _estado.aprobacion,
      motivo: _estado.motivo,
      documentosFaltantes: _estado.documentosFaltantes,
      aptoParaOfertas: _estado.aptoParaOfertas,
      disponibilidad: nueva,
      disponibilidadEmpresa: _estado.disponibilidadEmpresa,
    );
    return nueva;
  }
}
