// La justificación del precio en la negociación del piloto: se escribe junto
// al precio por hectárea, viaja con la contraoferta y la contraparte la lee;
// el total se calcula y nunca se envía.

import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/negociacion_cubit.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AlmacenNegociacionDemo almacen;
  late NegociacionCubit cubit;

  setUp(() async {
    almacen = AlmacenNegociacionDemo(latencia: Duration.zero);
    cubit = NegociacionCubit(
      MercadoDemo(almacen),
      NegociacionDemo(almacen),
      AppLocalizationsEs(),
      solicitudId: 4,
    );
    await cubit.cargar();
  });

  tearDown(() => cubit.close());

  test('la justificación del cliente llega a la ronda correspondiente', () {
    final conJustificacion = cubit.state.rondas.where(
      (r) => r.justificacion != null,
    );
    expect(conJustificacion, isNotEmpty);
    expect(conJustificacion.single.justificacion, contains('lote es parejo'));
  });

  test('el total del panel es hectáreas por precio, en decimal exacto', () {
    cubit.cambiarPrecio(123);
    expect(cubit.state.total, cubit.state.hectareas! * Decimal.fromInt(123));
  });

  test('la contraoferta lleva la justificación normalizada', () async {
    expect(cubit.state.esMiTurno, isTrue);
    cubit.cambiarPrecio(130);
    cubit.cambiarJustificacion('  Incluye el\ntraslado   del dron ');
    await cubit.enviar();
    final mias = await NegociacionDemo(almacen).misOfertas();
    final nueva = mias.firstWhere(
      (o) => o.autor == AutorOferta.proveedor && o.solicitudId == 4,
    );
    expect(nueva.precioHa, Decimal.fromInt(130));
    expect(nueva.justificacionPrecio, 'Incluye el traslado del dron');
  });

  test('sin justificación no se manda ninguna', () async {
    cubit.cambiarPrecio(131);
    await cubit.enviar();
    final mias = await NegociacionDemo(almacen).misOfertas();
    final nueva = mias.firstWhere(
      (o) => o.autor == AutorOferta.proveedor && o.solicitudId == 4,
    );
    expect(nueva.justificacionPrecio, isNull);
  });
}
