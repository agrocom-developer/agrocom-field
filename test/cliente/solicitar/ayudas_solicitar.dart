import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/cliente/solicitar/domain/solicitud_repositorio.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/referencias/precio_referencia.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/presentation/fotos_terreno_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/l10n/app_localizations.dart';

import '../../nucleo/marketplace/dobles_foto.dart';

/// Lunes 23 de noviembre de 2026, 10:00. «Mañana» es el martes 24.
final ahoraDePrueba = DateTime(2026, 11, 23, 10);

DateTime relojDePrueba() => ahoraDePrueba;

/// Repositorio de prueba: delega en la demo con reloj fijo, cuenta las
/// solicitudes que salen y deja controlar la carga.
class RepositorioEspia implements SolicitudRepositorio {
  RepositorioEspia({this.lotes, this.fallaLaCarga = false})
    : almacen = AlmacenDemoCliente(datos: DatosDemo(reloj: relojDePrueba)) {
    demo = SolicitudDemo(almacen, latencia: Duration.zero);
  }

  final AlmacenDemoCliente almacen;
  late final SolicitudDemo demo;

  /// Con valor, reemplaza los lotes de la demo.
  final List<Lote>? lotes;
  bool fallaLaCarga;

  /// Solicitudes enviadas a [publicar], en orden.
  final enviadas = <NuevaSolicitud>[];

  /// Claves de idempotencia de cada llamada a [publicar], en orden.
  List<String> get clavesEnviadas => [
    for (final s in enviadas) s.claveIdempotencia,
  ];

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
  Future<Solicitud> publicar(NuevaSolicitud solicitud) {
    enviadas.add(solicitud);
    return demo.publicar(solicitud);
  }
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

/// Deja el formulario completo y parado en el paso del precio, con el lote
/// «Maíz La Curva» (85,5 ha) para el martes 24 (urgente) o el jueves 26.
Future<void> completarHastaPrecio(
  SolicitarCubit cubit, {
  bool urgente = false,
}) async {
  await cubit.cargar();
  cubit
    ..elegirLote(cubit.state.lotes[1])
    ..elegirProducto('Insecticida piretroide');
  await cubit.avanzar();
  await cubit.avanzar();
  cubit.elegirFecha(cubit.state.fechas[urgente ? 0 : 2]);
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
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SolicitudRepositorio>.value(value: repositorio),
      RepositoryProvider<ReferenciasRepositorio>.value(
        value: ReferenciasDemo(),
      ),
    ],
    child: BlocProvider(
      create: (_) => FotosTerrenoCubit(
        FotosTerrenoDemo(),
        preparadorDePrueba(),
        AppLocalizationsEs(),
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
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
    ),
  );
}
