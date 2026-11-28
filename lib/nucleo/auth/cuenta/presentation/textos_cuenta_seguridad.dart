import '../../../../l10n/app_localizations.dart';
import '../domain/cuenta_seguridad.dart';

/// Textos de las pantallas de seguridad de la cuenta, en español y sin jerga,
/// leídos de `AppLocalizations` (ADR 0022). Los errores dicen qué hacer; un
/// canal caído nunca se atribuye a la persona.
abstract final class TextosCuentaSeguridad {
  static String canal(AppLocalizations l10n, CanalCodigo c) => switch (c) {
    CanalCodigo.whatsapp => l10n.cuentaCanalWhatsApp,
    CanalCodigo.sms => l10n.cuentaCanalSms,
    CanalCodigo.correo => l10n.cuentaCanalCorreo,
  };

  static String detalleCanal(AppLocalizations l10n, CanalCodigo c) =>
      switch (c) {
        CanalCodigo.whatsapp => l10n.cuentaCanalWhatsAppDetalle,
        CanalCodigo.sms => l10n.cuentaCanalSmsDetalle,
        CanalCodigo.correo => l10n.cuentaCanalCorreoDetalle,
      };

  /// «02:05»: cuenta regresiva de reenvío.
  static String espera(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Texto de la falla; [alternativas] son los canales que aún se pueden
  /// elegir (para sugerir uno cuando el elegido no está disponible).
  static String falla(
    AppLocalizations l10n,
    CuentaFalla falla, {
    List<CanalCodigo> alternativas = const [],
  }) => switch (falla) {
    CuentaSinConexion() => l10n.cuentaFallaSinConexion,
    CuentaCodigoInvalido() => l10n.cuentaFallaCodigoInvalido,
    CuentaContrasenaIncorrecta() => l10n.cuentaFallaContrasenaIncorrecta,
    CuentaSinDestino(:final canal) =>
      canal == CanalCodigo.correo
          ? l10n.cuentaFallaSinCorreo
          : l10n.cuentaFallaSinTelefono,
    CuentaCanalNoDisponible(:final canal) => l10n.cuentaFallaCanalNoDisponible(
      canal == null ? l10n.cuentaFallaEseMedio : _canal(l10n, canal),
      alternativas.isEmpty
          ? l10n.cuentaFallaReintentarEnUnMomento
          : l10n.cuentaFallaRecibirPor(_lista(l10n, alternativas)),
    ),
    CuentaLimiteExcedido() => l10n.cuentaFallaLimiteExcedido,
    CuentaTelefonoYaVerificado() => l10n.cuentaFallaTelefonoYaVerificado,
    CuentaEliminacionBloqueada() => l10n.cuentaFallaEliminacionBloqueada,
    CuentaDatosInvalidos(:final mensaje) =>
      mensaje ?? l10n.cuentaFallaDatosInvalidos,
    CuentaSesionVencida() => l10n.cuentaFallaSesionVencida,
    CuentaEnEliminacion() => l10n.cuentaFallaEnEliminacion,
    CuentaErrorDesconocido() => l10n.cuentaFallaDesconocida,
  };

  static String _canal(AppLocalizations l10n, CanalCodigo c) => canal(l10n, c);

  static String _lista(AppLocalizations l10n, List<CanalCodigo> canales) {
    final nombres = [for (final c in canales) canal(l10n, c)];
    if (nombres.length == 1) return nombres.first;
    return l10n.cuentaListaMediosO(
      nombres.sublist(0, nombres.length - 1).join(', '),
      nombres.last,
    );
  }

  static ({String titulo, String salida}) impedimento(
    AppLocalizations l10n,
    ImpedimentoEliminacion i,
  ) => switch (i) {
    ImpedimentoEliminacion.servicioEnCurso => (
      titulo: l10n.cuentaImpedimentoServicioTitulo,
      salida: l10n.cuentaImpedimentoServicioSalida,
    ),
    ImpedimentoEliminacion.reclamoAbierto => (
      titulo: l10n.cuentaImpedimentoReclamoTitulo,
      salida: l10n.cuentaImpedimentoReclamoSalida,
    ),
    ImpedimentoEliminacion.pilotosVinculados => (
      titulo: l10n.cuentaImpedimentoPilotosTitulo,
      salida: l10n.cuentaImpedimentoPilotosSalida,
    ),
  };

  /// Lo que se borra al eliminar la cuenta (ADR 0047, punto 6).
  static List<String> seBorra(AppLocalizations l10n) => [
    l10n.cuentaSeBorra1,
    l10n.cuentaSeBorra2,
    l10n.cuentaSeBorra3,
    l10n.cuentaSeBorra4,
    l10n.cuentaSeBorra5,
  ];

  /// Lo que se conserva, sin identificarte.
  static List<String> seConserva(AppLocalizations l10n) => [
    l10n.cuentaSeConserva1,
    l10n.cuentaSeConserva2,
    l10n.cuentaSeConserva3,
  ];

  static String efectosInmediatos(AppLocalizations l10n) =>
      l10n.cuentaEfectosInmediatos;

  static String graciaDias(AppLocalizations l10n) => l10n.cuentaGraciaDias;
}
