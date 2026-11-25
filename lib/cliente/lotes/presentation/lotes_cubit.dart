import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../solicitar/domain/solicitud_repositorio.dart';

sealed class LotesEstado {
  const LotesEstado();
}

final class LotesCargando extends LotesEstado {
  const LotesCargando();
}

final class LotesListos extends LotesEstado {
  const LotesListos(this.lotes);

  final List<Lote> lotes;
}

final class LotesError extends LotesEstado {
  const LotesError({required this.sinConexion});

  final bool sinConexion;
}

/// Los lotes que el cliente tiene registrados. Se leen de la red cada vez:
/// el flavor cliente no guarda copia local.
class LotesCubit extends Cubit<LotesEstado> {
  LotesCubit(this._repositorio) : super(const LotesCargando());

  final SolicitudRepositorio _repositorio;

  Future<void> cargar() async {
    if (state is! LotesCargando) emit(const LotesCargando());
    try {
      final lotes = await _repositorio.lotesDelCliente();
      if (!isClosed) emit(LotesListos(lotes));
    } on SinConexion {
      if (!isClosed) emit(const LotesError(sinConexion: true));
    } on Object {
      if (!isClosed) emit(const LotesError(sinConexion: false));
    }
  }
}
