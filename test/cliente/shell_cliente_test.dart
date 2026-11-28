import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/nucleo/ui/tema_visual/tema_visual_cubit.dart';
import 'package:agrocom_field/nucleo/ui/componentes/barra_inferior_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';

import '../nucleo/marketplace/ayudas_prueba.dart';

// Con el reloj real: las pantallas de ofertas y seguimiento calculan lo que
// falta con la hora del dispositivo, y la demo parte de esa misma hora.
DependenciasCliente _demo() => DependenciasCliente.demo(
  almacen: AlmacenDemoCliente(),
  latencia: Duration.zero,
);

void main() {
  testWidgets('el inicio muestra la solicitud con ofertas y la por calificar', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(
        dependencias: _demo(),
        almacenTema: AlmacenTemaVisualMemoria(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, Hugo'), findsOneWidget);
    expect(find.text('Publicar lote'), findsOneWidget);
    expect(find.text('SOLICITUD ACTIVA'), findsOneWidget);
    expect(find.text('Comparar ofertas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Calificar'), 300);
    expect(find.text('Calificar'), findsWidgets);
    expect(find.byType(BarraInferiorCampo), findsOneWidget);
  });

  testWidgets('publicar una solicitud en cuatro pasos la deja abierta', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(
        dependencias: _demo(),
        almacenTema: AlmacenTemaVisualMemoria(),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tocar(Finder objetivo) async {
      await tester.scrollUntilVisible(
        objetivo,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(objetivo);
      await tester.pumpAndSettle();
      await tester.tap(objetivo);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Publicar lote'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 4 · Lote'), findsOneWidget);

    await tocar(find.text('Maíz La Curva'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 4 · Aplicación'), findsOneWidget);

    await tocar(find.text('Insecticida piretroide'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 4 · Cuándo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fecha-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 4 de 4 · Precio'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('solicitar-precio')),
      '120',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('10.260', findRichText: true), findsWidgets);
    await tester.tap(find.text('Publicar solicitud').last);
    await tester.pumpAndSettle();

    // Abre el detalle de la solicitud, abierta y todavía sin ofertas.
    expect(find.text('Buscando piloto'), findsWidgets);
    expect(find.text('Tu precio'), findsOneWidget);
    expect(find.byKey(const ValueKey('precio-propuesto')), findsOneWidget);
    expect(find.text('Maíz La Curva'), findsWidgets);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Hugo'), findsOneWidget);
  });

  testWidgets('comparar las ofertas y elegir un piloto lleva al seguimiento', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(
        dependencias: _demo(),
        almacenTema: AlmacenTemaVisualMemoria(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comparar ofertas'));
    await tester.pumpAndSettle();
    expect(find.text('Comparar ofertas'), findsWidgets);
    // Las tres ofertas, la de menor precio primero y marcada.
    expect(find.byKey(const ValueKey('oferta-of-4101-b')), findsOneWidget);
    expect(find.text('ELEGIDO'), findsOneWidget);
    expect(find.textContaining('104', findRichText: true), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('aceptar-of-4101-b')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('aceptar-of-4101-b')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Las demás ofertas se cierran'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirmar-aceptar')));
    await tester.pumpAndSettle();

    expect(find.text('Servicio en curso'), findsOneWidget);
    expect(find.text('Piloto confirmado'), findsWidgets);
    expect(find.byKey(const ValueKey('abrir-chat')), findsOneWidget);
  });

  testWidgets('en iPad la navegación pasa a riel lateral', (tester) async {
    prepararIpad(tester);
    await tester.pumpWidget(
      AppCliente(
        dependencias: _demo(),
        almacenTema: AlmacenTemaVisualMemoria(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BarraInferiorCampo), findsNothing);
  });

  testWidgets('las pestañas Servicios, Lotes y Perfil cargan sus datos', (
    tester,
  ) async {
    prepararTelefono(tester);
    await tester.pumpWidget(
      AppCliente(
        dependencias: _demo(),
        almacenTema: AlmacenTemaVisualMemoria(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    expect(find.text('Mis solicitudes'), findsOneWidget);
    await tester.tap(find.text('Lotes').last);
    await tester.pumpAndSettle();
    expect(find.text('Maíz La Curva'), findsOneWidget);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('Hugo Antelo Suárez'), findsOneWidget);
    // El perfil ya no lista los lotes (viven en su pestaña); sí las secciones.
    expect(find.text('Métricas'), findsOneWidget);
    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('Mis lotes'), findsNothing);
  });

  testWidgets('el perfil cambia el tema y lo guarda', (tester) async {
    prepararTelefono(tester);
    final almacen = AlmacenTemaVisualMemoria();
    await tester.pumpWidget(
      AppCliente(dependencias: _demo(), almacenTema: almacen),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ajustes-apariencia')));
    await tester.pumpAndSettle();
    final campo = find.text('Oscuro');
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    await tester.tap(campo);
    await tester.pumpAndSettle();
    expect(almacen.modo, ModoVisualCampo.oscuro);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFF0F1A13));
  });
}
