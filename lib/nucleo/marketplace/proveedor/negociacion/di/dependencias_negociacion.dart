import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/negociacion_demo.dart';
import '../data/negociacion_red.dart';
import '../domain/avisador_solicitudes.dart';
import '../domain/negociacion_repositorios.dart';
import '../../../../api/marketplace_http.dart';
import '../../../../notificaciones/data/almacenes_locales.dart';
import '../../../../notificaciones/data/bandeja_red.dart';
import '../../../../notificaciones/domain/aviso.dart';
import '../../../../notificaciones/domain/presentador_avisos.dart';
import '../../../../notificaciones/notificador_local.dart';
import '../../../../permisos/data/gestor_permisos_plataforma.dart';
import '../../../../permisos/domain/permiso.dart';

/// Los repositorios de la negociación del proveedor: mapa de solicitudes,
/// mis ofertas, chat y avisos. Los monta `piloto` (ADR 0012).
class DependenciasNegociacion {
  const DependenciasNegociacion({
    required this.mercado,
    required this.negociacion,
    required this.mensajes,
    required this.avisos,
    required this.bandeja,
    this.presentador,
    this.avisador,
    this.notificador,
    this.permisos,
  });

  /// Datos ficticios en memoria (`MODO_DEMO`, ADR 0010).
  factory DependenciasNegociacion.demo({AlmacenNegociacionDemo? almacen}) {
    almacen ??= AlmacenNegociacionDemo();
    return DependenciasNegociacion(
      mercado: MercadoDemo(almacen),
      negociacion: NegociacionDemo(almacen),
      mensajes: MensajesDemo(almacen),
      avisos: AvisosDemo(almacen),
      bandeja: BandejaDemo(const []),
    );
  }

  /// Contra la API.
  factory DependenciasNegociacion.red(
    MarketplaceHttp http, {
    required NotificadorLocal notificador,
    AvisadorSolicitudesNuevas? avisador,
  }) {
    final mercado = MercadoRed(http);
    final avisos = AvisosRed(http);
    return DependenciasNegociacion(
      mercado: mercado,
      negociacion: NegociacionRed(http),
      mensajes: MensajesRed(http),
      avisos: avisos,
      bandeja: BandejaRed(
        obtener: (ruta) => http.obtener(ruta),
        enviar: (ruta) => http.enviar(ruta),
      ),
      notificador: notificador,
      permisos: GestorPermisosPlataforma(),
      // Los avisos de nuevas solicitudes salen del servidor (por oleadas) y
      // se presentan desde la bandeja; el piloto ya no compara el mercado
      // completo en el teléfono (ADR 0023).
      presentador: PresentadorAvisos(
        notificador: notificador,
        preferencias: PreferenciasCanalesLocal(),
        presentados: AvisosPresentadosLocal(),
      ),
      avisador: avisador,
    );
  }

  final MercadoRepositorio mercado;
  final NegociacionRepositorio negociacion;
  final MensajesRepositorio mensajes;
  final AvisosRepositorio avisos;

  /// «Mis notificaciones»: los avisos propios del servidor.
  final BandejaRepositorio bandeja;

  /// Convierte lo nuevo de la bandeja en notificaciones del sistema, con o
  /// sin Firebase. Sin él (demo y pruebas), la bandeja solo se lee.
  final PresentadorAvisos? presentador;

  /// Avisa de solicitudes nuevas al abrir o refrescar el mapa; solo con red.
  final AvisadorSolicitudesNuevas? avisador;

  /// Para pedir el permiso de notificaciones al activar los avisos.
  final NotificadorLocal? notificador;

  /// Pide los permisos con su explicación previa (ADR 0026). Sin él (demo y
  /// pruebas), el aviso del sistema sale directo por [notificador].
  final GestorPermisos? permisos;

  List<RepositoryProvider<Object>> get proveedores => [
    RepositoryProvider<DependenciasNegociacion>.value(value: this),
    RepositoryProvider<MercadoRepositorio>.value(value: mercado),
    RepositoryProvider<NegociacionRepositorio>.value(value: negociacion),
    RepositoryProvider<MensajesRepositorio>.value(value: mensajes),
    RepositoryProvider<AvisosRepositorio>.value(value: avisos),
    RepositoryProvider<BandejaRepositorio>.value(value: bandeja),
  ];

  Widget proveer({required Widget child}) =>
      MultiRepositoryProvider(providers: proveedores, child: child);
}
