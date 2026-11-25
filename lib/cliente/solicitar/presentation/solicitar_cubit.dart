import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../contactos/domain/contacto.dart';
import '../../../nucleo/marketplace/ui/formato_marketplace.dart';
import '../../contactos/domain/contactos_repositorio.dart';
import '../domain/reglas_solicitud.dart';
import '../domain/solicitud_repositorio.dart';
import 'solicitar_estado.dart';

/// Texto editable de una superficie: «85,5», «120».
String _textoHectareas(Decimal valor) {
  final entera = valor.toStringAsFixed(1).endsWith('.0');
  return FormatoMarketplace.numero(
    valor,
    decimales: entera ? 0 : 1,
  ).replaceAll('.', '');
}

/// Formulario de solicitud del flavor cliente. Online-first: no hay outbox;
/// si el envío falla, el estado conserva todo lo escrito y el reintento usa
/// la misma clave de idempotencia, de modo que un doble toque o un reintento
/// nunca crean dos solicitudes (ADR 0009).
class SolicitarCubit extends Cubit<SolicitarEstado> {
  SolicitarCubit(
    this._repositorio, {
    ContactosRepositorio? contactos,
    DateTime Function()? reloj,
    String? claveIdempotencia,
  }) : _contactos = contactos,
       _reloj = reloj ?? DateTime.now,
       super(
         SolicitarEstado(
           claveIdempotencia: claveIdempotencia ?? const Uuid().v4(),
         ),
       );

  final SolicitudRepositorio _repositorio;
  final ContactosRepositorio? _contactos;
  final DateTime Function() _reloj;

