import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../camara/selector_imagen.dart';
import '../../../dominio/falla.dart';
import '../../../foto_preparador.dart';
import '../domain/cuenta_proveedor.dart';

/// En qué punto está cada documento de la lista.
enum EtapaDocumento {
  /// El servidor lo pide y no hay ninguno enviado.
  faltante,
  subiendo,
  enRevision,
  aprobado,
  rechazado,
  vencido,

  /// No se pudo subir; la foto ya comprimida sigue en memoria para reintentar.
  errorEnvio,
}

class ItemDocumento {
  const ItemDocumento({
    required this.tipo,
    required this.etapa,
    this.venceEn,
    this.mensaje,
  });

  final TipoDocumentoProveedor tipo;
  final EtapaDocumento etapa;
  final DateTime? venceEn;

  /// Motivo del rechazo o del fallo de envío.
  final String? mensaje;

  /// Se puede tomar la foto (o volver a tomarla).
  bool get puedeCapturar =>
      etapa == EtapaDocumento.faltante ||
      etapa == EtapaDocumento.rechazado ||
      etapa == EtapaDocumento.vencido ||
      etapa == EtapaDocumento.errorEnvio;

  bool get requiereAccion => puedeCapturar;
}

class DocumentosEstado {
  const DocumentosEstado({
    this.cargando = true,
    this.error = false,
    this.sinRed = false,
    this.items = const [],
    this.aviso,
  });

  final bool cargando;
  final bool error;
  final bool sinRed;
  final List<ItemDocumento> items;

  /// Mensaje de la última captura (foto muy pesada, por ejemplo).
  final String? aviso;

  DocumentosEstado copiarCon({
    bool? cargando,
    bool? error,
    bool? sinRed,
    List<ItemDocumento>? items,
    String? Function()? aviso,
  }) => DocumentosEstado(
    cargando: cargando ?? this.cargando,
    error: error ?? this.error,
    sinRed: sinRed ?? this.sinRed,
    items: items ?? this.items,
    aviso: aviso != null ? aviso() : this.aviso,
  );
}

/// La lista de documentos que el servidor pide (`documentos_faltantes`) más
/// los ya enviados, con la cámara por ítem. La foto se comprime a menos de
/// 300 KB y vive solo en memoria hasta que se sube: no se guarda en disco ni
/// en `drift` (ADR 0024, punto 7).
class DocumentosCubit extends Cubit<DocumentosEstado> {
  DocumentosCubit(this._repositorio, this._preparador, this._l10n)
    : super(const DocumentosEstado());

  final CuentaProveedorRepositorio _repositorio;
  final PreparadorFoto _preparador;
  final AppLocalizations _l10n;

  int? _proveedorId;
  List<DocumentoEnviado> _enviados = const [];
  List<TipoDocumentoProveedor> _faltantes = const [];

  /// Fotos que fallaron al subir, por tipo, para el reintento.
  final Map<TipoDocumentoProveedor, DocumentoPorSubir> _pendientes = {};
  final Map<TipoDocumentoProveedor, String> _errores = {};
  final Set<TipoDocumentoProveedor> _subiendo = {};

  Future<void> cargar() async {
    emit(state.copiarCon(cargando: true, error: false, sinRed: false));
    try {
      final cuenta = await _repositorio.estado();
      _proveedorId = cuenta.proveedorId;
      _faltantes = cuenta.documentosFaltantes;
      _enviados = await _repositorio.documentos(cuenta.proveedorId);
      _publicar(cargando: false);
    } on SinConexion {
      if (!isClosed) {
        emit(state.copiarCon(cargando: false, error: true, sinRed: true));
      }
    } on OperacionRechazada {
      if (!isClosed) {
        emit(state.copiarCon(cargando: false, error: true, sinRed: false));
      }
    }
  }

