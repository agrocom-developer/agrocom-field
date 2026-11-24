import '../evidencias/compresor_adaptativo.dart' show topeBytesEvidencia;
import 'dominio/falla.dart';

/// Comprueba que una foto ya comprimida cabe en el tope del servidor (menos
/// de 300 KB, invariante 7). Una foto mayor ni se envía: el servidor la
/// rechazaría con `422` y el usuario esperaría para nada.
void validarTamanoDeFoto(List<int> bytes) {
  if (bytes.isEmpty) {
    throw const OperacionRechazada('La foto está vacía. Elige otra.');
  }
  if (bytes.length >= topeBytesEvidencia) {
    throw const OperacionRechazada(
      'La foto es muy pesada. Elige otra o toma una nueva.',
    );
  }
}
