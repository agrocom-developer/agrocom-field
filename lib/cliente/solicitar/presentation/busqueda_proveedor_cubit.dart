import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/solicitud_repositorio.dart';

/// Sigue la búsqueda de proveedor de un servicio recién solicitado. Parte de
/// la ronda de proveedores propios, que es donde empieza toda asignación.
class BusquedaProveedorCubit extends Cubit<BusquedaProveedor> {
  BusquedaProveedorCubit(this._repositorio, this.servicioId)
    : super(const BusquedaProveedor(fase: FaseBusqueda.propios));

  final SolicitudRepositorio _repositorio;
  final String servicioId;
  StreamSubscription<BusquedaProveedor>? _suscripcion;

  void iniciar() {
    _suscripcion?.cancel();
    _suscripcion = _repositorio
        .observarBusqueda(servicioId)
        .listen(
          emit,
          // Un corte de red no cambia lo que ya se sabe: la búsqueda sigue en
          // el servidor y el servicio se puede consultar desde el inicio.
          onError: (Object _) {},
        );
  }

  @override
  Future<void> close() {
    // Sin esperar la cancelación: no hay nada que dependa de ella y el
    // cierre del cubit no queda atado al flujo del repositorio.
    unawaited(_suscripcion?.cancel());
    return super.close();
  }
}
