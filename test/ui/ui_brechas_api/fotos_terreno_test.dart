// Fotos del terreno: la galería del cliente (hasta 8, compresión, subida con
// reintento) y la tira que ve el piloto en la solicitud abierta.

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_preparador.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/presentation/fotos_terreno_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/presentation/galeria_fotos_terreno.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/presentation/visor_fotos_terreno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../nucleo/marketplace/dobles_foto.dart';
import 'ayudas.dart';

class _Inestable extends FotosTerrenoDemo {
  int fallos = 0;
  var subidas = 0;
  final borrados = <int>[];

  @override
  Future<FotoTerreno> subir(
    int terrenoId,
    List<int> bytes, {
    String? descripcion,
  }) async {
    subidas++;
    if (fallos > 0) {
      fallos--;
      throw const SinConexion();
    }
    return super.subir(terrenoId, bytes, descripcion: descripcion);
  }

  @override
  Future<void> borrar(int terrenoId, int fotoId) async {
    borrados.add(fotoId);
    if (fallos > 0) {
      fallos--;
      throw const SinConexion();
    }
    return super.borrar(terrenoId, fotoId);
  }
}

FotosTerrenoCubit _cubit(FotosTerrenoRepositorio repo) =>
    FotosTerrenoCubit(repo, preparadorDePrueba());

const _fotosDelServidor = [
  FotoTerreno(id: 1, url: 'assets/imagenes/fondo_dron_pulverizando.jpg'),
  FotoTerreno(id: 2, url: 'assets/imagenes/fondo_dron_sobre_agua.jpg'),
];

Widget _galeria(FotosTerrenoCubit cubit) =>
    BlocProvider.value(value: cubit, child: const GaleriaFotosTerreno());

