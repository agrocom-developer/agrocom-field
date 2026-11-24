// Golden tests del flujo «Solicitar fumigación» y de la búsqueda de
// proveedor: cada pantalla y estado en claro (360x640 y 412x915), en oscuro
// (412x915) y con el texto al 200 % (360x640), más el panel dividido de iPad.
//
// Se regeneran con
//   flutter test --update-goldens test/cliente/solicitar/solicitar_goldens_test.dart
// y se revisan a ojo antes de commitear.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:agrocom_field/cliente/solicitar/presentation/buscando_proveedor_pantalla.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_estado.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_solicitar.dart';

/// El render de texto difiere entre macOS y Linux: los golden de referencia
/// se generan en macOS y en CI (Linux) se omiten en vez de dar falsos rojos.
final String? _saltar = Platform.isMacOS
    ? null
    : 'golden de referencia generado en macOS';

typedef _Variante = ({
  String nombre,
  Size tamano,
  ModoVisualCampo modo,
  double escala,
});

const _chico = Size(360, 640);
const _grande = Size(412, 915);
const _ipad = Size(1194, 834);

const _variantes = <_Variante>[
  (nombre: 'claro_360', tamano: _chico, modo: ModoVisualCampo.claro, escala: 1),
  (
    nombre: 'claro_412',
    tamano: _grande,
    modo: ModoVisualCampo.claro,
    escala: 1,
  ),
  (
    nombre: 'oscuro_412',
    tamano: _grande,
    modo: ModoVisualCampo.oscuro,
    escala: 1,
  ),
  (
    nombre: 'claro_360_texto200',
    tamano: _chico,
    modo: ModoVisualCampo.claro,
    escala: 2,
  ),
];

const _soloChico = <_Variante>[
  (nombre: 'claro_360', tamano: _chico, modo: ModoVisualCampo.claro, escala: 1),
];

const _soloIpad = <_Variante>[
  (nombre: 'claro_ipad', tamano: _ipad, modo: ModoVisualCampo.claro, escala: 1),
  (
    nombre: 'oscuro_ipad',
    tamano: _ipad,
    modo: ModoVisualCampo.oscuro,
    escala: 1,
  ),
];

/// Lleva el cubit al estado de la escena.
typedef _Preparar = Future<void> Function(SolicitarCubit, RepositorioEspia);

Future<void> _hastaAplicacion(SolicitarCubit c, RepositorioEspia _) async {
  await c.cargar();
  c
    ..elegirLote(c.state.lotes[1])
    ..elegirProducto('Insecticida piretroide');
  await c.avanzar();
}

final _escenasFormulario = <String, (_Preparar, List<_Variante>)>{
  'cargando': ((c, r) async {}, _soloChico),
  'error_de_carga': (
    (c, r) async {
      r.fallaLaCarga = true;
      await c.cargar();
    },
    _soloChico,
  ),
  'lote_sin_elegir': ((c, r) => c.cargar(), _soloChico),
  'lote_guardado': (
    (c, r) async {
      await c.cargar();
      c.elegirLote(c.state.lotes[1]);
    },
    _variantes,
  ),
  'lote_dibujo_vacio': (
    (c, r) async {
      await c.cargar();
      c.cambiarModoLote(ModoLote.dibujo);
    },
    _soloChico,
  ),
  'lote_dibujo': (
    (c, r) async {
      await c.cargar();
      c.cambiarModoLote(ModoLote.dibujo);
      contornoDePrueba.forEach(c.agregarVertice);
    },
    _variantes,
  ),
  'aplicacion': (_hastaAplicacion, _variantes),
  'aplicacion_hectareas_invalidas': (
    (c, r) async {
      await _hastaAplicacion(c, r);
      c.cambiarHectareas('0');
    },
    _soloChico,
  ),
  'cuando': (
    (c, r) async {
      await _hastaAplicacion(c, r);
      await c.avanzar();
      c
        ..elegirFecha(c.state.fechas.first)
        ..elegirVentana(VentanaHoraria.amanecer);
    },
    _variantes,
  ),
  'resumen': ((c, r) => completarHastaResumen(c, urgente: true), _variantes),
  'resumen_precio_cargando': (
    (c, r) async {
      await completarHastaResumen(c);
      // Una estimación que no termina deja el esqueleto del precio.
      c.emit(c.state.copiarCon(estimando: true, estimacion: null));
    },
    _soloChico,
  ),
  'resumen_precio_error': (
    (c, r) async {
      r.fallaLaEstimacion = true;
      await completarHastaResumen(c);
    },
    _soloChico,
  ),
  'resumen_sin_conexion': (
    (c, r) async {
      await completarHastaResumen(c);
      c.emit(c.state.copiarCon(falloEnvio: FalloEnvio.sinConexion));
    },
    _variantes,
  ),
  'ipad_lote_guardado': (
    (c, r) async {
      await c.cargar();
      c.elegirLote(c.state.lotes[1]);
    },
    _soloIpad,
  ),
  'ipad_resumen': (
    (c, r) => completarHastaResumen(c, urgente: true),
    _soloIpad,
  ),
};

