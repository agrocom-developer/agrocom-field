import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/precio_final/data/precio_final_demo.dart';
import 'package:agrocom_field/cliente/precio_final/domain/precio_final_repositorio.dart';
import 'package:agrocom_field/cliente/precio_final/presentation/precio_final_cubit.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/precio_final_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

import '../../ui/ui_negociacion_cliente/ayudas.dart';

class _SinRed implements PrecioFinalRepositorio {
  @override
  Future<Never> ver(String solicitudId) async => throw const SinConexion();

  @override
  Future<Never> confirmar(String solicitudId) async =>
      throw const SinConexion();
}

void main() {
  testWidgets('el ticket queda «por confirmar» y el cliente lo confirma', (
    tester,
  ) async {
    await montar(
      tester,
      pantalla: const PrecioFinalPantalla(solicitudId: '4103'),
      dependencias: dependenciasDePrueba(almacenDePrueba()),
    );
    await asentar(tester);
    expect(find.text('POR CONFIRMAR'), findsOneWidget);
    final confirmar = find.byKey(const ValueKey('confirmar-precio-final'));
    expect(confirmar, findsOneWidget);
    await tester.tap(confirmar);
    await asentar(tester);
    expect(find.text('CONFIRMADO'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('aviso-precio-confirmado')),
      findsOneWidget,
    );
    expect(confirmar, findsNothing);
  });

  test(
    'el cubit confirma una sola vez y el reintento devuelve lo mismo',
    () async {
      final repo = PrecioFinalDemo(almacenDePrueba());
      final cubit = PrecioFinalCubit(repo, '4103');
      await cubit.cargar();
      expect(cubit.state.precio?.confirmado, isFalse);
      expect(await cubit.confirmar(), isTrue);
      final primera = cubit.state.precio!.confirmadoEn;
      expect(await cubit.confirmar(), isTrue);
      expect(cubit.state.precio!.confirmadoEn, primera);
      await cubit.close();
    },
  );

  test('un servicio sin terminar no se puede confirmar', () async {
    final repo = PrecioFinalDemo(almacenDePrueba());
    expect(await repo.ver('4101'), isNull);
    expect(repo.confirmar('4101'), throwsA(isA<OperacionRechazada>()));
  });

  test('sin red el cubit lo dice y no confirma', () async {
    final cubit = PrecioFinalCubit(_SinRed(), '4103');
    await cubit.cargar();
    expect(cubit.state.fallo, FalloPrecioFinal.sinConexion);
    expect(await cubit.confirmar(), isFalse);
    await cubit.close();
  });
}
