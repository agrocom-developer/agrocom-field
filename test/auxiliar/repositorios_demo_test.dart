import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/auxiliar/demo/almacen_demo_auxiliar.dart';
import 'package:agrocom_field/auxiliar/mezcla/data/mezcla_demo.dart';

void main() {
  test(
    'registrar una mezcla la agrega al instante con su uuid de cliente',
    () async {
      final repo = MezclaDemo(AlmacenDemoAuxiliar());
      final antes = (await repo.observar().first);
      await repo.registrar(
        producto: 'Fungicida',
        litros: Decimal.parse('88.5'),
      );
      final despues = await repo.observar().first;
      expect(despues.length, antes.length + 1);
      final nueva = despues.first;
      expect(nueva.litros, Decimal.parse('88.5'));
      expect(nueva.sincronizado, isFalse);
      expect(
        antes.map((m) => m.uuidCliente),
        isNot(contains(nueva.uuidCliente)),
      );
    },
  );
}
