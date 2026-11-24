// Conductor de las pruebas de captura de QA visual. Las capturas las toma
// `tool/capturar_pantallas.sh` con `xcrun simctl io`; acá solo se reporta el
// resultado de la prueba.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
