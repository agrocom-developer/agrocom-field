// Pantallas de seguridad de la cuenta (cliente y piloto): recuperar acceso,
// verificar teléfono, ajustes, eliminar la cuenta, cuenta en eliminación y
// «Ya tienes una cuenta». Con el repositorio en memoria (código 000000).

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/data/cuenta_seguridad_demo.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/ajustes_seguridad_pantalla.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/cuenta_en_eliminacion_pantalla.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/cuenta_ya_registrada_pantalla.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/eliminar_cuenta_pantalla.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/recuperar_acceso_pantalla.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/verificar_telefono_hoja.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _montar(
  WidgetTester tester,
  Widget home,
  CuentaSeguridadRepositorio repo, {
  ModoVisualCampo modo = ModoVisualCampo.claro,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepositoryProvider<CuentaSeguridadRepositorio>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: modo),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}

/// Deja pasar cargas y animaciones cortas sin `pumpAndSettle` (el esqueleto
/// y la cuenta regresiva programan cuadros sin fin).
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _campo(String clave) => find.descendant(
  of: find.byKey(Key(clave)),
  matching: find.byType(TextFormField),
);

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _asentar(tester);
}

void main() {
  group('Recuperar acceso', () {
    testWidgets('valida el identificador, ofrece otro canal si uno cae y '
        'devuelve el usuario al terminar', (tester) async {
      final repo = CuentaSeguridadDemo(canalesCaidos: {CanalCodigo.whatsapp});
      String? usuario;
      await _montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir'),
              onPressed: () async => usuario = await abrirRecuperarAcceso(
                context,
                app: AppCuenta.cliente,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        repo,
      );
      await _tocar(tester, find.byKey(const Key('abrir')));

      // Sin identificador no se envía nada.
      await _tocar(tester, find.byKey(const Key('canal-sms')));
      expect(
        find.text('Escribe tu usuario, teléfono o correo'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('campo-codigo')), findsNothing);

      await tester.enterText(_campo('recuperar-identificador'), 'rosa');
      await _tocar(tester, find.byKey(const Key('canal-whatsapp')));
      // El canal caído se explica sin culpar a la persona y se ofrece otro.
      expect(
        find.textContaining('WhatsApp no está disponible por ahora'),
        findsOneWidget,
      );
      expect(find.textContaining('por SMS o Correo'), findsOneWidget);
      expect(find.byKey(const Key('campo-codigo')), findsNothing);

      await _tocar(tester, find.byKey(const Key('canal-correo')));
      expect(find.byKey(const Key('campo-codigo')), findsOneWidget);
      // La recuperación nunca confirma si la cuenta existe.
      expect(
        find.textContaining('Si existe una cuenta con esos datos'),
        findsOneWidget,
      );

      // Código malo: falla clara y se puede reintentar.
      await tester.enterText(_campo('campo-codigo'), '111111');
      await tester.enterText(_campo('campo-contrasena-nueva'), 'abcd');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(find.textContaining('no es válido o ya venció'), findsOneWidget);

      await tester.enterText(_campo('campo-codigo'), '000000');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(find.text('Cambiaste tu contraseña'), findsOneWidget);
      expect(find.textContaining('demo.usuario'), findsOneWidget);

      await _tocar(tester, find.byKey(const Key('recuperar-ir-al-ingreso')));
      expect(usuario, 'demo.usuario');
    });

    testWidgets('la contraseña nueva exige 4 caracteres y nada más', (
      tester,
    ) async {
      final repo = CuentaSeguridadDemo();
      await _montar(
        tester,
        const RecuperarAccesoPantalla(app: AppCuenta.proveedor),
        repo,
      );
      await tester.enterText(_campo('recuperar-identificador'), '70012345');
      await _tocar(tester, find.byKey(const Key('canal-sms')));
      await tester.enterText(_campo('campo-codigo'), '000000');
      await tester.enterText(_campo('campo-contrasena-nueva'), 'abc');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(find.text('Usa al menos 4 caracteres'), findsOneWidget);

      // Sin mayúsculas, números ni símbolos: vale.
      await tester.enterText(_campo('campo-contrasena-nueva'), 'abcd');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(find.text('Cambiaste tu contraseña'), findsOneWidget);
    });
  });

  group('Verificar teléfono y ajustes de seguridad', () {
    testWidgets('la hoja ofrece WhatsApp y SMS (no correo) y es opcional', (
      tester,
    ) async {
      final repo = CuentaSeguridadDemo();
      bool? resultado;
      await _montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir'),
              onPressed: () async =>
                  resultado = await mostrarVerificarTelefono(context),
              child: const Text('abrir'),
            ),
          ),
        ),
        repo,
      );
      await _tocar(tester, find.byKey(const Key('abrir')));
      expect(find.byKey(const Key('canal-whatsapp')), findsOneWidget);
      expect(find.byKey(const Key('canal-sms')), findsOneWidget);
      expect(find.byKey(const Key('canal-correo')), findsNothing);

      await _tocar(tester, find.byKey(const Key('verificar-mas-tarde')));
      expect(resultado, isFalse);
      expect(repo.telefonoVerificado, isFalse);
    });

    testWidgets('verificar desde Seguridad deja el teléfono verificado', (
      tester,
    ) async {
      final repo = CuentaSeguridadDemo();
      await _montar(
        tester,
        AjustesSeguridadPantalla(alCerrarSesion: () {}),
        repo,
      );
      await _asentar(tester);
      expect(find.text('Verifica tu teléfono'), findsOneWidget);
      expect(find.byKey(const Key('ajuste-contrasena')), findsOneWidget);
      expect(find.byKey(const Key('ajuste-eliminar-cuenta')), findsOneWidget);

      await _tocar(tester, find.byKey(const Key('ajuste-telefono')));
      await _tocar(tester, find.byKey(const Key('canal-sms')));
      await tester.enterText(_campo('campo-codigo'), '000000');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(find.text('Tu teléfono quedó verificado'), findsOneWidget);
      await _tocar(tester, find.byKey(const Key('telefono-listo')));

      expect(repo.telefonoVerificado, isTrue);
      expect(find.text('Teléfono verificado'), findsOneWidget);
      expect(find.text('Verifica tu teléfono'), findsNothing);
    });

    testWidgets('con el teléfono ya verificado no ofrece verificarlo', (
      tester,
    ) async {
      await _montar(
        tester,
        AjustesSeguridadPantalla(alCerrarSesion: () {}),
        CuentaSeguridadDemo(telefonoVerificado: true),
        modo: ModoVisualCampo.campo,
      );
      await _asentar(tester);
      expect(find.text('Teléfono verificado'), findsOneWidget);
    });
  });

  group('Eliminar mi cuenta', () {
    testWidgets('con algo pendiente explica el motivo y su salida, sin '
        'ofrecer eliminar', (tester) async {
      await _montar(
        tester,
        EliminarCuentaPantalla(alCerrarSesion: () {}),
        CuentaSeguridadDemo(
          impedimentos: const [
            ImpedimentoEliminacion.servicioEnCurso,
            ImpedimentoEliminacion.reclamoAbierto,
          ],
        ),
      );
      await _asentar(tester);
      expect(find.text('Todavía no puedes eliminar tu cuenta'), findsOneWidget);
      expect(
        find.byKey(const Key('impedimento-servicio_en_curso')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('impedimento-reclamo_abierto')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('eliminar-continuar')), findsNothing);
    });

    testWidgets('explica qué se borra y qué se conserva; contraseña '
        'incorrecta y luego correcta', (tester) async {
      var cerro = 0;
      await _montar(
        tester,
        EliminarCuentaPantalla(alCerrarSesion: () => cerro++),
        CuentaSeguridadDemo(),
      );
      await _asentar(tester);
      expect(find.text('Qué se borra'), findsOneWidget);
      expect(find.text('Qué se conserva'), findsOneWidget);
      expect(
        find.textContaining('Tienes 7 días para arrepentirte'),
        findsOneWidget,
      );

      await _tocar(tester, find.byKey(const Key('eliminar-continuar')));
      // La confirmación va en una hoja, no en un diálogo.
      expect(find.text('Confirma con tu contraseña'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.enterText(_campo('eliminar-contrasena'), 'otra');
      await _tocar(tester, find.byKey(const Key('eliminar-confirmar')));
      expect(find.textContaining('no es la de tu cuenta'), findsOneWidget);

      await tester.enterText(_campo('eliminar-contrasena'), 'demo');
      await _tocar(tester, find.byKey(const Key('eliminar-confirmar')));
      expect(
        find.text('Tu cuenta quedó en espera de eliminación'),
        findsOneWidget,
      );
      expect(cerro, 0);
      await _tocar(tester, find.byKey(const Key('eliminar-entendido')));
      expect(cerro, 1);
    });

    testWidgets('el piloto con registros sin subir primero sincroniza', (
      tester,
    ) async {
      final lote = _Lote(2);
      await _montar(
        tester,
        RepositoryProvider<PendientesDeSincronizacion>.value(
          value: lote,
          child: EliminarCuentaPantalla(alCerrarSesion: () {}),
        ),
        CuentaSeguridadDemo(),
        modo: ModoVisualCampo.campo,
      );
      await _asentar(tester);
      expect(find.byKey(const Key('eliminar-pendientes')), findsOneWidget);
      expect(find.textContaining('2 registros sin subir'), findsOneWidget);
      expect(find.byKey(const Key('eliminar-continuar')), findsNothing);

      await _tocar(tester, find.byKey(const Key('eliminar-sincronizar')));
      expect(find.byKey(const Key('eliminar-pendientes')), findsNothing);
      expect(find.byKey(const Key('eliminar-continuar')), findsOneWidget);
    });

    testWidgets('quien olvidó la contraseña confirma con un código', (
      tester,
    ) async {
      final repo = CuentaSeguridadDemo();
      await _montar(
        tester,
        EliminarCuentaPantalla(alCerrarSesion: () {}),
        repo,
      );
      await _asentar(tester);
      await _tocar(tester, find.byKey(const Key('eliminar-continuar')));
      await _tocar(tester, find.byKey(const Key('eliminar-usar-codigo')));
      await _tocar(tester, find.byKey(const Key('canal-correo')));
      await tester.enterText(_campo('campo-codigo'), '000000');
      await _tocar(tester, find.byKey(const Key('confirmar-codigo')));
      expect(
        find.text('Tu cuenta quedó en espera de eliminación'),
        findsOneWidget,
      );
      expect((await repo.consultarEliminacion()).enGracia, isTrue);
    });
  });

  group('Cuenta en eliminación', () {
    final t0 = DateTime.utc(2026, 11, 27, 12);

    testWidgets('muestra cuánto falta y «Conservar mi cuenta» la reactiva', (
      tester,
    ) async {
      final repo = CuentaSeguridadDemo(ahora: () => t0);
      await repo.eliminarCuenta(contrasena: 'demo');
      var conservada = 0;
      await _montar(
        tester,
        CuentaEnEliminacionPantalla(
          alConservada: () => conservada++,
          alCerrarSesion: () {},
          ahora: () => t0,
        ),
        repo,
      );
      await _asentar(tester);
      expect(find.text('Tu cuenta se está eliminando'), findsOneWidget);
      expect(find.textContaining('quedan 7 días'), findsOneWidget);

      await _tocar(tester, find.byKey(const Key('eliminacion-conservar')));
      expect(find.text('Conservamos tu cuenta'), findsOneWidget);
      expect((await repo.consultarEliminacion()).enGracia, isFalse);
      await _tocar(tester, find.byKey(const Key('conservada-listo')));
      expect(conservada, 1);
    });

    testWidgets('cerrar sesión sale sin tocar la cuenta', (tester) async {
      final repo = CuentaSeguridadDemo(ahora: () => t0);
      await repo.eliminarCuenta(contrasena: 'demo');
      var salio = 0;
      await _montar(
        tester,
        CuentaEnEliminacionPantalla(
          alConservada: () {},
          alCerrarSesion: () => salio++,
          ahora: () => t0,
        ),
        repo,
      );
      await _asentar(tester);
      await _tocar(tester, find.byKey(const Key('eliminacion-cerrar-sesion')));
      expect(salio, 1);
      expect((await repo.consultarEliminacion()).enGracia, isTrue);
    });
  });

  group('Ya tienes una cuenta', () {
    testWidgets('ofrece iniciar sesión o recuperar el acceso', (tester) async {
      var entrar = 0;
      var recuperar = 0;
      await _montar(
        tester,
        CuentaYaRegistradaPantalla(
          app: AppCuenta.proveedor,
          tipoCuenta: 'proveedor',
          alIniciarSesion: () => entrar++,
          alRecuperarAcceso: () => recuperar++,
        ),
        CuentaSeguridadDemo(),
        modo: ModoVisualCampo.campo,
      );
      expect(find.text('Ya tienes una cuenta'), findsOneWidget);
      // Un proveedor con el alta a medias continúa donde quedó.
      expect(
        find.textContaining('continuarás donde lo dejaste'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('ya-registrada-iniciar-sesion')));
      await tester.tap(find.byKey(const Key('ya-registrada-recuperar')));
      expect((entrar, recuperar), (1, 1));
    });

    testWidgets('una cuenta de la otra app manda a la app correcta', (
      tester,
    ) async {
      await _montar(
        tester,
        CuentaYaRegistradaPantalla(
          app: AppCuenta.cliente,
          tipoCuenta: 'proveedor',
          alIniciarSesion: () {},
          alRecuperarAcceso: () {},
        ),
        CuentaSeguridadDemo(),
      );
      expect(find.textContaining('registrado como piloto'), findsOneWidget);
      expect(
        find.byKey(const Key('ya-registrada-iniciar-sesion')),
        findsNothing,
      );
      expect(find.byKey(const Key('ya-registrada-volver')), findsOneWidget);
    });
  });
}

class _Lote implements PendientesDeSincronizacion {
  _Lote(this.pendientes);

  int pendientes;

  @override
  Future<int> cantidad() async => pendientes;

  @override
  Future<void> sincronizar() async => pendientes = 0;
}
