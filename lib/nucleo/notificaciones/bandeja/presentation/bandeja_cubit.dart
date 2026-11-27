import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/dominio/falla.dart';
import '../domain/bandeja_repositorio.dart';
import '../domain/notificacion.dart';

/// Qué avisos se muestran.
enum FiltroBandeja { todas, mensajes, sistema }

sealed class BandejaEstado {
  const BandejaEstado();
}

class BandejaCargando extends BandejaEstado {
  const BandejaCargando();
}

class BandejaError extends BandejaEstado {
  const BandejaError({required this.sinConexion});

  final bool sinConexion;
}

class BandejaLista extends BandejaEstado {
  const BandejaLista(this.todas, {this.filtro = FiltroBandeja.todas});

  final List<Notificacion> todas;
  final FiltroBandeja filtro;

  List<Notificacion> get visibles => switch (filtro) {
    FiltroBandeja.todas => todas,
    FiltroBandeja.mensajes => [
      for (final n in todas)
        if (n.esMensaje) n,
    ],
    FiltroBandeja.sistema => [
      for (final n in todas)
        if (!n.esMensaje) n,
    ],
  };

  int get noLeidas => todas.where((n) => !n.leida).length;

  BandejaLista copiar({List<Notificacion>? todas, FiltroBandeja? filtro}) =>
      BandejaLista(todas ?? this.todas, filtro: filtro ?? this.filtro);
}

class BandejaCubit extends Cubit<BandejaEstado> {
  BandejaCubit(this._repositorio) : super(const BandejaCargando());

  final BandejaRepositorio _repositorio;

  Future<void> cargar() async {
    emit(const BandejaCargando());
    try {
      final lista = await _repositorio.listar();
      if (!isClosed) emit(BandejaLista(lista));
    } on SinConexion {
      if (!isClosed) emit(const BandejaError(sinConexion: true));
    } on FallaMarketplace {
      if (!isClosed) emit(const BandejaError(sinConexion: false));
    }
  }

  void filtrar(FiltroBandeja filtro) {
    final actual = state;
    if (actual is BandejaLista) emit(actual.copiar(filtro: filtro));
  }

  /// Marca un aviso como leído al abrirlo. Se refleja de inmediato; si el
  /// servidor falla, la marca se pierde sin molestar (se reintenta al
  /// volver a abrir la bandeja).
  Future<void> abrir(Notificacion n) async {
    final actual = state;
    if (actual is! BandejaLista || n.leida) return;
    emit(
      actual.copiar(
        todas: [for (final x in actual.todas) x.id == n.id ? x.comoLeida() : x],
      ),
    );
    try {
      await _repositorio.marcarLeida(n.id);
    } on FallaMarketplace {
      // Sin red o rechazado: el aviso se verá de nuevo como no leído.
    }
  }

  Future<void> marcarTodasLeidas() async {
    final actual = state;
    if (actual is! BandejaLista || actual.noLeidas == 0) return;
    emit(actual.copiar(todas: [for (final x in actual.todas) x.comoLeida()]));
    try {
      await _repositorio.marcarTodasLeidas();
    } on FallaMarketplace {
      // Se reintenta al reabrir la bandeja.
    }
  }
}
