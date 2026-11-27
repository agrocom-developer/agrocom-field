import 'package:flutter_bloc/flutter_bloc.dart';

import '../../marketplace/dominio/falla.dart';
import '../domain/aviso.dart';
import '../domain/canal_aviso.dart';
import '../domain/presentador_avisos.dart';

enum FaseBandeja { cargando, lista, error }

class BandejaEstado {
  const BandejaEstado({
    this.fase = FaseBandeja.cargando,
    this.bandeja = const Bandeja(),
    this.canal,
    this.sinRed = false,
    this.refrescando = false,
  });

  final FaseBandeja fase;
  final Bandeja bandeja;

  /// El grupo elegido; `null` muestra todos.
  final CanalAviso? canal;
  final bool sinRed;

  /// Se vuelve a leer con la lista a la vista (no se tapa con el esqueleto).
  final bool refrescando;

  List<Aviso> get visibles => bandeja.delCanal(canal);
  int get noLeidas => bandeja.noLeidas;

  BandejaEstado copiarCon({
    FaseBandeja? fase,
    Bandeja? bandeja,
    CanalAviso? Function()? canal,
    bool? sinRed,
    bool? refrescando,
  }) => BandejaEstado(
    fase: fase ?? this.fase,
    bandeja: bandeja ?? this.bandeja,
    canal: canal != null ? canal() : this.canal,
    sinRed: sinRed ?? this.sinRed,
    refrescando: refrescando ?? this.refrescando,
  );
}

/// La bandeja «Mis notificaciones». Se lee al abrir la app, al volver a
/// primer plano y al refrescar a mano; la lectura nunca bloquea otra
/// pantalla. Si hay un [PresentadorAvisos], cada lectura presenta como
/// notificación del sistema lo que llegó nuevo.
class BandejaCubit extends Cubit<BandejaEstado> {
  BandejaCubit(this._repositorio, {PresentadorAvisos? presentador})
    : _presentador = presentador,
      super(const BandejaEstado());

  final BandejaRepositorio _repositorio;
  final PresentadorAvisos? _presentador;

  Future<void> cargar() async {
    final conLista = state.fase == FaseBandeja.lista;
    emit(
      state.copiarCon(
        fase: conLista ? FaseBandeja.lista : FaseBandeja.cargando,
        refrescando: conLista,
        sinRed: false,
      ),
    );
    try {
      final bandeja = await _repositorio.leer();
      if (isClosed) return;
      emit(
        state.copiarCon(
          fase: FaseBandeja.lista,
          bandeja: bandeja,
          refrescando: false,
        ),
      );
      try {
        await _presentador?.presentar(bandeja);
      } on Object {
        // Presentar es un extra: sin permiso del sistema la bandeja sigue.
      }
    } on FallaMarketplace catch (e) {
      if (isClosed) return;
      // Con avisos ya a la vista se conservan; solo se avisa.
      emit(
        state.copiarCon(
          fase: state.fase == FaseBandeja.lista
              ? FaseBandeja.lista
              : FaseBandeja.error,
          sinRed: e is SinConexion,
          refrescando: false,
        ),
      );
    }
  }

  void elegirCanal(CanalAviso? canal) =>
      emit(state.copiarCon(canal: () => canal));

  /// Marca el aviso como leído al instante y lo confirma con el servidor; si
  /// el servidor falla, el aviso vuelve a verse sin leer en la próxima
  /// lectura de la bandeja.
  Future<void> marcarLeida(Aviso aviso) async {
    if (aviso.leida) return;
    emit(state.copiarCon(bandeja: state.bandeja.conLeida(aviso.id)));
    try {
      await _repositorio.marcarLeida(aviso.id);
    } on FallaMarketplace {
      // No se interrumpe a la persona: lo confirmará la próxima lectura.
    }
  }
}
