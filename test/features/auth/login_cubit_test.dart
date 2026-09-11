// Etapa 2 de HU-03 (+ etapa 2 de HU-69, ADR 0005): `LoginCubit` contra un
// `LoginService` mockeado — verifica la traducción de cada `ResultadoLogin`
// a un `LoginEstado` con mensaje legible, y el selector de rol del flavor
// `auxiliar` ante un `409` (piloto no cambia: regresión explícita).

import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/features/auth/login_estado.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/resultado_login.dart';
import 'package:agrocom_field/nucleo/auth/rol_activo.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _LoginServiceFalso extends Mock implements LoginService {}

const _roles = [
  RolActivo(id: 1, name: 'piloto', description: 'Piloto de dron'),
  RolActivo(id: 2, name: 'auxiliar', description: null),
];

void main() {
  late _LoginServiceFalso loginService;

  setUp(() {
    loginService = _LoginServiceFalso();
  });

  blocTest<LoginCubit, LoginEstado>(
    'estado inicial es LoginInicial',
    build: () => LoginCubit(loginService, Flavor.piloto),
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
    build: () => LoginCubit(loginService, Flavor.piloto),
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
    build: () => LoginCubit(loginService, Flavor.piloto),
    act: (cubit) => cubit.ingresar(usuario: 'camila.rojas', contrasena: 'mala'),
    expect: () => [
      const LoginCargando(),
      const LoginFallido('Usuario o contraseña incorrectos.'),
    ],
  );

  blocTest<LoginCubit, LoginEstado>(
    'piloto + 409: sigue emitiendo el mensaje genérico de siempre, sin '
    'selector (regresión — ver ADR 0005: "el flavor piloto no cambia")',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginRolAmbiguo(_roles));
    },
    build: () => LoginCubit(loginService, Flavor.piloto),
    act: (cubit) =>
        cubit.ingresar(usuario: 'miguelito.justiniano', contrasena: 'password'),
    verify: (cubit) {
      final estado = cubit.state;
      expect(estado, isA<LoginFallido>());
      expect((estado as LoginFallido).mensaje, contains('más de un rol'));
    },
  );

  blocTest<LoginCubit, LoginEstado>(
    'auxiliar + 409: emite LoginRequiereSeleccionRol con los roles del '
    'cuerpo, en vez del mensaje genérico',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginRolAmbiguo(_roles));
    },
    build: () => LoginCubit(loginService, Flavor.auxiliar),
    act: (cubit) =>
        cubit.ingresar(usuario: 'miguelito.justiniano', contrasena: 'password'),
    expect: () => [
      const LoginCargando(),
      const LoginRequiereSeleccionRol(_roles),
    ],
  );

  blocTest<LoginCubit, LoginEstado>(
    'auxiliar: único rol vivo, sin selector, directo a éxito',
    setUp: () {
      when(
        () => loginService.login(
          usuario: any(named: 'usuario'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) async => const LoginExitoso());
    },
    build: () => LoginCubit(loginService, Flavor.auxiliar),
    act: (cubit) =>
        cubit.ingresar(usuario: 'camila.rojas', contrasena: 'password'),
    expect: () => [const LoginCargando(), const LoginExitosoEstado()],
  );

  blocTest<LoginCubit, LoginEstado>(
    'elegirRol: reintenta el login con las credenciales retenidas más el '
    'role_id elegido',
    setUp: () {
      // Una sola stub, con la respuesta condicionada al `roleId` de la
      // invocación real: mocktail no distingue "no pasé roleId" de
      // "pasé roleId: null" entre dos `when()` separados (ambos matchean
      // con `any(named: ...)`), así que hay que ramificar adentro.
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
    },
    build: () => LoginCubit(loginService, Flavor.auxiliar),
    act: (cubit) async {
      await cubit.ingresar(
        usuario: 'miguelito.justiniano',
        contrasena: 'password',
      );
      await cubit.elegirRol(1);
    },
    expect: () => [
      const LoginCargando(),
      const LoginRequiereSeleccionRol(_roles),
      const LoginCargando(),
      const LoginExitosoEstado(),
    ],
    verify: (_) {
      verify(
        () => loginService.login(
          usuario: 'miguelito.justiniano',
          contrasena: 'password',
          roleId: 1,
        ),
      ).called(1);
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
    build: () => LoginCubit(loginService, Flavor.piloto),
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
    build: () => LoginCubit(loginService, Flavor.piloto),
    act: (cubit) =>
        cubit.ingresar(usuario: 'camila.rojas', contrasena: 'password'),
    expect: () => [
      const LoginCargando(),
      const LoginFallido('Sin conexión. Probá de nuevo cuando tengas señal.'),
    ],
  );
}