final _escenasBusqueda = <String, (BusquedaProveedor?, List<_Variante>)>{
  'buscando_propios': (null, _variantes),
  'buscando_terceros': (
    const BusquedaProveedor(fase: FaseBusqueda.terceros, radioKm: 50),
    _variantes,
  ),
  'asignado': (
    BusquedaProveedor(
      fase: FaseBusqueda.asignado,
      proveedor: RepositorioEspia().almacen.datos.proveedores[1],
    ),
    _variantes,
  ),
  'sin_proveedor': (
    const BusquedaProveedor(fase: FaseBusqueda.sinProveedor),
    _soloChico,
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  group('solicitar fumigación', () {
    for (final MapEntry(key: escena, value: (preparar, variantes))
        in _escenasFormulario.entries) {
      for (final v in variantes) {
        testWidgets('$escena · ${v.nombre}', (tester) async {
          prepararPantalla(tester, v.tamano);
          final repo = RepositorioEspia();
          final cubit = crearCubit(repo);
          addTearDown(cubit.close);
          await preparar(cubit, repo);

          await tester.pumpWidget(
            envolver(
              repositorio: repo,
              modo: v.modo,
              escalaTexto: v.escala,
              sinAnimaciones: true,
              child: BlocProvider.value(
                value: cubit,
                child: SolicitarVista(alSolicitado: (_) {}),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${escena}_${v.nombre}.png'),
          );
        }, skip: _saltar != null);
      }
    }
  });

  group('buscando proveedor', () {
    for (final MapEntry(key: escena, value: (cuadro, variantes))
        in _escenasBusqueda.entries) {
      for (final v in variantes) {
        testWidgets('$escena · ${v.nombre}', (tester) async {
          prepararPantalla(tester, v.tamano);
          final repo = RepositorioEspia();
          final flujo = StreamController<BusquedaProveedor>();
          addTearDown(flujo.close);
          repo.busqueda = flujo;
          final servicio = repo.almacen.servicios.firstWhere(
            (s) => s.estado == EstadoServicio.buscandoProveedor,
            orElse: () => repo.almacen.servicios.first,
          );

          await tester.pumpWidget(
            envolver(
              repositorio: repo,
              modo: v.modo,
              escalaTexto: v.escala,
              sinAnimaciones: true,
              conScaffold: false,
              child: BuscandoProveedorPantalla(
                servicio: servicio,
                alVerServicio: () {},
              ),
            ),
          );
          if (cuadro != null) flujo.add(cuadro);
          await tester.pump();
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${escena}_${v.nombre}.png'),
          );
        }, skip: _saltar != null);
      }
    }
  });
}
