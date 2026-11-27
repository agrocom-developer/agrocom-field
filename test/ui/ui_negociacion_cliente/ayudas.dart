import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/calificar/data/calificacion_demo.dart';
import 'package:agrocom_field/cliente/calificar/presentation/calificar_pantalla.dart';
import 'package:agrocom_field/cliente/contactos/data/contactos_demo.dart';
import 'package:agrocom_field/cliente/contactos/domain/contactos_repositorio.dart';
import 'package:agrocom_field/cliente/cuenta/data/cuenta_demo.dart';
import 'package:agrocom_field/cliente/precio_final/data/precio_final_demo.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/cliente/inicio/data/inicio_cliente_demo.dart';
import 'package:agrocom_field/cliente/problema/data/problema_demo.dart';
import 'package:agrocom_field/cliente/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/cliente/ofertas/domain/ofertas_repositorio.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento_repositorio.dart';
import 'package:agrocom_field/cliente/solicitudes/data/solicitudes_demo.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitudes_repositorio.dart';
import 'package:agrocom_field/cliente/solicitar/data/solicitud_demo.dart';
import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_perfil/foto_perfil_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/pagos_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/push/dispositivos_push_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/push/token_push_store.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import '../../nucleo/marketplace/dobles_foto.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

/// Reloj fijo de las pruebas: los datos demo calculan sus fechas desde acá.
final ahoraDePrueba = DateTime(2026, 11, 23, 9);

/// El render de texto difiere entre macOS y Linux: los golden de referencia
/// se generan en macOS y en CI (Linux) se omiten en vez de dar falsos rojos.
final bool saltarGolden = !Platform.isMacOS;

Future<void> cargarFuentes() async {
  Future<void> cargar(String familia, String ruta) async {
    final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
    await cargador.load();
  }

  await cargar('Manrope', 'assets/fonts/Manrope.ttf');
  await cargar('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
  await cargar('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}

/// Almacén demo con el reloj fijo.
AlmacenDemoCliente almacenDePrueba() =>
    AlmacenDemoCliente(datos: DatosDemo(reloj: () => ahoraDePrueba));

/// Repositorios demo sin latencia sobre [almacen]. [solicitudes], [ofertas] y
/// [seguimiento] reemplazan a los demo cuando la prueba necesita controlar
/// el flujo de datos (una carga que no termina, una ubicación vieja).
DependenciasCliente dependenciasDePrueba(
  AlmacenDemoCliente almacen, {
  SolicitudesRepositorio? solicitudes,
  OfertasRepositorio? ofertas,
  SeguimientoRepositorio? seguimiento,
  ContactosRepositorio? contactos,
}) => DependenciasCliente(
  solicitudes: solicitudes ?? SolicitudesDemo(almacen, latencia: Duration.zero),
  solicitud: SolicitudDemo(almacen, latencia: Duration.zero),
  ofertas: ofertas ?? OfertasDemo(almacen, latencia: Duration.zero),
  seguimiento: seguimiento ?? SeguimientoDemo(almacen, latencia: Duration.zero),
  calificacion: CalificacionDemo(almacen, latencia: Duration.zero),
  problema: ProblemaDemo(almacen, latencia: Duration.zero),
  cuenta: CuentaDemo(almacen),
  acceso: AccesoDemo(
    almacen,
    latencia: Duration.zero,
    onboardingVisto: true,
    sesionIniciada: true,
  ),
  inicio: InicioClienteDemo(almacen, latencia: Duration.zero),
  fotoPerfil: FotoPerfilDemo(),
  fotosTerreno: FotosTerrenoDemo(),
  pagos: PagosDemo(),
  preparadorFoto: preparadorDePrueba(),
  push: DispositivosPushDemo(TokenPushEnMemoria()),
  contactos: contactos ?? ContactosDemo(),
  precioFinal: PrecioFinalDemo(almacen),
);

/// Variante visual de una captura: modo, tamaño lógico y escala de texto.
class Variante {
  const Variante(this.modo, this.tamano, this.escalaTexto);

  final ModoVisualCampo modo;
  final Size tamano;
  final double escalaTexto;

  String get sufijo =>
      '${modo.name}_${tamano.width.toInt()}x${tamano.height.toInt()}'
      '_x${escalaTexto.toStringAsFixed(1)}';

  static const compacto = Size(360, 640);
  static const amplio = Size(412, 915);

  /// Claro en teléfono chico y grande, y el chico con
  /// el texto al 200 %.
  static const matriz = [
    Variante(ModoVisualCampo.claro, compacto, 1),
    Variante(ModoVisualCampo.claro, compacto, 2),
    Variante(ModoVisualCampo.claro, amplio, 1),
  ];

  static const base = Variante(ModoVisualCampo.claro, amplio, 1);
}

/// Monta [pantalla] como la monta `AppCliente`: tema del modo y repositorios
/// por encima del `Navigator`.
Future<void> montar(
  WidgetTester tester, {
  required Widget pantalla,
  required DependenciasCliente dependencias,
  Variante variante = Variante.base,
  bool reducirMovimiento = false,
}) async {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = variante.tamano;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = variante.escalaTexto;
  if (reducirMovimiento) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
    ConfiguracionMapa.teselas = true;
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(modo: variante.modo),
      builder: (context, child) => dependencias.proveer(child: child!),
      home: pantalla,
    ),
  );
}

/// Deja pasar las cargas sin latencia y las transiciones cortas. No usa
/// `pumpAndSettle`: el esqueleto de carga no se detiene solo.
Future<void> asentar(WidgetTester tester, {int veces = 6}) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Decodifica las fotos de avance antes de capturar: en las pruebas la
/// lectura de recursos es E/S real y no avanza con `pump`.
Future<void> precargarFotos(WidgetTester tester) async {
  final contexto = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final ruta in const [
      'assets/imagenes/fondo_equipo_dron.jpg',
      'assets/imagenes/fondo_dron_agras_t50.jpg',
      'assets/imagenes/fondo_dron_sobre_agua.jpg',
      'assets/imagenes/fondo_dron_pulverizando.jpg',
      'assets/imagenes/fondo_dron_pulverizando_vertical.jpg',
    ]) {
      await precacheImage(AssetImage(ruta), contexto);
    }
  });
  await tester.pump();
}

Future<void> esperarGolden(WidgetTester tester, String nombre) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre'));

/// Pantalla anfitriona que abre la hoja de calificar como la abre la app.
class AbreHojaCalificar extends StatelessWidget {
  const AbreHojaCalificar(this.servicio, {super.key});

  final Solicitud servicio;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitud')),
    body: Center(
      child: TextButton(
        onPressed: () => abrirCalificar(context, servicio),
        child: const Text('Abrir'),
      ),
    ),
  );
}
