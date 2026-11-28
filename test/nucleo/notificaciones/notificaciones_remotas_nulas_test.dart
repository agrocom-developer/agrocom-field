import 'package:agrocom_field/nucleo/notificaciones/remotas/notificaciones_remotas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sin proveedor: no configurado, sin token y sin avisos', () async {
    const remotas = NotificacionesRemotasNulas();
    expect(await remotas.estado(), EstadoPushRemoto.noConfigurado);
    expect(await remotas.obtenerToken(), isNull);
    expect(await remotas.avisos.isEmpty, isTrue);
  });
}
