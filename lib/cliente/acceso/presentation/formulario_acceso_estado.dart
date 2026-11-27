import '../../../l10n/app_localizations.dart';
import '../../../nucleo/auth/cuenta/presentation/textos_cuenta_seguridad.dart';
import '../domain/acceso_repositorio.dart';

/// Estado compartido por los formularios de ingreso y de registro.
class FormularioAccesoEstado {
  const FormularioAccesoEstado({
    this.enviando = false,
    this.fallo,
    this.porCampo = const {},
    this.sesion,
    this.esperaSegundos = 0,
    this.tipoCuenta,
  });

  final bool enviando;

  /// Motivo del último intento fallido que no pertenece a un campo.
  final MotivoFalloAcceso? fallo;

  /// Errores que devolvió el servidor, por campo.
  final Map<CampoAcceso, String> porCampo;

  /// Sesión recién iniciada: la pantalla avisa hacia arriba y no muestra
  /// nada más.
  final SesionCliente? sesion;

  /// Segundos que faltan para poder reintentar tras un `429`.
  final int esperaSegundos;

  /// `tipo_cuenta` de un `409 cuenta_ya_registrada`.
  final String? tipoCuenta;

  /// Mensaje para el aviso general, o `null` si no corresponde mostrarlo.
  String? mensajeFallo(AppLocalizations l10n) => switch (fallo) {
    null ||
    MotivoFalloAcceso.validacion ||
    MotivoFalloAcceso.cuentaYaRegistrada => null,
    MotivoFalloAcceso.demasiadosIntentos =>
      esperaSegundos > 0
          ? l10n.cuentaDemasiadosIntentosEn(
              TextosCuentaSeguridad.espera(esperaSegundos),
            )
          : l10n.cuentaDemasiadosIntentosEspera,
    MotivoFalloAcceso.credencialesInvalidas => l10n.accesoErrorCredenciales,
    MotivoFalloAcceso.sinConexion => l10n.accesoErrorSinConexion,
    MotivoFalloAcceso.desconocido => l10n.accesoErrorDesconocido,
  };

  bool get sinConexion => fallo == MotivoFalloAcceso.sinConexion;

  /// Hay una cuenta regresiva en curso: el botón de ingresar espera.
  bool get enEspera => esperaSegundos > 0;

  @override
  bool operator ==(Object other) =>
      other is FormularioAccesoEstado &&
      other.enviando == enviando &&
      other.fallo == fallo &&
      other.sesion == sesion &&
      other.esperaSegundos == esperaSegundos &&
      other.tipoCuenta == tipoCuenta &&
      other.porCampo.length == porCampo.length &&
      other.porCampo.entries.every((e) => porCampo[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    enviando,
    fallo,
    sesion,
    porCampo.length,
    esperaSegundos,
    tipoCuenta,
  );
}
