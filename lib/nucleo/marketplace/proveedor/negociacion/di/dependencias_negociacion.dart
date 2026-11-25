import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/negociacion_demo.dart';
import '../data/negociacion_red.dart';
import '../domain/avisador_solicitudes.dart';
import '../domain/negociacion_repositorios.dart';
import '../../../../api/marketplace_http.dart';
import '../../../../notificaciones/notificador_local.dart';

/// Los repositorios de la negociación del proveedor: mapa de solicitudes,
/// mis ofertas, chat y avisos. Los monta `piloto` (ADR 0012).
class DependenciasNegociacion {
  const DependenciasNegociacion({
    required this.mercado,
    required this.negociacion,
    required this.mensajes,
    required this.avisos,
    this.avisador,
    this.notificador,
  });

  /// Datos ficticios en memoria (`MODO_DEMO`, ADR 0010).
  factory DependenciasNegociacion.demo({AlmacenNegociacionDemo? almacen}) {
    almacen ??= AlmacenNegociacionDemo();
    return DependenciasNegociacion(
      mercado: MercadoDemo(almacen),
      negociacion: NegociacionDemo(almacen),
      mensajes: MensajesDemo(almacen),
      avisos: AvisosDemo(almacen),
    );
  }

  /// Contra la API.
  factory DependenciasNegociacion.red(
    MarketplaceHttp http, {
    required NotificadorLocal notificador,
    SolicitudesVistasStore? vistas,
  }) {
    final mercado = MercadoRed(http);
    final avisos = AvisosRed(http);
    return DependenciasNegociacion(
      mercado: mercado,
      negociacion: NegociacionRed(http),
      mensajes: MensajesRed(http),
      avisos: avisos,
      notificador: notificador,
      avisador: AvisadorSolicitudesNuevas(
        mercado: mercado,
        avisos: avisos,
        notificador: notificador,
        vistas: vistas ?? SolicitudesVistasLocal(),
      ),
    );
  }

  final MercadoRepositorio mercado;
  final NegociacionRepositorio negociacion;
  final MensajesRepositorio mensajes;
  final AvisosRepositorio avisos;

  /// Avisa de solicitudes nuevas al abrir o refrescar el mapa; solo con red.
  final AvisadorSolicitudesNuevas? avisador;

  /// Para pedir el permiso de notificaciones al activar los avisos.
  final NotificadorLocal? notificador;

  List<RepositoryProvider<Object>> get proveedores => [
    RepositoryProvider<DependenciasNegociacion>.value(value: this),
    RepositoryProvider<MercadoRepositorio>.value(value: mercado),
    RepositoryProvider<NegociacionRepositorio>.value(value: negociacion),
    RepositoryProvider<MensajesRepositorio>.value(value: mensajes),
    RepositoryProvider<AvisosRepositorio>.value(value: avisos),
  ];

  Widget proveer({required Widget child}) =>
      MultiRepositoryProvider(providers: proveedores, child: child);
}
