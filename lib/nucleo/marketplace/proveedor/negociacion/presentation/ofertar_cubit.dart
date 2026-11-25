import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

enum FaseOferta { libre, enviando, enviada, fallo }

class OfertarEstado {
  const OfertarEstado({
    this.estado = FaseOferta.libre,
    this.oferta,
    this.mensaje,
    this.sinRed = false,
  });

  final FaseOferta estado;
  final OfertaNegociada? oferta;
  final String? mensaje;
  final bool sinRed;

  bool get enviando => estado == FaseOferta.enviando;
}

/// Envía la primera oferta del piloto sobre una solicitud. La clave de
/// idempotencia (`uuid_cliente`) nace aquí y se conserva entre reintentos
/// hasta que el servidor responde: si la respuesta se pierde, reenviar no
/// crea una segunda oferta (ADR 0016).
class OfertarCubit extends Cubit<OfertarEstado> {
  OfertarCubit(this._mercado, this._l10n, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const OfertarEstado());

  final AppLocalizations _l10n;
  final MercadoRepositorio _mercado;
  final Uuid _uuid;
  String? _clave;

  Future<void> ofertar({
    required int solicitudId,
    required TipoOferta tipo,
    Decimal? precioHa,
    String? nota,
  }) async {
    if (state.enviando) return;
    final clave = _clave ??= _uuid.v4();
    emit(const OfertarEstado(estado: FaseOferta.enviando));
    try {
      final oferta = await _mercado.ofertar(
        solicitudId: solicitudId,
        uuidCliente: clave,
        tipo: tipo,
        precioHa: precioHa,
        nota: nota,
      );
      _clave = null;
      emit(OfertarEstado(estado: FaseOferta.enviada, oferta: oferta));
    } on SinConexion {
      // La clave se conserva: el reintento devuelve la misma oferta.
      emit(
        OfertarEstado(
          estado: FaseOferta.fallo,
          sinRed: true,
          mensaje: _l10n.proveedorNegociacionHayConexionQueEscribiste,
        ),
      );
    } on OperacionRechazada catch (e) {
      // Una respuesta del servidor cierra el intento: el próximo es nuevo.
      _clave = null;
      emit(OfertarEstado(estado: FaseOferta.fallo, mensaje: e.mensaje));
    }
  }
}