  Future<void> cargar() async {
    emit(state.copiarCon(carga: CargaSolicitud.cargando));
    try {
      final lotes = await _repositorio.lotesDelCliente();
      final productos = await _repositorio.productosSugeridos();
      final cultivos = await _repositorio.cultivosSugeridos();
      // Los contactos son un extra de la empresa: si no cargan, se publica
      // con el principal que el servidor elige por defecto.
      var contactos = state.contactos;
      try {
        contactos = await _contactos?.listar() ?? const [];
      } on Object {
        contactos = const [];
      }
      if (isClosed) return;
      emit(
        state.copiarCon(
          contactos: contactos,
          contactoId: state.contactoId ?? _principal(contactos),
          carga: CargaSolicitud.lista,
          lotes: lotes,
          productos: productos,
          cultivos: cultivos,
          fechas: ReglasSolicitud.fechasDisponibles(_reloj()),
          // Sin lotes registrados, lo único posible es dibujar uno.
          modoLote: lotes.isEmpty ? ModoLote.dibujo : state.modoLote,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copiarCon(carga: CargaSolicitud.error));
    }
  }

  static int? _principal(List<ContactoCliente> lista) {
    for (final c in lista) {
      if (c.esPrincipal) return c.id;
    }
    return lista.isEmpty ? null : lista.first.id;
  }

  void elegirContacto(int id) => emit(state.copiarCon(contactoId: id));

  // ── Paso 1: lote ─────────────────────────────────────────────────────

  void cambiarModoLote(ModoLote modo) {
    if (modo == state.modoLote) return;
    _emitirGeometria(state.copiarCon(modoLote: modo));
  }

  void elegirLote(Lote lote) {
    _emitirGeometria(
      state.copiarCon(
        modoLote: ModoLote.guardado,
        loteGuardado: lote,
        cultivo: lote.cultivo,
      ),
    );
  }

  void agregarVertice(GeoPunto punto) =>
      _emitirGeometria(state.copiarCon(vertices: [...state.vertices, punto]));

  void moverVertice(int indice, GeoPunto punto) {
    if (indice < 0 || indice >= state.vertices.length) return;
    _emitirGeometria(
      state.copiarCon(vertices: [...state.vertices]..[indice] = punto),
    );
  }

  void deshacerVertice() {
    if (state.vertices.isEmpty) return;
    _emitirGeometria(
      state.copiarCon(
        vertices: state.vertices.sublist(0, state.vertices.length - 1),
      ),
    );
  }

  void borrarContorno() => _emitirGeometria(state.copiarCon(vertices: []));

  /// Cuando cambia el terreno, las hectáreas propuestas vuelven a salir de
  /// la geometría: una edición manual solo vale para el terreno sobre el que
  /// se hizo.
  void _emitirGeometria(SolicitarEstado nuevo) {
    final calculadas = nuevo.hectareasCalculadas;
    emit(
      nuevo.copiarCon(
        hectareasTexto: calculadas == null ? '' : _textoHectareas(calculadas),
      ),
    );
  }

  // ── Paso 2: aplicación ───────────────────────────────────────────────

  void cambiarHectareas(String texto) =>
      emit(state.copiarCon(hectareasTexto: texto));

  void elegirCultivo(String cultivo) => emit(state.copiarCon(cultivo: cultivo));

  void elegirProducto(String producto) =>
      emit(state.copiarCon(producto: producto));

  // ── Paso 3: cuándo y accesos ─────────────────────────────────────────

  void elegirFecha(DateTime fecha) {
    final error = ReglasSolicitud.errorDeFecha(fecha, _reloj());
    if (error != null) {
      emit(state.copiarCon(errorFecha: error));
      return;
    }
    emit(
      state.copiarCon(
        fecha: DateTime(fecha.year, fecha.month, fecha.day),
        errorFecha: null,
      ),
    );
  }

  bool get fechaUrgente =>
      state.fecha != null && ReglasSolicitud.esUrgente(state.fecha!, _reloj());

  void cambiarAccesos(String texto) => emit(state.copiarCon(accesos: texto));

  void cambiarObservaciones(String texto) =>
      emit(state.copiarCon(observaciones: texto));

  // ── Navegación entre pasos ───────────────────────────────────────────

  /// Acción principal de la pantalla: siguiente paso o, en el último,
  /// publicar.
  Future<void> avanzar() async {
    if (!state.puedeAvanzar) return;
    switch (state.paso) {
      case PasoSolicitud.lote:
        emit(state.copiarCon(paso: PasoSolicitud.aplicacion, avanza: true));
      case PasoSolicitud.aplicacion:
        emit(state.copiarCon(paso: PasoSolicitud.cuando, avanza: true));
      case PasoSolicitud.cuando:
        emit(
          state.copiarCon(
            paso: PasoSolicitud.precio,
            avanza: true,
            falloEnvio: null,
          ),
        );
      case PasoSolicitud.precio:
        await publicar();
    }
  }

  void retroceder() {
    if (state.paso == PasoSolicitud.lote || state.enviando) return;
    emit(
      state.copiarCon(
        paso: PasoSolicitud.values[state.paso.index - 1],
        avanza: false,
      ),
    );
  }

  // ── Paso 4: precio y publicación ─────────────────────────────────────

  void cambiarPrecio(String texto) => emit(state.copiarCon(precioTexto: texto));

  Future<void> publicar() async {
    final lote = state.lote;
    final hectareas = state.hectareas;
    final precio = state.precio;
    // Un segundo toque mientras viaja el primero no hace nada; y si llegara
    // a salir, la clave de idempotencia lo deja en una sola solicitud.
    if (state.enviando || state.solicitud != null) return;
    if (lote == null ||
        hectareas == null ||
        precio == null ||
        state.cultivo == null ||
        state.producto == null ||
        state.fecha == null) {
      return;
    }
    emit(
      state.copiarCon(enviando: true, falloEnvio: null, mensajeRechazo: null),
    );
    try {
      final accesos = state.accesos.trim();
      final observaciones = state.observaciones.trim();
      final solicitud = await _repositorio.publicar(
        NuevaSolicitud(
          lote: lote,
          hectareas: hectareas,
          cultivo: state.cultivo!,
          producto: state.producto!,
          fechaDeseada: state.fecha!,
          precioHa: precio,
          claveIdempotencia: state.claveIdempotencia,
          accesos: accesos.isEmpty ? null : accesos,
          observaciones: observaciones.isEmpty ? null : observaciones,
          contactoId: state.contactos.isEmpty ? null : state.contactoId,
        ),
      );
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, solicitud: solicitud));
    } on SolicitudSinConexion {
      if (isClosed) return;
      emit(
        state.copiarCon(enviando: false, falloEnvio: FalloEnvio.sinConexion),
      );
    } on OperacionRechazada catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          enviando: false,
          falloEnvio: FalloEnvio.rechazado,
          mensajeRechazo: e.mensaje,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copiarCon(enviando: false, falloEnvio: FalloEnvio.desconocido),
      );
    }
  }
}
