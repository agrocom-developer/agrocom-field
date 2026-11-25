// Foto de perfil: elegir, cambiar y quitar, con sus estados de carga, éxito,
// error y sin red; el avatar con iniciales de respaldo y los goldens.

import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_perfil/foto_perfil_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_perfil/presentation/foto_perfil_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_perfil/presentation/foto_perfil_widgets.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_preparador.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/avatar_foto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../nucleo/marketplace/dobles_foto.dart';
import 'ayudas.dart';

/// Falla las veces que se pida y luego se comporta como la demo.
class _Inestable extends FotoPerfilDemo {
  _Inestable(this.fallos, [this.error = const SinConexion()]);

  int fallos;
  final Object error;
  var subidas = 0;

  @override
  Future<String> subir(List<int> bytes) async {
    subidas++;
    if (fallos > 0) {
      fallos--;
      throw error;
    }
    return super.subir(bytes);
  }

  @override
  Future<void> quitar() async {
    if (fallos > 0) {
      fallos--;
      throw error;
    }
    return super.quitar();
  }
}

List<RepositoryProvider<Object>> _repos(
  FotoPerfilRepositorio foto, [
  SelectorImagenFalso? selector,
]) => [
  RepositoryProvider<FotoPerfilRepositorio>.value(value: foto),
  RepositoryProvider<PreparadorFoto>.value(
    value: preparadorDePrueba(selector ?? SelectorImagenFalso()),
  ),
];

Widget _encabezado() => FotoPerfilProveedor(
  urlInicial: '',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: const [
      Row(
        children: [
          AvatarFotoPerfil(iniciales: 'HA', nombre: 'Hugo Antelo'),
          SizedBox(width: 14),
          Expanded(child: Text('Hugo Antelo')),
        ],
      ),
      AccionesFotoPerfil(),
    ],
  ),
);

FotoPerfilCubit _cubit(FotoPerfilRepositorio repo, {String? url}) =>
    FotoPerfilCubit(
      repo,
      preparadorDePrueba(),
      AppLocalizationsEs(),
      urlInicial: url,
    );

