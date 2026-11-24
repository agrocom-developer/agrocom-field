import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/api_client.dart';
import '../../../../api/marketplace_http.dart';
import '../../../../camara/selector_foto.dart';
import '../../../../db/database.dart';
import '../../../../evidencias/compresor_evidencia.dart';
import '../data/ejecucion_demo.dart';
import '../data/ejecucion_local.dart';
import '../data/ejecucion_sync_engine.dart';
import '../data/ubicacion_red.dart';
import '../domain/ejecucion.dart';

/// Lo que necesita la ejecución de un servicio adjudicado: la base local, la
/// cámara y la ubicación. Lo montan `piloto` y `auxiliar` (ADR 0012).
class DependenciasEjecucion {
  const DependenciasEjecucion({
    required this.repositorio,
    required this.selectorFoto,
    required this.ubicacion,
    required this.publicador,
    this.compartirUbicacion = true,
    this.motor,
  });

  /// Datos ficticios en memoria (`MODO_DEMO`, ADR 0010).
  factory DependenciasEjecucion.demo({
    EjecucionRepositorio? repositorio,
    SelectorFoto? selectorFoto,
    ServicioUbicacion? ubicacion,
    UbicacionRepositorio? publicador,
    bool compartirUbicacion = true,
  }) => DependenciasEjecucion(
    repositorio: repositorio ?? EjecucionDemo(),
    selectorFoto: selectorFoto ?? _SinCamara(),
    ubicacion: ubicacion ?? ServicioUbicacionDemo(),
    publicador: publicador ?? UbicacionDemo(),
    compartirUbicacion: compartirUbicacion,
  );

  /// Sobre `drift` y la API. Solo el piloto comparte su ubicación.
  factory DependenciasEjecucion.local({
    required AppDatabase db,
    required ApiClient api,
    required CompresorEvidencia compresor,
    required Directory directorioFotos,
    required SelectorFoto selectorFoto,
    bool compartirUbicacion = true,
  }) {
    final motor = EjecucionSyncEngine(api: api, db: db);
    return DependenciasEjecucion(
      repositorio: EjecucionLocal(
        db,
        compresor: compresor,
        directorioFotos: directorioFotos,
        sincronizar: motor.sincronizar,
      ),
      selectorFoto: selectorFoto,
      ubicacion: ServicioUbicacionGeolocator(),
      publicador: UbicacionRed(MarketplaceHttp(api)),
      compartirUbicacion: compartirUbicacion,
      motor: motor,
    );
  }

  final EjecucionRepositorio repositorio;
  final SelectorFoto selectorFoto;
  final ServicioUbicacion ubicacion;
  final UbicacionRepositorio publicador;

  /// El piloto comparte su ubicación; el auxiliar no.
  final bool compartirUbicacion;

  /// El motor de subida, para dispararlo con la conectividad.
  final EjecucionSyncEngine? motor;

  List<RepositoryProvider<Object>> get proveedores => [
    RepositoryProvider<DependenciasEjecucion>.value(value: this),
    RepositoryProvider<EjecucionRepositorio>.value(value: repositorio),
  ];

  Widget proveer({required Widget child}) =>
      MultiRepositoryProvider(providers: proveedores, child: child);
}

/// La demo no abre la cámara: devuelve una foto vacía muy chica.
class _SinCamara implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async => null;
}