void main() {
  setUpAll(cargarFuentes);

  group('FotosTerrenoCubit', () {
    test('con un terreno guardado, cada foto sube al elegirla', () async {
      final repo = _Inestable();
      final c = _cubit(repo)..usarTerreno(7, _fotosDelServidor);
      expect(c.state.fotos, hasLength(2));

      await c.agregar(OrigenFoto.galeria);
      expect(c.state.fotos, hasLength(3));
      expect(c.state.fotos.last.situacion, SituacionFoto.guardada);
      expect(c.state.fotos.last.id, isNotNull);
      expect(repo.subidas, 1);
      expect(c.state.mensaje, 'Foto guardada.');
    });

    test('no deja pasar de 8 y lo explica', () async {
      final c = _cubit(_Inestable())..usarTerreno(7);
      for (var i = 0; i < FotosTerrenoRepositorio.maximo; i++) {
        await c.agregar(OrigenFoto.galeria);
      }
      expect(c.state.fotos, hasLength(8));
      expect(c.state.lleno, isTrue);
      await c.agregar(OrigenFoto.galeria);
      expect(c.state.fotos, hasLength(8));
      expect(c.state.esError, isTrue);
      expect(c.state.mensaje, contains('máximo'));
    });

    test('una subida sin red queda fallida y se reintenta', () async {
      final repo = _Inestable()..fallos = 1;
      final c = _cubit(repo)..usarTerreno(7);
      await c.agregar(OrigenFoto.camara);
      expect(c.state.fotos.single.situacion, SituacionFoto.fallida);
      expect(c.state.sinRed, isTrue);

      await c.reintentar(c.state.fotos.single.clave);
      expect(c.state.fotos.single.situacion, SituacionFoto.guardada);
      expect(c.state.esError, isFalse);
    });

    test('quitar borra en el servidor; sin red conserva la foto', () async {
      final repo = _Inestable();
      final c = _cubit(repo)..usarTerreno(7);
      await c.agregar(OrigenFoto.galeria);
      final clave = c.state.fotos.single.clave;

      repo.fallos = 1;
      await c.quitar(clave);
      expect(c.state.fotos, hasLength(1));
      expect(c.state.esError, isTrue);

      await c.quitar(clave);
      expect(c.state.fotos, isEmpty);
    });

    test(
      'quitar una foto que el servidor ya no tiene la quita igual',
      () async {
        final c = _cubit(_Inestable())..usarTerreno(7, _fotosDelServidor);
        await c.quitar('servidor-1');
        expect(c.state.fotos.map((f) => f.id), [2]);
        expect(c.state.esError, isFalse);
      },
    );

    test('un contorno nuevo guarda las fotos y las sube al publicar', () async {
      final repo = _Inestable();
      final c = _cubit(repo)..usarTerreno(null);
      await c.agregar(OrigenFoto.galeria);
      await c.agregar(OrigenFoto.camara);
      expect(repo.subidas, 0);
      expect(c.state.fotos.map((f) => f.situacion), [
        SituacionFoto.pendiente,
        SituacionFoto.pendiente,
      ]);
      expect(c.pendientes, 2);

      final fallidas = await c.subirPendientes(99);
      expect(fallidas, 0);
      expect(repo.subidas, 2);
      expect(repo.de(99), hasLength(2));
      expect(c.pendientes, 0);
    });

    test('cambiar de terreno conserva las fotos de cada uno', () async {
      final c = _cubit(_Inestable())..usarTerreno(null);
      await c.agregar(OrigenFoto.galeria);
      c.usarTerreno(7, _fotosDelServidor);
      expect(c.state.fotos, hasLength(2));
      c.usarTerreno(null);
      expect(c.state.fotos, hasLength(1));
      expect(c.state.fotos.single.situacion, SituacionFoto.pendiente);
    });

    test('una foto de más de 300 KB no sale del celular', () async {
      expect(
        () => FotosTerrenoDemo().subir(7, List.filled(300 * 1024, 1)),
        throwsA(isA<OperacionRechazada>()),
      );
    });
  });

  group('GaleriaFotosTerreno', () {
    testWidgets('vacía, orienta y ofrece agregar', (tester) async {
      await montar(tester, _galeria(_cubit(_Inestable())..usarTerreno(7)));
      expect(find.text('Fotos del terreno'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);
      expect(find.textContaining('el piloto las ve'), findsOneWidget);
      expect(find.byKey(const Key('fotos-terreno-agregar')), findsOneWidget);
    });

    testWidgets('agrega una foto desde la galería y cuenta 3/8', (
      tester,
    ) async {
      final cubit = _cubit(_Inestable())..usarTerreno(7, _fotosDelServidor);
      await montar(tester, _galeria(cubit));
      await tester.tap(find.byKey(const Key('fotos-terreno-agregar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('fotos-terreno-galeria')));
      await asentar(tester);
      expect(find.text('3/8'), findsOneWidget);
      expect(find.text('Foto guardada.'), findsOneWidget);
    });

    testWidgets('un contorno nuevo avisa que las fotos salen al publicar', (
      tester,
    ) async {
      final cubit = _cubit(_Inestable())..usarTerreno(null);
      await montar(tester, _galeria(cubit));
      await cubit.agregar(OrigenFoto.galeria);
      await asentar(tester);
      expect(find.textContaining('cuando publiques'), findsOneWidget);
    });

    testWidgets('quitar una foto la saca de la galería', (tester) async {
      final cubit = _cubit(_Inestable())..usarTerreno(7, _fotosDelServidor);
      await montar(tester, _galeria(cubit));
      await tester.tap(find.byKey(const Key('fotos-terreno-quitar-1')));
      await asentar(tester);
      expect(find.text('1/8'), findsOneWidget);
    });

    testWidgets('quitar tiene un objetivo táctil de 48 dp', (tester) async {
      final cubit = _cubit(_Inestable())..usarTerreno(7, _fotosDelServidor);
      await montar(tester, _galeria(cubit));
      final area = find.ancestor(
        of: find.byKey(const Key('fotos-terreno-quitar-1')),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(area.first).shortestSide, greaterThanOrEqualTo(48));
    });

    testWidgets('una foto fallida se reintenta con un toque', (tester) async {
      final repo = _Inestable()..fallos = 1;
      final cubit = _cubit(repo)..usarTerreno(7);
      await montar(tester, _galeria(cubit));
      await cubit.agregar(OrigenFoto.galeria);
      await asentar(tester);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      await tester.tap(find.byKey(const Key('fotos-terreno-reintentar-1')));
      await asentar(tester);
      expect(find.text('Foto guardada.'), findsOneWidget);
    });

    testWidgets('abrir una foto muestra el visor y se cierra', (tester) async {
      final cubit = _cubit(_Inestable())..usarTerreno(7);
      await montar(tester, _galeria(cubit));
      await cubit.agregar(OrigenFoto.galeria);
      await asentar(tester);
      await tester.tap(find.byType(InkWell).first);
      await asentar(tester);
      expect(find.text('Foto 1 de 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await asentar(tester, veces: 10);
      expect(find.text('Foto 1 de 1'), findsNothing);
    });

    for (final v in matrizCliente) {
      testWidgets('golden con fotos ${v.nombre}', (tester) async {
        final cubit = _cubit(_Inestable())..usarTerreno(7, _fotosDelServidor);
        await montar(tester, _galeria(cubit), variante: v);
        await cubit.agregar(OrigenFoto.galeria);
        await asentar(tester);
        await tester.runAsync(() async {
          for (final f in cubit.state.fotos) {
            if (f.url != null && f.url!.startsWith('assets/')) {
              await precacheImage(
                AssetImage(f.url!),
                tester.element(find.byType(GaleriaFotosTerreno)),
              );
            }
          }
        });
        await asentar(tester);
        await golden(tester, 'fotos_terreno_galeria_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    testWidgets('golden vacía y con error', (tester) async {
      final repo = _Inestable()..fallos = 1;
      final cubit = _cubit(repo)..usarTerreno(7);
      await montar(tester, _galeria(cubit), variante: matrizCliente.first);
      await golden(tester, 'fotos_terreno_vacia_claro_360');
      await cubit.agregar(OrigenFoto.galeria);
      await asentar(tester);
      await golden(tester, 'fotos_terreno_error_claro_360');
    }, skip: saltarGolden != null);
  });

  group('VisorFotosTerreno (piloto)', () {
    testWidgets('sin fotos lo dice', (tester) async {
      await montar(
        tester,
        const VisorFotosTerreno(fotos: []),
        variante: matrizCampo[1],
      );
      expect(find.byKey(const Key('fotos-terreno-vacio')), findsOneWidget);
    });

    testWidgets('con fotos abre la pantalla completa', (tester) async {
      await montar(
        tester,
        const VisorFotosTerreno(fotos: _fotosDelServidor),
        variante: matrizCampo[1],
      );
      await tester.tap(find.byKey(const Key('visor-foto-1')));
      await asentar(tester);
      expect(find.text('Foto 2 de 2'), findsOneWidget);
    });

    for (final v in matrizCampo) {
      testWidgets('golden con fotos ${v.nombre}', (tester) async {
        await montar(
          tester,
          const VisorFotosTerreno(fotos: _fotosDelServidor),
          variante: v,
        );
        await tester.runAsync(() async {
          for (final f in _fotosDelServidor) {
            await precacheImage(
              AssetImage(f.url),
              tester.element(find.byType(VisorFotosTerreno)),
            );
          }
        });
        await asentar(tester);
        await golden(tester, 'fotos_terreno_visor_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    testWidgets('golden vacío', (tester) async {
      await montar(
        tester,
        const VisorFotosTerreno(fotos: []),
        variante: matrizCampo.first,
      );
      await golden(tester, 'fotos_terreno_visor_vacio_campo_360');
    }, skip: saltarGolden != null);
  });
}
