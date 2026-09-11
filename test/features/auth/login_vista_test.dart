// Etapa 2 de HU-03: widget test de `LoginVista` — cubit real conectado a
// un `LoginService` mockeado, para probar la pantalla de punta a punta
// (validación, estado de carga, mensaje de error, navegación al éxito) sin
// pasar por `LoginPantalla`/GetIt.

import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/auth/login_vista.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _LoginServiceFalso extends Mock implements LoginService {}

void main() {
  late _LoginServiceFalso loginService;
  late LoginCubit cubit;
  late int loginesExitosos;

  setUp(() {
    loginService = _LoginServiceFalso();
    cubit = LoginCubit(loginService);
    loginesExitosos = 0;
  });

  tearDown(() => cubit.close());

  Future<void> bombear(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<LoginCubit>.value(
        value: cubit,
        child: LoginVista(onIngresoExitoso: () => loginesExitosos++),
      ),
    ),
  );

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

  testWidgets('409: muestra el mensaje de rol ambiguo sin navegar', (
    tester,
  ) async {
    when(
      () => loginService.login(
        usuario: 'miguelito.justiniano',
        contrasena: 'password',
      ),
    ).thenAnswer((_) async => const LoginRolAmbiguo());

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
    expect(loginesExitosos, 0);
  });

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
