// Etapa 2 de HU-03: arranque de la app — sin token guardado muestra login,
// con token guardado salta directo al placeholder (que HU-04/HU-05
// reemplazan más adelante, fuera de esta tarea).

import 'package:agrocom_field/app.dart';
import 'package:agrocom_field/features/auth/login_cubit.dart';
import 'package:agrocom_field/nucleo/auth/login_service.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TokenStoreFalso extends Mock implements TokenStore {}

class _LoginServiceFalso extends Mock implements LoginService {}

void main() {
  late _TokenStoreFalso tokenStore;

  setUp(() {
    tokenStore = _TokenStoreFalso();
  });

  testWidgets('sin token guardado, arranca en la pantalla de login', (
    tester,
  ) async {
    when(() => tokenStore.leerToken()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      AgrocomApp(
        flavor: Flavor.piloto,
        tokenStore: tokenStore,
        crearLoginCubit: () => LoginCubit(_LoginServiceFalso()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_usuario')), findsOneWidget);
    expect(find.text('agrocom-field — piloto'), findsNothing);
  });

  testWidgets('con token guardado, salta el login y muestra el placeholder', (
    tester,
  ) async {
    when(() => tokenStore.leerToken()).thenAnswer((_) async => 'un-token');

    await tester.pumpWidget(
      AgrocomApp(
        flavor: Flavor.auxiliar,
        tokenStore: tokenStore,
        crearLoginCubit: () => LoginCubit(_LoginServiceFalso()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('agrocom-field — auxiliar'), findsOneWidget);
    expect(find.byKey(const Key('login_usuario')), findsNothing);
  });
}
