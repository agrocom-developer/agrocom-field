// Contraste WCAG de cada par rol/superficie de la paleta, en los tres modos.
// Si un color se toca y deja de cumplir, este test lo dice antes que un
// usuario bajo el sol.

import 'package:agrocom_field/nucleo/ui/contraste_wcag.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/tokens_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el contraste de referencia de la fórmula coincide con el estándar', () {
    expect(ContrasteWcag.ratio(Colors.black, Colors.white), closeTo(21, 0.001));
    expect(ContrasteWcag.ratio(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  for (final modo in ModoVisualCampo.values) {
    final p = PaletaCampo.deModo(modo);
    group('paleta ${modo.name}', () {
      test('texto cumple AAA sobre fondo y superficies', () {
        for (final base in [p.fondo, p.superficie, p.superficieElevada]) {
          expect(
            ContrasteWcag.ratio(p.texto, base),
            greaterThanOrEqualTo(ContrasteWcag.aaaTexto),
          );
        }
      });

      test('texto secundario cumple AA sobre fondo y superficies', () {
        for (final base in [p.fondo, p.superficie, p.superficieElevada]) {
          expect(
            ContrasteWcag.ratio(p.textoSecundario, base),
            greaterThanOrEqualTo(ContrasteWcag.aaTexto),
          );
        }
      });

      test('acento: texto sobre el relleno y acento como texto cumplen AA', () {
        expect(
          ContrasteWcag.ratio(p.sobreAcento, p.acento),
          greaterThanOrEqualTo(ContrasteWcag.aaTexto),
        );
        for (final base in [p.fondo, p.superficie]) {
          expect(
            ContrasteWcag.ratio(p.acentoTexto, base),
            greaterThanOrEqualTo(ContrasteWcag.aaTexto),
          );
        }
      });

      test('éxito, alerta, error e info cumplen AA como texto', () {
        for (final color in [p.exito, p.alerta, p.error, p.info]) {
          for (final base in [p.fondo, p.superficie]) {
            expect(
              ContrasteWcag.ratio(color, base),
              greaterThanOrEqualTo(ContrasteWcag.aaTexto),
            );
          }
        }
      });

      test('el borde de controles cumple 3:1 contra fondo y superficie', () {
        for (final base in [p.fondo, p.superficie]) {
          expect(
            ContrasteWcag.ratio(p.bordeFuerte, base),
            greaterThanOrEqualTo(ContrasteWcag.aaComponente),
          );
        }
      });
    });
  }

  test('el modo campo supera el contraste del modo oscuro en texto', () {
    expect(
      ContrasteWcag.ratio(
        PaletaCampo.campo.textoSecundario,
        PaletaCampo.campo.fondo,
      ),
      greaterThan(
        ContrasteWcag.ratio(
          PaletaCampo.oscuro.textoSecundario,
          PaletaCampo.oscuro.fondo,
        ),
      ),
    );
  });

  test('construir() instala la paleta del modo en el tema', () {
    final tema = AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro);
    expect(tema.extension<PaletaCampo>(), PaletaCampo.claro);
    expect(tema.brightness, Brightness.light);
    // Sin argumentos conserva el modo campo (tema de la app).
    expect(
      AgrocomThemeCampo.construir().extension<PaletaCampo>(),
      PaletaCampo.campo,
    );
  });

  test('lerp interpola entre paletas', () {
    final mitad = PaletaCampo.claro.lerp(PaletaCampo.oscuro, 0.5);
    expect(
      mitad.fondo,
      Color.lerp(PaletaCampo.claro.fondo, PaletaCampo.oscuro.fondo, 0.5),
    );
  });

  test('las duraciones de interacción no superan 300 ms salvo la lenta', () {
    expect(MovimientoCampo.toque, lessThan(const Duration(milliseconds: 300)));
    expect(MovimientoCampo.rapida, lessThan(const Duration(milliseconds: 300)));
    expect(MovimientoCampo.media, lessThan(const Duration(milliseconds: 300)));
  });

  test('las clases de pantalla cortan en 600 y 840', () {
    expect(ClasePantallaCampo.deAncho(390), ClasePantallaCampo.compacto);
    expect(ClasePantallaCampo.deAncho(600), ClasePantallaCampo.medio);
    expect(ClasePantallaCampo.deAncho(834), ClasePantallaCampo.medio);
    expect(ClasePantallaCampo.deAncho(1194), ClasePantallaCampo.expandido);
  });

  testWidgets('movimiento reducido anula la duración', (tester) async {
    late Duration normal;
    late Duration reducido;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reducido = MovimientoCampo.duracion(context, MovimientoCampo.media);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            normal = MovimientoCampo.duracion(context, MovimientoCampo.media);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(reducido, Duration.zero);
    expect(normal, MovimientoCampo.media);
  });
}
