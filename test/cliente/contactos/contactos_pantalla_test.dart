import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/contactos/data/contactos_demo.dart';
import 'package:agrocom_field/cliente/contactos/domain/contacto.dart';
import 'package:agrocom_field/cliente/contactos/presentation/contactos_pantalla.dart';
import 'package:agrocom_field/cliente/cuenta/presentation/cuenta_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/ui/tema_visual/tema_visual_cubit.dart';

import '../../ui/ui_negociacion_cliente/ayudas.dart';

Future<ContactosDemo> _abrir(
  WidgetTester tester, {
  List<ContactoCliente>? iniciales,
}) async {
  final contactos = ContactosDemo(iniciales: iniciales);
  await montar(
    tester,
    pantalla: const ContactosPantalla(),
    dependencias: dependenciasDePrueba(almacenDePrueba(), contactos: contactos),
  );
  await asentar(tester);
  return contactos;
}

void main() {
  testWidgets('lista los contactos con el principal marcado', (tester) async {
    await _abrir(tester);
    expect(find.text('Rosario Antelo Vaca'), findsOneWidget);
    expect(find.text('Gerente'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Mario Suárez Rojas'), findsOneWidget);
  });

  testWidgets('agregar un contacto lo suma a la lista', (tester) async {
    final repo = await _abrir(tester);
    await tester.tap(find.byKey(const ValueKey('contacto-agregar')));
    await asentar(tester);
    await tester.enterText(
      find.byKey(const ValueKey('contacto-nombre')),
      'Elena Chávez Soliz',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contacto-celular')),
      '+591 70011223',
    );
    await tester.tap(find.byKey(const ValueKey('contacto-guardar')));
    await asentar(tester);
    expect(find.text('Elena Chávez Soliz'), findsOneWidget);
    expect((await repo.listar()).length, 3);
  });

  testWidgets('la hoja marca el nombre y el celular vacíos', (tester) async {
    await _abrir(tester);
    await tester.tap(find.byKey(const ValueKey('contacto-agregar')));
    await asentar(tester);
    await tester.tap(find.byKey(const ValueKey('contacto-guardar')));
    await asentar(tester);
    expect(find.text('Escribe el nombre.'), findsOneWidget);
    expect(
      find.text('Escribe un celular de al menos 7 dígitos.'),
      findsOneWidget,
    );
  });

  testWidgets('el único contacto no se puede quitar', (tester) async {
    await _abrir(
      tester,
      iniciales: const [
        ContactoCliente(
          id: 1,
          nombre: 'Rosario Antelo Vaca',
          telefono: '+591 76543210',
          esPrincipal: true,
        ),
      ],
    );
    final quitar = tester.widget<IconButton>(
      find.byKey(const ValueKey('contacto-quitar-1')),
    );
    expect(quitar.onPressed, isNull);
    expect(find.textContaining('al menos un contacto'), findsWidgets);
  });

  testWidgets('quitar al principal releva al siguiente', (tester) async {
    final repo = await _abrir(tester);
    await tester.tap(find.byKey(const ValueKey('contacto-quitar-1')));
    await asentar(tester);
    await tester.tap(find.byKey(const ValueKey('contacto-confirmar-quitar')));
    await asentar(tester);
    final lista = await repo.listar();
    expect(lista.single.id, 2);
    expect(lista.single.esPrincipal, isTrue);
  });

  test(
    'ContactosDemo imita al servidor: una empresa no queda sin contactos',
    () {
      final repo = ContactosDemo(
        iniciales: const [
          ContactoCliente(id: 1, nombre: 'A', telefono: '1', esPrincipal: true),
        ],
      );
      expect(repo.darDeBaja(1), throwsA(isA<OperacionRechazada>()));
    },
  );

  testWidgets('el perfil de una empresa ofrece sus contactos', (tester) async {
    await montar(
      tester,
      pantalla: BlocProvider(
        create: (_) => TemaVisualCubit(AlmacenTemaVisualMemoria()),
        child: const Scaffold(body: CuentaPantalla()),
      ),
      dependencias: dependenciasDePrueba(almacenDePrueba()),
    );
    await asentar(tester);
    final fila = find.byKey(const Key('perfil-contactos'));
    await tester.scrollUntilVisible(fila, 200);
    await asentar(tester);
    expect(fila, findsOneWidget);
    expect(find.text('2 personas'), findsOneWidget);
  });
}
