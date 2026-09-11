// Etapa 2 de HU-03 (+ etapa 3 de HU-69, ADR 0005): widget test de
// `LoginVista` — cubit real conectado a un `LoginService` mockeado, para
// probar la pantalla de punta a punta (validación, estado de carga,
// mensaje de error, navegación al éxito, selector de rol) sin pasar por
// `LoginPantalla`/GetIt.

import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/auth/login_vista.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:agrocom_field/nucleo/auth/rol_activo.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _LoginServiceFalso extends Mock implements LoginService {}

const _roles = [
  RolActivo(id: 1, name: 'piloto', description: 'Piloto de dron'),
  RolActivo(id: 2, name: 'auxiliar', description: null),
];

void main() {
  late _LoginServiceFalso loginService;
  late LoginCubit cubit;
  late int loginesExitosos;

  setUp(() {
    loginService = _LoginServiceFalso();
    loginesExitosos = 0;
  });

  tearDown(() => cubit.close());

  Future<void> bombear(WidgetTester tester, {Flavor flavor = Flavor.piloto}) {
    cubit = LoginCubit(loginService, flavor);
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginCubit>.value(
          value: cubit,
          child: LoginVista(onIngresoExitoso: () => loginesExitosos++),
        ),
      ),
    );
  }

  testWidgets('no deja ingresar con campos vacíos y no llama al servicio', (
    tester,
  ) async {
    await bombear(tester);

    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pump();

    expect(find.text('Ingresá tu usuario'), findsOneWidget);
    expect(find.text('Ingresá tu contraseña'), findsOneWidget);
    verifyNever(
      () => loginService.login(
        usuario: any(named: 'usuario'),
        contrasena: any(named: 'contrasena'),
      ),
    );
  });

  testWidgets('credenciales válidas: muestra carga y navega al placeholder', (
    tester,
  ) async {
    when(
      () => loginService.login(usuario: 'camila.rojas', contrasena: 'password'),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const LoginExitoso();
    });

    await bombear(tester);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'camila.rojas',
    );
    await tester.enterText(
      find.byKey(const Key('login_contrasena')),
      'password',
    );
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(loginesExitosos, 1);
  });

  testWidgets('401: muestra el mensaje de credenciales inválidas', (
    tester,
  ) async {
    when(
      () => loginService.login(usuario: 'camila.rojas', contrasena: 'mala'),
    ).thenAnswer((_) async => const LoginCredencialesInvalidas());

    await bombear(tester);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'camila.rojas',
    );
    await tester.enterText(find.byKey(const Key('login_contrasena')), 'mala');
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(loginesExitosos, 0);
  });

  testWidgets('piloto + 409: muestra el mensaje de rol ambiguo sin navegar ni '
      'selector (regresión — ver ADR 0005: "el flavor piloto no cambia")', (
    tester,
  ) async {
    when(
      () => loginService.login(
        usuario: 'miguelito.justiniano',
        contrasena: 'password',
      ),
    ).thenAnswer((_) async => const LoginRolAmbiguo(_roles));

    await bombear(tester);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'miguelito.justiniano',
    );
    await tester.enterText(
      find.byKey(const Key('login_contrasena')),
      'password',
    );
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.byKey(const Key('login_rol_1')), findsNothing);
    expect(loginesExitosos, 0);
  });

  testWidgets('auxiliar + 409: muestra el selector con los roles del cuerpo', (
    tester,
  ) async {
    when(
      () => loginService.login(
        usuario: 'miguelito.justiniano',
        contrasena: 'password',
      ),
    ).thenAnswer((_) async => const LoginRolAmbiguo(_roles));

    await bombear(tester, flavor: Flavor.auxiliar);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'miguelito.justiniano',
    );
    await tester.enterText(
      find.byKey(const Key('login_contrasena')),
      'password',
    );
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error')), findsNothing);
    expect(find.text('Piloto de dron'), findsOneWidget);
    expect(find.text('auxiliar'), findsOneWidget);
    expect(loginesExitosos, 0);
  });

  testWidgets(
    'auxiliar + 409: tocar un rol reintenta el login con ese role_id y '
    'navega en éxito',
    (tester) async {
      // Una sola stub: la respuesta depende del roleId de la invocación
      // real (ver la misma nota en login_cubit_test.dart).
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
          roleId: any(named: 'roleId'),
        ),
      ).thenAnswer((invocation) async {
        final roleId = invocation.namedArguments[#roleId] as int?;
        return roleId == null
            ? const LoginRolAmbiguo(_roles)
            : const LoginExitoso();
      });

      await bombear(tester, flavor: Flavor.auxiliar);
      await tester.enterText(
        find.byKey(const Key('login_usuario')),
        'miguelito.justiniano',
      );
      await tester.enterText(
        find.byKey(const Key('login_contrasena')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_boton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_rol_1')));
      await tester.pumpAndSettle();

      verify(
        () => loginService.login(
          usuario: 'miguelito.justiniano',
          contrasena: 'password',
          roleId: 1,
        ),
      ).called(1);
      expect(loginesExitosos, 1);
    },
  );

  testWidgets('422: muestra el mensaje de datos inválidos del servidor', (
    tester,
  ) async {
    when(
      () => loginService.login(usuario: 'camila.rojas', contrasena: 'x'),
    ).thenAnswer(
      (_) async =>
          const LoginDatosInvalidos('El campo password es obligatorio.'),
    );

    await bombear(tester);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'camila.rojas',
    );
    await tester.enterText(find.byKey(const Key('login_contrasena')), 'x');
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pumpAndSettle();

    expect(find.text('El campo password es obligatorio.'), findsOneWidget);
  });

  testWidgets('sin red: muestra el mensaje de sin conexión', (tester) async {
    when(
      () => loginService.login(usuario: 'camila.rojas', contrasena: 'password'),
    ).thenAnswer((_) async => const LoginSinConexion());

    await bombear(tester);
    await tester.enterText(
      find.byKey(const Key('login_usuario')),
      'camila.rojas',
    );
    await tester.enterText(
      find.byKey(const Key('login_contrasena')),
      'password',
    );
    await tester.tap(find.byKey(const Key('login_boton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión. Probá de nuevo cuando tengas señal.'),
      findsOneWidget,
    );
  });
}
