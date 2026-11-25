import 'package:decimal/decimal.dart';

/// Formato de cantidades para mostrar. Todo parte de [Decimal]: nunca se
/// convierte a `double` para redondear (ADR 0002). Separador de miles con
/// punto y de decimales con coma, como se escribe en Bolivia.
abstract final class FormatoMarketplace {
  static String _agrupar(String entero) {
    final b = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) b.write('.');
      b.write(entero[i]);
    }
    return b.toString();
  }

  static String numero(Decimal valor, {int decimales = 2}) {
    final texto = valor.toStringAsFixed(decimales);
    final negativo = texto.startsWith('-');
    final limpio = negativo ? texto.substring(1) : texto;
    final partes = limpio.split('.');
    final entero = _agrupar(partes.first);
    final resultado = partes.length > 1 ? '$entero,${partes[1]}' : entero;
    return negativo ? '-$resultado' : resultado;
  }

  /// «Bs 10.800» (sin decimales cuando son cero) o «Bs 690,50».
  static String bs(Decimal monto) {
    final entero = monto.toStringAsFixed(2).endsWith('.00');
    return 'Bs ${numero(monto, decimales: entero ? 0 : 2)}';
  }

  /// Solo la cifra de un monto, sin «Bs»: «7.680» o «690,50». Va en mono
  /// junto a su unidad (`CifraCampo`).
  static String bsNumero(Decimal monto) {
    final entero = monto.toStringAsFixed(2).endsWith('.00');
    return numero(monto, decimales: entero ? 0 : 2);
  }

  /// Solo la cifra de unas hectáreas, sin «ha»: «120» o «85,5».
  static String hectareasNumero(Decimal valor) {
    final entera = valor.toStringAsFixed(1).endsWith('.0');
    return numero(valor, decimales: entera ? 0 : 1);
  }

  /// «120 ha» o «85,5 ha».
  static String hectareas(Decimal valor) {
    final entera = valor.toStringAsFixed(1).endsWith('.0');
    return '${numero(valor, decimales: entera ? 0 : 1)} ha';
  }

  static String litros(Decimal valor) {
    final entero = valor.toStringAsFixed(1).endsWith('.0');
    return '${numero(valor, decimales: entero ? 0 : 1)} L';
  }

  static String kilometros(Decimal valor) =>
      '${numero(valor, decimales: 1)} km';

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// «23 nov».
  static String fechaCorta(DateTime f) => '${f.day} ${_meses[f.month - 1]}';

  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  /// «lun».
  static String diaSemana(DateTime f) => _dias[f.weekday - 1];

  /// «lun 23 nov».
  static String fechaConDia(DateTime f) => '${diaSemana(f)} ${fechaCorta(f)}';

  /// «23 nov 2026».
  static String fechaLarga(DateTime f) => '${fechaCorta(f)} ${f.year}';

  static String hora(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  /// «hace 3 días», «hace 2 h», «hace 6 min».
  static String hace(DateTime f, DateTime ahora) {
    final d = ahora.difference(f);
    if (d.inDays >= 1) {
      return 'hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
    }
    if (d.inHours >= 1) return 'hace ${d.inHours} h';
    return 'hace ${d.inMinutes.clamp(0, 59)} min';
  }

  /// «1 h 14 min» o «32 min».
  static String duracionMinutos(int minutos) {
    if (minutos >= 1440) return '${minutos ~/ 1440} d';
    if (minutos >= 60) {
      final m = minutos % 60;
      return m == 0 ? '${minutos ~/ 60} h' : '${minutos ~/ 60} h $m min';
    }
    return '$minutos min';
  }
}
