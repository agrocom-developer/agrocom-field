// Golden tests del flujo «Publicar solicitud»: cada pantalla y estado en claro (360x640 y 412x915), en oscuro
// (412x915) y con el texto al 200 % (360x640), más el panel dividido de iPad.
//
// Se regeneran con
//   flutter test --update-goldens test/cliente/solicitar/solicitar_goldens_test.dart
// y se revisan a ojo antes de commitear.

import 'dart:io' show Platform;

import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_estado.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_pantalla.dart';
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
      c.elegirFecha(c.state.fechas.first);
    },
    _variantes,
  ),
  'cuando_dibujo_con_accesos': (
    (c, r) async {
      await c.cargar();
      c.cambiarModoLote(ModoLote.dibujo);
      contornoDePrueba.forEach(c.agregarVertice);
      await c.avanzar();
      c
        ..elegirCultivo('Soya')
        ..elegirProducto('Fertilizante foliar');
      await c.avanzar();
      c
        ..elegirFecha(c.state.fechas[2])
        ..cambiarAccesos('Portón azul, a 3 km de la ruta.')
        ..cambiarObservaciones('Línea eléctrica al sur del lote.');
    },
    _soloChico,
  ),
  'precio_vacio': (
    (c, r) => completarHastaPrecio(c, urgente: true),
    _variantes,
  ),
  'precio': (
    (c, r) async {
      await completarHastaPrecio(c);
      c.cambiarPrecio('118,40');
    },
    _variantes,
  ),
  'precio_invalido': (
    (c, r) async {
      await completarHastaPrecio(c);
      c.cambiarPrecio('0');
    },
    _soloChico,
  ),
  'precio_sin_conexion': (
    (c, r) async {
      await completarHastaPrecio(c);
      c
        ..cambiarPrecio('118,40')
        ..emit(c.state.copiarCon(falloEnvio: FalloEnvio.sinConexion));
    },
    _variantes,
  ),
  'precio_rechazado': (
    (c, r) async {
      await completarHastaPrecio(c);
      c
        ..cambiarPrecio('118,40')
        ..emit(
          c.state.copiarCon(
            falloEnvio: FalloEnvio.rechazado,
            mensajeRechazo: 'Falta un teléfono en tu cuenta.',
          ),
        );
    },
    _soloChico,
  ),
  'ipad_lote_guardado': (
    (c, r) async {
      await c.cargar();
      c.elegirLote(c.state.lotes[1]);
    },
    _soloIpad,
  ),
  'ipad_precio': (
    (c, r) async {
      await completarHastaPrecio(c);
      c.cambiarPrecio('118,40');
    },
    _soloIpad,
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  group('publicar solicitud', () {
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
}
