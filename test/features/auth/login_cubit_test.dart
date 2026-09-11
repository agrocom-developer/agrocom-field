// Etapa 2 de HU-03: `LoginCubit` contra un `LoginService` mockeado —
// verifica la traducción de cada `ResultadoLogin` a un `LoginEstado` con
// mensaje legible.

import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/auth/login_estado.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _LoginServiceFalso extends Mock implements LoginService {}

void main() {
  late _LoginServiceFalso loginService;

  setUp(() {
    loginService = _LoginServiceFalso();
  });

  blocTest<LoginCubit, LoginEstado>(
    'estado inicial es LoginInicial',
    build: () => LoginCubit(loginService),
    verify: (cubit) => expect(cubit.state, const LoginInicial()),
  );

  blocTest<LoginCubit, LoginEstado>(
    '201: emite cargando y luego exitoso',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginExitoso());
    },
    build: () => LoginCubit(loginService),
    act: (cubit) =>
        cubit.ingresar(usuario: 'camila.rojas', contrasena: 'password'),
    expect: () => [const LoginCargando(), const LoginExitosoEstado()],
  );

  blocTest<LoginCubit, LoginEstado>(
    '401: emite un mensaje de credenciales inválidas',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginCredencialesInvalidas());
    },
    build: () => LoginCubit(loginService),
    act: (cubit) => cubit.ingresar(usuario: 'camila.rojas', contrasena: 'mala'),
    expect: () => [
      const LoginCargando(),
      const LoginFallido('Usuario o contraseña incorrectos.'),
    ],
  );

  blocTest<LoginCubit, LoginEstado>(
    '409: emite un mensaje explícito de que el selector de rol no está soportado',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginRolAmbiguo());
    },
    build: () => LoginCubit(loginService),
    act: (cubit) =>
        cubit.ingresar(usuario: 'miguelito.justiniano', contrasena: 'password'),
    verify: (cubit) {
      final estado = cubit.state;
      expect(estado, isA<LoginFallido>());
      expect((estado as LoginFallido).mensaje, contains('más de un rol'));
    },
  );

  blocTest<LoginCubit, LoginEstado>(
    '422: propaga el mensaje del servidor',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer(
        (_) async =>
            const LoginDatosInvalidos('El campo password es obligatorio.'),
      );
    },
    build: () => LoginCubit(loginService),
    act: (cubit) => cubit.ingresar(usuario: 'camila.rojas', contrasena: ''),
    expect: () => [
      const LoginCargando(),
      const LoginFallido('El campo password es obligatorio.'),
    ],
  );

  blocTest<LoginCubit, LoginEstado>(
    'sin red: emite un mensaje de sin conexión',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginSinConexion());
    },
    build: () => LoginCubit(loginService),
    act: (cubit) =>
        cubit.ingresar(usuario: 'camila.rojas', contrasena: 'password'),
    expect: () => [
      const LoginCargando(),
      const LoginFallido('Sin conexión. Probá de nuevo cuando tengas señal.'),
    ],
  );
}
