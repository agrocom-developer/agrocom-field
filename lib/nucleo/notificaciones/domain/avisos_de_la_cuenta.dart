import 'aviso.dart';
import 'presentador_avisos.dart';

/// Lo que una app necesita para mostrar los avisos de la cuenta: la bandeja
/// y, si hay, quien los presenta como notificación del sistema. Se provee una
/// vez en el árbol y la campana del encabezado lo lee.
class AvisosDeLaCuenta {
  const AvisosDeLaCuenta({required this.bandeja, this.presentador});

  final BandejaRepositorio bandeja;
  final PresentadorAvisos? presentador;
}
