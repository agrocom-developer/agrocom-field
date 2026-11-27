// Componentes compartidos del perfil: estrellas, cifras, filas, menú,
// calificaciones y ajustes (apariencia y cerrar sesión).

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/marketplace_ui.dart';
import 'package:agrocom_field/nucleo/ui/ajustes/ajustes_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_visual/tema_visual_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {TemaVisualCubit? tema}) {
  Widget app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      child: home,
    ),
  );
  if (tema != null) app = BlocProvider.value(value: tema, child: app);
  return app;
}

void main() {
  testWidgets('EstrellasPerfilCampo: 5 doradas, número y toque', (t) async {
    var tocado = false;
    await t.pumpWidget(
      _app(
        Scaffold(
          body: Center(
            child: Container(
              color: PaletaCampo.claro.cabecera,
              child: EstrellasPerfilCampo(valor: 5, onTap: () => tocado = true),
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.text('5,0'), findsOneWidget);
    expect(
      t.getSemantics(find.byType(EstrellasPerfilCampo)),
      matchesSemantics(
        label: 'Calificación 5,0 de 5, ver calificaciones',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      t.getSize(find.byType(EstrellasPerfilCampo)).height,
      greaterThanOrEqualTo(48),
    );
    await t.tap(find.byType(EstrellasPerfilCampo));
    expect(tocado, isTrue);
  });

  testWidgets('EstrellasPerfilCampo: 3,5 lleva media estrella', (t) async {
    await t.pumpWidget(
      _app(const Scaffold(body: EstrellasPerfilCampo(valor: 3.5))),
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('CifrasPerfilCampo: columnas iguales', (t) async {
    await t.pumpWidget(
      _app(
        const Scaffold(
          body: CifrasPerfilCampo(
            cifras: [
              (valor: '2', etiqueta: 'lotes'),
              (valor: '6', etiqueta: 'servicios'),
              (valor: '5,0', etiqueta: 'como cliente'),
            ],
          ),
        ),
      ),
    );
    final a = t.getCenter(find.text('2')).dx;
    final b = t.getCenter(find.text('6')).dx;
    final c = t.getCenter(find.text('5,0')).dx;
    expect(b - a, closeTo(c - b, 0.5));
  });

  testWidgets('FilaAccionCampo y FilaAjusteCampo: toque y pastilla', (t) async {
    var n = 0;
    await t.pumpWidget(
      _app(
        Scaffold(
          body: Column(
            children: [
              FilaAccionCampo(
                icono: Icons.flight_rounded,
                titulo: 'Dron y licencia',
                detalle: '2 drones',
                trailing: const PildoraContadorCampo(2),
                alToque: () => n++,
              ),
              FilaAjusteCampo(
                icono: Icons.palette_outlined,
                titulo: 'Apariencia',
                alToque: () => n += 10,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    await t.tap(find.text('Dron y licencia'));
    await t.tap(find.text('Apariencia'));
    expect(n, 11);
  });

  testWidgets('MenuPerfilCampo: abre y llama a la acción elegida', (t) async {
    var salio = false;
    await t.pumpWidget(
      _app(
        Scaffold(
          body: MenuPerfilCampo(alAjustes: () {}, alSalir: () => salio = true),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('perfil-menu')));
    await t.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Apariencia'), findsNothing);
    await t.tap(find.byKey(const Key('perfil-menu-salir')));
    await t.pumpAndSettle();
    expect(salio, isTrue);
  });

  group('CalificacionesPantalla', () {
    testWidgets('vacía: orienta', (t) async {
      await t.pumpWidget(
        _app(
          const CalificacionesPantalla(
            resumen: ResumenCalificaciones(
              promedio: 0,
              total: 0,
              recientes: [],
            ),
          ),
        ),
      );
      expect(find.text('Aún no hay calificaciones'), findsOneWidget);
    });

    testWidgets('con reseñas: promedio y comentario', (t) async {
      await t.pumpWidget(
        _app(
          CalificacionesPantalla(
            reloj: () => DateTime(2026, 11, 27),
            resumen: ResumenCalificaciones(
              promedio: 4.5,
              total: 2,
              porPuntaje: const {5: 1, 4: 1},
              recientes: [
                CalificacionRecibida(
                  servicioId: 's1',
                  autor: 'Rosario Antelo',
                  puntaje: 5,
                  fecha: DateTime(2026, 11, 20),
                  comentario: 'Muy puntual',
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('4,5'), findsOneWidget);
      expect(find.text('Rosario Antelo'), findsOneWidget);
      expect(find.text('Muy puntual'), findsOneWidget);
    });
  });

  group('Ajustes', () {
    testWidgets('Apariencia cambia el tema a Oscuro y lo guarda', (t) async {
      final almacen = AlmacenTemaVisualMemoria();
      final cubit = TemaVisualCubit(almacen);
      await t.pumpWidget(_app(const AjustesPantalla(), tema: cubit));
      await t.tap(find.byKey(const Key('ajustes-apariencia')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('apariencia-oscuro')));
      await t.pumpAndSettle();
      expect(cubit.state, ModoVisualCampo.oscuro);
      expect(almacen.modo, ModoVisualCampo.oscuro);
      await cubit.close();
    });

    testWidgets('Cerrar sesión pide confirmación', (t) async {
      var salio = false;
      await t.pumpWidget(_app(AjustesPantalla(alSalir: () => salio = true)));
      await t.tap(find.byKey(const Key('ajustes-cerrar-sesion')));
      await t.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(salio, isFalse);
      await t.tap(find.byKey(const Key('ajustes-cerrar-sesion')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('ajustes-confirmar-salida')));
      await t.pumpAndSettle();
      expect(salio, isTrue);
    });

    testWidgets('sin alSalir no hay grupo Cuenta', (t) async {
      await t.pumpWidget(_app(const AjustesPantalla()));
      expect(find.text('Cuenta'), findsNothing);
    });
  });
}
