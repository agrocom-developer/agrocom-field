import 'package:agrocom_field/nucleo/entorno/info_entorno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfoEntorno.hostDe', () {
    test('conserva el puerto explícito de un entorno local', () {
      expect(InfoEntorno.hostDe('http://192.168.0.3:8000'), '192.168.0.3:8000');
      expect(InfoEntorno.hostDe('http://10.0.2.2:8000'), '10.0.2.2:8000');
    });

    test('deja solo el host cuando la URL usa el puerto del esquema', () {
      expect(
        InfoEntorno.hostDe('https://api.agrocom.com.ar/'),
        'api.agrocom.com.ar',
      );
      expect(
        InfoEntorno.hostDe('https://staging.agrocom.com.ar/api'),
        'staging.agrocom.com.ar',
      );
    });

    test('devuelve el texto tal cual si no parsea como URL con host', () {
      expect(InfoEntorno.hostDe('sin-esquema'), 'sin-esquema');
      expect(InfoEntorno.hostDe(''), '');
    });
  });
}
