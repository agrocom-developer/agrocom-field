import 'package:decimal/decimal.dart';

/// Reglas del formulario de solicitud que se validan en el dispositivo antes
/// de enviar. El servidor las vuelve a validar: estas solo evitan un viaje de
/// red que ya se sabe que va a fallar.
abstract final class ReglasSolicitud {
  /// Días de anticipación mínima: el servicio se pide, como pronto, para el
  /// día siguiente.
  static const anticipacionMinimaDias = 1;

  /// Cuántos días hacia adelante se ofrecen para elegir.
  static const diasOfrecidos = 14;

  /// Un pedido con menos de esta cantidad de días de anticipación es urgente
  /// y lleva recargo.
  static const diasUrgencia = 2;

  /// Superficie máxima de una sola solicitud, en hectáreas.
  static final hectareasMaximas = Decimal.fromInt(5000);

  static DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

  static int _diasHasta(DateTime fecha, DateTime ahora) =>
      // Entre fechas sin hora; se redondea porque un cambio de horario de
      // verano deja 23 o 25 horas entre dos medianoches.
      (_dia(fecha).difference(_dia(ahora)).inHours / 24).round();

  /// Fechas que se pueden elegir, de la más próxima a la más lejana.
  static List<DateTime> fechasDisponibles(DateTime ahora) => [
    for (var i = 0; i < diasOfrecidos; i++)
      DateTime(ahora.year, ahora.month, ahora.day + anticipacionMinimaDias + i),
  ];

  /// Mensaje si [fecha] no se puede pedir; `null` si es válida.
  static String? errorDeFecha(DateTime fecha, DateTime ahora) {
    final dias = _diasHasta(fecha, ahora);
    if (dias < anticipacionMinimaDias) {
      return 'Elige una fecha a partir de mañana.';
    }
    if (dias >= anticipacionMinimaDias + diasOfrecidos) {
      return 'Elige una fecha dentro de los próximos $diasOfrecidos días.';
    }
    return null;
  }

  static bool esUrgente(DateTime fecha, DateTime ahora) =>
      _diasHasta(fecha, ahora) < diasUrgencia;

  /// Interpreta lo que el cliente escribió como hectáreas («85,5» o «85.5»).
  /// Devuelve `null` si no es un número. Nunca pasa por `double`.
  static Decimal? parsearHectareas(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(limpio)) return null;
    return Decimal.tryParse(limpio);
  }

  /// Mensaje si el texto de hectáreas no sirve; `null` si es válido.
  static String? errorDeHectareas(String texto) {
    if (texto.trim().isEmpty) {
      return 'Indica cuántas hectáreas quieres fumigar.';
    }
    final valor = parsearHectareas(texto);
    if (valor == null) return 'Escribe un número, por ejemplo 85,5.';
    if (valor <= Decimal.zero) return 'La superficie tiene que ser mayor a 0.';
    if (valor.scale > 2) return 'Usa como máximo dos decimales.';
    if (valor > hectareasMaximas) {
      return 'Una solicitud admite hasta $hectareasMaximas ha.';
    }
    return null;
  }
}
