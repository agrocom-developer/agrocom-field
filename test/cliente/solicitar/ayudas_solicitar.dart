import 'dart:async';

import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/cliente/solicitar/domain/solicitud_repositorio.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lunes 23 de noviembre de 2026, 10:00. «Mañana» es el martes 24.
final ahoraDePrueba = DateTime(2026, 11, 23, 10);

DateTime relojDePrueba() => ahoraDePrueba;

/// Repositorio de prueba: delega en la demo con reloj fijo, cuenta las
/// solicitudes que salen y deja controlar la carga y la búsqueda.
class RepositorioEspia implements SolicitudRepositorio {
  RepositorioEspia({this.lotes, this.fallaLaCarga = false})
    : almacen = AlmacenDemoCliente(datos: DatosDemo(reloj: relojDePrueba)) {
    demo = SolicitudDemo(
      almacen,
      latencia: Duration.zero,
      pasoBusqueda: const Duration(seconds: 4),
    );
  }

  final AlmacenDemoCliente almacen;
  late final SolicitudDemo demo;

  /// Con valor, reemplaza los lotes de la demo.
  final List<Lote>? lotes;
  bool fallaLaCarga;
  bool fallaLaEstimacion = false;

  /// Claves de idempotencia de cada llamada a [solicitar], en orden.
  final clavesEnviadas = <String>[];

  /// Con valor, [observarBusqueda] devuelve este flujo en vez del de la demo.
  StreamController<BusquedaProveedor>? busqueda;

  @override
  Future<List<Lote>> lotesDelCliente() async {
    if (fallaLaCarga) throw Exception('sin red');
    return lotes ?? await demo.lotesDelCliente();
  }

  @override
  Future<List<String>> productosSugeridos() => demo.productosSugeridos();

  @override
  Future<List<String>> cultivosSugeridos() => demo.cultivosSugeridos();

  @override
  Future<EstimacionServicio> estimar({
    required Lote lote,
    required Decimal dosisLitrosPorHectarea,
    Decimal? hectareas,
    DateTime? fechaDeseada,
    String? producto,
    String? cultivo,
    VentanaHoraria ventana = VentanaHoraria.indistinta,
    String? claveIdempotencia,
  }) {
    if (fallaLaEstimacion) throw Exception('sin red');
    return demo.estimar(
      lote: lote,
      dosisLitrosPorHectarea: dosisLitrosPorHectarea,
      hectareas: hectareas,
      fechaDeseada: fechaDeseada,
    );
  }

  @override
  Future<Servicio> solicitar(SolicitudServicio solicitud) {
    clavesEnviadas.add(solicitud.claveIdempotencia);
    return demo.solicitar(solicitud);
  }

  @override
  Stream<BusquedaProveedor> observarBusqueda(String servicioId) =>
      busqueda?.stream ?? demo.observarBusqueda(servicioId);
}

SolicitarCubit crearCubit(RepositorioEspia repo) =>
    SolicitarCubit(repo, reloj: relojDePrueba, claveIdempotencia: 'clave-1');

/// Cuadrilátero de unos 1.000 m de lado cerca de San Julián: ~100 ha.
const contornoDePrueba = [
  GeoPunto(-16.9400, -62.6300),
  GeoPunto(-16.9400, -62.6206),
  GeoPunto(-16.9310, -62.6206),
  GeoPunto(-16.9310, -62.6300),
];

/// Deja el formulario completo y parado en el resumen, con el lote «Maíz La
/// Curva» (85,5 ha) para el martes 24 (urgente) o el jueves 26.
Future<void> completarHastaResumen(
  SolicitarCubit cubit, {
  bool urgente = false,
}) async {
  await cubit.cargar();
  cubit
    ..elegirLote(cubit.state.lotes[1])
    ..elegirProducto('Insecticida piretroide');
  await cubit.avanzar();
  await cubit.avanzar();
  cubit
    ..elegirFecha(cubit.state.fechas[urgente ? 0 : 2])
    ..elegirVentana(VentanaHoraria.amanecer);
  await cubit.avanzar();
}

Future<void> cargarFuentes() async {
  Future<void> cargar(String familia, String ruta) async {
    final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
    await cargador.load();
  }

  await cargar('Manrope', 'assets/fonts/Manrope.ttf');
  await cargar('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
  await cargar('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}

/// Fija el tamaño lógico de la pantalla y apaga las teselas del mapa.
void prepararPantalla(WidgetTester tester, Size tamano, {double densidad = 2}) {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = tamano * densidad;
  tester.view.devicePixelRatio = densidad;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    ConfiguracionMapa.teselas = true;
  });
}

/// App mínima del flavor cliente alrededor de [child].
Widget envolver({
  required SolicitudRepositorio repositorio,
  required Widget child,
  ModoVisualCampo modo = ModoVisualCampo.claro,
  double escalaTexto = 1,
  bool sinAnimaciones = false,
  bool conScaffold = true,
}) {
  return RepositoryProvider<SolicitudRepositorio>.value(
    value: repositorio,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrocomThemeCampo.construir(modo: modo),
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escalaTexto),
          disableAnimations: sinAnimaciones,
        ),
        child: hijo!,
      ),
      home: conScaffold ? Scaffold(body: SafeArea(child: child)) : child,
    ),
  );
}