void main() {
  setUpAll(cargarFuentes);

  group('FotoPerfilCubit', () {
    test('cargar trae la foto actual; sin red deja las iniciales', () async {
      final c = _cubit(FotoPerfilDemo('/api/personas/1/foto'));
      await c.cargar();
      expect(c.state.url, '/api/personas/1/foto');
      expect(c.state.fase, FaseFotoPerfil.lista);

      final sinRed = _cubit(_Falla());
      await sinRed.cargar();
      expect(sinRed.state.tieneFoto, isFalse);
      expect(sinRed.state.fase, FaseFotoPerfil.lista);
    });

    test('elegir sube la foto comprimida y avisa el éxito', () async {
      final c = _cubit(FotoPerfilDemo());
      await c.cargar();
      await c.elegir(OrigenFoto.galeria);
      expect(c.state.tieneFoto, isTrue);
      expect(c.state.bytes, fotoDePrueba);
      expect(c.state.esError, isFalse);
      expect(c.state.mensaje, contains('actualizada'));
    });

    test('cancelar el selector no cambia nada', () async {
      final c = FotoPerfilCubit(
        FotoPerfilDemo(),
        preparadorDePrueba(SelectorImagenFalso(cancela: true)),
        AppLocalizationsEs(),
        urlInicial: '',
      );
      await c.elegir(OrigenFoto.camara);
      expect(c.state.tieneFoto, isFalse);
      expect(c.state.mensaje, isNull);
      expect(c.state.fase, FaseFotoPerfil.lista);
    });

    test(
      'un fallo sin red deja la foto anterior y reintenta lo mismo',
      () async {
        final repo = _Inestable(1);
        final c = _cubit(repo, url: '/foto-vieja');
        await c.elegir(OrigenFoto.galeria);
        expect(c.state.esError, isTrue);
        expect(c.state.sinRed, isTrue);
        expect(c.state.puedeReintentar, isTrue);
        expect(c.state.url, '/foto-vieja');

        await c.reintentar();
        expect(repo.subidas, 2);
        expect(c.state.esError, isFalse);
        expect(c.state.url, isNot('/foto-vieja'));
      },
    );

    test('un rechazo del servidor muestra su mensaje', () async {
      final c = _cubit(
        _Inestable(1, const OperacionRechazada('La foto no es una imagen.')),
      );
      await c.elegir(OrigenFoto.galeria);
      expect(c.state.mensaje, 'La foto no es una imagen.');
      expect(c.state.sinRed, isFalse);
    });

    test('quitar borra la foto; es idempotente en el repositorio', () async {
      final c = _cubit(FotoPerfilDemo('/foto'), url: '/foto');
      await c.quitar();
      expect(c.state.tieneFoto, isFalse);
      expect(c.state.mensaje, contains('iniciales'));
      await c.quitar();
      expect(c.state.esError, isFalse);
    });

    test('quitar sin red permite reintentar', () async {
      final repo = _Inestable(1);
      final c = _cubit(repo, url: '/foto');
      await c.quitar();
      expect(c.state.puedeReintentar, isTrue);
      await c.reintentar();
      expect(c.state.tieneFoto, isFalse);
    });
  });

  group('AvatarFoto', () {
    testWidgets('sin foto muestra las iniciales', (tester) async {
      await montar(
        tester,
        const AvatarFoto(iniciales: 'MQ', etiqueta: 'Marcelo Quiroga'),
      );
      expect(find.text('MQ'), findsOneWidget);
    });

    testWidgets('si la foto no carga, quedan las iniciales', (tester) async {
      await montar(
        tester,
        const AvatarFoto(
          iniciales: 'MQ',
          etiqueta: 'Marcelo Quiroga',
          url: 'assets/no-existe.jpg',
        ),
      );
      await asentar(tester);
      expect(find.text('MQ'), findsOneWidget);
    });
  });

  group('foto de perfil en pantalla', () {
    testWidgets('agregar desde la galería muestra la foto y el éxito', (
      tester,
    ) async {
      final selector = SelectorImagenFalso();
      await montar(
        tester,
        _encabezado(),
        repositorios: _repos(FotoPerfilDemo(), selector),
      );
      expect(find.text('Agregar foto'), findsOneWidget);
      expect(find.text('Quitar'), findsNothing);

      await tester.tap(find.byKey(const Key('foto-perfil-cambiar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('foto-perfil-galeria')));
      await asentar(tester);

      expect(selector.llamadas, 1);
      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(find.text('Quitar'), findsOneWidget);
      expect(find.byKey(const Key('foto-perfil-aviso')), findsOneWidget);
    });

    testWidgets('un error con reintento se resuelve con un toque', (
      tester,
    ) async {
      final repo = _Inestable(1);
      await montar(tester, _encabezado(), repositorios: _repos(repo));
      await tester.tap(find.byKey(const Key('foto-perfil-avatar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('foto-perfil-camara')));
      await asentar(tester);
      expect(find.textContaining('Sin conexión'), findsOneWidget);

      await tester.tap(find.byKey(const Key('foto-perfil-reintentar')));
      await asentar(tester);
      expect(find.byKey(const Key('foto-perfil-reintentar')), findsNothing);
      expect(find.text('Cambiar foto'), findsOneWidget);
    });

    testWidgets('quitar desde la hoja vuelve a las iniciales', (tester) async {
      await montar(
        tester,
        _encabezado(),
        repositorios: _repos(FotoPerfilDemo()),
      );
      await tester.tap(find.byKey(const Key('foto-perfil-avatar')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('foto-perfil-galeria')));
      await asentar(tester);
      await tester.tap(find.byKey(const Key('foto-perfil-quitar')));
      await asentar(tester);
      expect(find.text('Agregar foto'), findsOneWidget);
      expect(find.text('HA'), findsOneWidget);
    });

    testWidgets('los controles miden 56 dp o más y tienen etiqueta', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        _encabezado(),
        repositorios: _repos(FotoPerfilDemo()),
      );
      expect(
        tester.getSize(find.byKey(const Key('foto-perfil-cambiar'))).height,
        greaterThanOrEqualTo(56),
      );
      expect(
        find.bySemanticsLabel(RegExp('Sin foto de perfil')),
        findsOneWidget,
      );
      semantica.dispose();
    });

    for (final v in [...matrizCliente, ...matrizCampo]) {
      testWidgets('golden con foto ${v.nombre}', (tester) async {
        await montar(
          tester,
          _encabezado(),
          variante: v,
          repositorios: _repos(FotoPerfilDemo()),
        );
        await tester.tap(find.byKey(const Key('foto-perfil-cambiar')));
        await asentar(tester);
        await tester.tap(find.byKey(const Key('foto-perfil-galeria')));
        await asentar(tester);
        await golden(tester, 'foto_perfil_con_foto_${v.nombre}');
      }, skip: saltarGolden != null);
    }

    for (final v in [matrizCliente.first, matrizCampo.first]) {
      testWidgets('golden vacío y error ${v.nombre}', (tester) async {
        await montar(
          tester,
          _encabezado(),
          variante: v,
          repositorios: _repos(FotoPerfilDemo()),
        );
        await golden(tester, 'foto_perfil_vacio_${v.nombre}');
      }, skip: saltarGolden != null);
      testWidgets('golden error sin red ${v.nombre}', (tester) async {
        await montar(
          tester,
          _encabezado(),
          variante: v,
          repositorios: _repos(_Inestable(1)),
        );
        await tester.tap(find.byKey(const Key('foto-perfil-cambiar')));
        await asentar(tester);
        await tester.tap(find.byKey(const Key('foto-perfil-galeria')));
        await asentar(tester);
        await golden(tester, 'foto_perfil_sin_red_${v.nombre}');
      }, skip: saltarGolden != null);
    }
  });
}

class _Falla extends FotoPerfilDemo {
  @override
  Future<String?> actual() async => throw const SinConexion();
}
