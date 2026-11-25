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

  /// Un pedido con menos de esta cantidad de días de anticipación se marca
  /// como urgente para los pilotos. No lleva recargo: el precio lo negocian
  /// las partes.
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

  /// Qué falla del texto de hectáreas; `null` si es válido.
  static ErrorHectareas? errorDeHectareas(String texto) {
    if (texto.trim().isEmpty) {
      return ErrorHectareas.vacio;
    }
    final valor = parsearHectareas(texto);
    if (valor == null) return ErrorHectareas.noEsNumero;
    if (valor <= Decimal.zero) return ErrorHectareas.noPositivo;
    if (valor.scale > 2) return ErrorHectareas.decimales;
    if (valor > hectareasMaximas) return ErrorHectareas.sobreMaximo;
    return null;
  }

  /// Interpreta lo que el cliente escribió como precio por hectárea («120»
  /// o «118,50»). Nunca pasa por `double`.
  static Decimal? parsearPrecio(String texto) => parsearHectareas(texto);

  /// Qué falla del precio por hectárea; `null` si es válido. El
  /// servidor vuelve a validar el máximo de sanidad.
  static ErrorPrecio? errorDePrecio(String texto) {
    if (texto.trim().isEmpty) {
      return ErrorPrecio.vacio;
    }
    final valor = parsearPrecio(texto);
    if (valor == null) return ErrorPrecio.noEsNumero;
    if (valor <= Decimal.zero) return ErrorPrecio.noPositivo;
    if (valor.scale > 2) return ErrorPrecio.decimales;
    return null;
  }
}

/// Por qué no sirve el texto de hectáreas. La pantalla lo traduce a texto.
enum ErrorHectareas {
  vacio,
  noEsNumero,
  noPositivo,
  decimales,
  sobreMaximo,

  /// Pide más hectáreas de las que tiene el lote guardado.
  sobreLote,
}

/// Por qué no sirve el precio por hectárea. La pantalla lo traduce a texto.
enum ErrorPrecio { vacio, noEsNumero, noPositivo, decimales }
