import '../../../l10n/app_localizations.dart';
import '../domain/acceso_repositorio.dart';

/// Estado compartido por los formularios de ingreso y de registro.
class FormularioAccesoEstado {
  const FormularioAccesoEstado({
    this.enviando = false,
    this.fallo,
    this.porCampo = const {},
    this.sesion,
  });

  final bool enviando;

  /// Motivo del último intento fallido que no pertenece a un campo.
  final MotivoFalloAcceso? fallo;

  /// Errores que devolvió el servidor, por campo.
  final Map<CampoAcceso, String> porCampo;

  /// Sesión recién iniciada: la pantalla avisa hacia arriba y no muestra
  /// nada más.
  final SesionCliente? sesion;

  /// Mensaje para el aviso general, o `null` si no corresponde mostrarlo.
  String? mensajeFallo(AppLocalizations l10n) => switch (fallo) {
    null || MotivoFalloAcceso.validacion => null,
    MotivoFalloAcceso.credencialesInvalidas => l10n.accesoErrorCredenciales,
    MotivoFalloAcceso.sinConexion => l10n.accesoErrorSinConexion,
    MotivoFalloAcceso.desconocido => l10n.accesoErrorDesconocido,
  };

  bool get sinConexion => fallo == MotivoFalloAcceso.sinConexion;

  @override
  bool operator ==(Object other) =>
      other is FormularioAccesoEstado &&
      other.enviando == enviando &&
      other.fallo == fallo &&
      other.sesion == sesion &&
      other.porCampo.length == porCampo.length &&
      other.porCampo.entries.every((e) => porCampo[e.key] == e.value);

  @override
  int get hashCode => Object.hash(enviando, fallo, sesion, porCampo.length);
}
