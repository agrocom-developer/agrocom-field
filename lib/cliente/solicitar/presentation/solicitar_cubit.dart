import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/formato_marketplace.dart';
import '../domain/reglas_solicitud.dart';
import '../domain/solicitud_repositorio.dart';
import 'solicitar_estado.dart';

final _pasoDosis = Decimal.parse('0.1');

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
/// nunca crean dos servicios (ADR 0009).
class SolicitarCubit extends Cubit<SolicitarEstado> {
  SolicitarCubit(
    this._repositorio, {
    DateTime Function()? reloj,
    String? claveIdempotencia,
  }) : _reloj = reloj ?? DateTime.now,
       super(
         SolicitarEstado(
           claveIdempotencia: claveIdempotencia ?? const Uuid().v4(),
         ),
       );

  final SolicitudRepositorio _repositorio;
  final DateTime Function() _reloj;

  /// Descarta la respuesta de una estimación que ya no corresponde a lo que
  /// hay en pantalla.
  int _turnoEstimacion = 0;

  Future<void> cargar() async {
    emit(state.copiarCon(carga: CargaSolicitud.cargando));
    try {
      final lotes = await _repositorio.lotesDelCliente();
      final productos = await _repositorio.productosSugeridos();
      final cultivos = await _repositorio.cultivosSugeridos();
      if (isClosed) return;
      emit(
        state.copiarCon(
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

  void subirDosis() =>
      emit(state.copiarCon(dosis: state.dosisEfectiva + _pasoDosis));

  void bajarDosis() {
    if (state.dosisEfectiva <= _pasoDosis) return;
    emit(state.copiarCon(dosis: state.dosisEfectiva - _pasoDosis));
  }

  // ── Paso 3: cuándo ───────────────────────────────────────────────────

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

  void elegirVentana(VentanaHoraria ventana) =>
      emit(state.copiarCon(ventana: ventana));

  // ── Navegación entre pasos ───────────────────────────────────────────

  /// Acción principal de la pantalla: siguiente paso o, en el resumen,
  /// enviar.
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
            paso: PasoSolicitud.resumen,
            avanza: true,
            falloEnvio: null,
          ),
        );
        await estimar();
      case PasoSolicitud.resumen:
        await enviar();
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

  // ── Paso 4: resumen y envío ──────────────────────────────────────────

  Future<void> estimar() async {
    final lote = state.lote;
    final hectareas = state.hectareas;
    if (lote == null || hectareas == null) return;
    final turno = ++_turnoEstimacion;
    emit(
      state.copiarCon(
        estimando: true,
        falloEstimacion: false,
        estimacion: null,
      ),
    );
    try {
      final estimacion = await _repositorio.estimar(
        lote: lote,
        dosisLitrosPorHectarea: state.dosisEfectiva,
        hectareas: hectareas,
        fechaDeseada: state.fecha,
        producto: state.producto,
        cultivo: state.cultivo,
        ventana: state.ventana,
        claveIdempotencia: state.claveIdempotencia,
      );
      if (isClosed || turno != _turnoEstimacion) return;
      emit(state.copiarCon(estimando: false, estimacion: estimacion));
    } on Object {
      if (isClosed || turno != _turnoEstimacion) return;
      emit(state.copiarCon(estimando: false, falloEstimacion: true));
    }
  }

  Future<void> enviar() async {
    final lote = state.lote;
    final hectareas = state.hectareas;
    // Un segundo toque mientras viaja el primero no hace nada; y si llegara
    // a salir, la clave de idempotencia lo deja en un solo servicio.
    if (state.enviando || state.servicio != null) return;
    if (lote == null ||
        hectareas == null ||
        state.cultivo == null ||
        state.producto == null ||
        state.fecha == null) {
      return;
    }
    emit(state.copiarCon(enviando: true, falloEnvio: null));
    try {
      final servicio = await _repositorio.solicitar(
        SolicitudServicio(
          lote: lote,
          producto: state.producto!,
          dosisLitrosPorHectarea: state.dosisEfectiva,
          fechaDeseada: state.fecha!,
          claveIdempotencia: state.claveIdempotencia,
          hectareas: hectareas,
          cultivo: state.cultivo,
          ventana: state.ventana,
        ),
      );
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, servicio: servicio));
    } on SolicitudSinConexion {
      if (isClosed) return;
      emit(
        state.copiarCon(enviando: false, falloEnvio: FalloEnvio.sinConexion),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copiarCon(enviando: false, falloEnvio: FalloEnvio.desconocido),
      );
    }
  }
}