  /// Une lo que el servidor pide con lo ya enviado y con lo que está en curso.
  void _publicar({bool cargando = false, String? Function()? aviso}) {
    // El envío más reciente de cada tipo (la lista llega del más nuevo).
    final ultimo = <TipoDocumentoProveedor, DocumentoEnviado>{};
    for (final d in _enviados) {
      ultimo.putIfAbsent(d.tipo, () => d);
    }
    final tipos = <TipoDocumentoProveedor>[
      ..._faltantes,
      for (final t in ultimo.keys)
        if (!_faltantes.contains(t)) t,
      for (final t in _pendientes.keys)
        if (!_faltantes.contains(t) && !ultimo.containsKey(t)) t,
    ];
    final items = [for (final tipo in tipos) _item(tipo, ultimo[tipo])];
    if (isClosed) return;
    emit(state.copiarCon(cargando: cargando, items: items, aviso: aviso));
  }

  ItemDocumento _item(TipoDocumentoProveedor tipo, DocumentoEnviado? enviado) {
    if (_subiendo.contains(tipo)) {
      return ItemDocumento(tipo: tipo, etapa: EtapaDocumento.subiendo);
    }
    if (_errores.containsKey(tipo)) {
      return ItemDocumento(
        tipo: tipo,
        etapa: EtapaDocumento.errorEnvio,
        mensaje: _errores[tipo],
      );
    }
    if (enviado == null) {
      return ItemDocumento(tipo: tipo, etapa: EtapaDocumento.faltante);
    }
    return ItemDocumento(
      tipo: tipo,
      venceEn: enviado.venceEn,
      mensaje: enviado.motivoRechazo,
      etapa: switch (enviado.estado) {
        EstadoDocumentoEnviado.enRevision => EtapaDocumento.enRevision,
        EstadoDocumentoEnviado.aprobado => EtapaDocumento.aprobado,
        EstadoDocumentoEnviado.rechazado => EtapaDocumento.rechazado,
        EstadoDocumentoEnviado.vencido => EtapaDocumento.vencido,
      },
    );
  }

  /// Abre la cámara y devuelve la foto ya comprimida, o `null` si la persona
  /// cancela, el sistema negó la cámara ([alDenegar]) o la foto no baja del
  /// tope de 300 KB (queda un aviso).
  Future<DocumentoPorSubir?> tomar(
    TipoDocumentoProveedor tipo, {
    required void Function() alDenegar,
  }) async {
    try {
      final bytes = await _preparador.preparar(OrigenFoto.camara);
      if (bytes == null) return null;
      _publicar(aviso: () => null);
      return DocumentoPorSubir(tipo: tipo, bytes: bytes);
    } on PermisoCamaraDenegado {
      alDenegar();
      return null;
    } on FotoMuyPesada {
      _publicar(aviso: () => _l10n.fotoMuyPesada);
      return null;
    }
  }

  /// Sube la foto. Si falla, la conserva en memoria para [reintentar].
  Future<void> enviar(DocumentoPorSubir documento) async {
    final id = _proveedorId;
    if (id == null) return;
    final tipo = documento.tipo;
    _errores.remove(tipo);
    _subiendo.add(tipo);
    _publicar(aviso: () => null);
    try {
      final nuevo = await _repositorio.subirDocumento(id, documento);
      _pendientes.remove(tipo);
      _enviados = [nuevo, ..._enviados];
      _faltantes = [
        for (final t in _faltantes)
          if (t != tipo) t,
      ];
    } on SinConexion {
      _pendientes[tipo] = documento;
      _errores[tipo] = _l10n.documentosErrorSinRed;
    } on OperacionRechazada catch (e) {
      _pendientes[tipo] = documento;
      _errores[tipo] = e.mensaje;
    } finally {
      _subiendo.remove(tipo);
    }
    _publicar();
  }

  Future<void> reintentar(TipoDocumentoProveedor tipo) async {
    final pendiente = _pendientes[tipo];
    if (pendiente != null) await enviar(pendiente);
  }

  /// Descarta una foto que no se pudo subir (para volver a tomarla).
  void descartar(TipoDocumentoProveedor tipo) {
    _pendientes.remove(tipo);
    _errores.remove(tipo);
    _publicar();
  }
}
