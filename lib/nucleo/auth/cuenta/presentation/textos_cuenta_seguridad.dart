import '../domain/cuenta_seguridad.dart';

/// Textos de las pantallas de seguridad de la cuenta, en español y sin jerga.
/// Los errores dicen qué hacer; un canal caído nunca se atribuye a la persona.
abstract final class TextosCuentaSeguridad {
  static String canal(CanalCodigo c) => switch (c) {
    CanalCodigo.whatsapp => 'WhatsApp',
    CanalCodigo.sms => 'SMS',
    CanalCodigo.correo => 'Correo',
  };

  static String detalleCanal(CanalCodigo c) => switch (c) {
    CanalCodigo.whatsapp => 'Al teléfono de tu cuenta',
    CanalCodigo.sms => 'Mensaje de texto al teléfono de tu cuenta',
    CanalCodigo.correo => 'Al correo de respaldo de tu cuenta',
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
    CuentaFalla falla, {
    List<CanalCodigo> alternativas = const [],
  }) => switch (falla) {
    CuentaSinConexion() =>
      'No hay conexión. Revisa tu señal y vuelve a intentarlo: lo que '
          'escribiste se conserva.',
    CuentaCodigoInvalido() =>
      'El código no es válido o ya venció. Revisa los 6 dígitos o pide uno '
          'nuevo.',
    CuentaContrasenaIncorrecta() =>
      'Esa contraseña no es la de tu cuenta. Revísala o confirma con un '
          'código.',
    CuentaSinDestino(:final canal) =>
      canal == CanalCodigo.correo
          ? 'Tu cuenta no tiene un correo de respaldo. Elige otro medio.'
          : 'Tu cuenta no tiene un teléfono para ese medio. Elige otro.',
    CuentaCanalNoDisponible(:final canal) =>
      '${canal == null ? 'Ese medio' : TextosCuentaSeguridad.canal(canal)} '
          'no está disponible por ahora; no es un problema de tu cuenta. '
          '${alternativas.isEmpty ? 'Vuelve a intentarlo en un momento.' : 'Recibe el código por ${_lista(alternativas)}.'}',
    CuentaLimiteExcedido() =>
      'Pediste varios códigos seguidos. Espera un momento antes de pedir '
          'otro.',
    CuentaTelefonoYaVerificado() => 'Tu teléfono ya está verificado.',
    CuentaEliminacionBloqueada() =>
      'No puedes eliminar tu cuenta todavía. Resuelve lo pendiente y vuelve '
          'a intentarlo.',
    CuentaDatosInvalidos(:final mensaje) =>
      mensaje ?? 'Revisa los datos e inténtalo de nuevo.',
    CuentaSesionVencida() => 'Tu sesión venció. Ingresa de nuevo.',
    CuentaEnEliminacion() =>
      'Tu cuenta está en proceso de eliminación. Puedes conservarla desde '
          'aquí.',
    CuentaErrorDesconocido() =>
      'No pudimos completar esto. Inténtalo de nuevo en un momento.',
  };

  static String _lista(List<CanalCodigo> canales) {
    final nombres = [for (final c in canales) canal(c)];
    if (nombres.length == 1) return nombres.first;
    return '${nombres.sublist(0, nombres.length - 1).join(', ')} o '
        '${nombres.last}';
  }

  static ({String titulo, String salida}) impedimento(
    ImpedimentoEliminacion i,
  ) => switch (i) {
    ImpedimentoEliminacion.servicioEnCurso => (
      titulo: 'Tienes un servicio adjudicado o en ejecución',
      salida: 'Termínalo o cancélalo desde Servicios y vuelve a esta pantalla.',
    ),
    ImpedimentoEliminacion.reclamoAbierto => (
      titulo: 'Hay un reclamo abierto en el que participas',
      salida: 'Espera a que se resuelva; después podrás eliminar tu cuenta.',
    ),
    ImpedimentoEliminacion.pilotosVinculados => (
      titulo: 'Tu empresa tiene pilotos vinculados',
      salida:
          'Libéralos o pide a un administrador de Agrocom el cambio de '
          'encargado.',
    ),
  };

  /// Lo que se borra al eliminar la cuenta (ADR 0047, punto 6).
  static const List<String> seBorra = [
    'Tu nombre, usuario, teléfono y correo.',
    'Tu foto de perfil.',
    'Tus lotes, fotos de terreno y datos de empresa que no estén en un '
        'servicio vigente.',
    'Tus sesiones en todos los dispositivos.',
    'El texto de los mensajes que escribiste.',
  ];

  /// Lo que se conserva, sin identificarte.
  static const List<String> seConserva = [
    'El registro de cada servicio: precio acordado, hectáreas y fechas. Tu '
        'nombre aparece como «Cuenta eliminada».',
    'El puntaje de las calificaciones, sin tu nombre y sin comentarios.',
    'Lo que la ley o la prevención de fraude exigen, por un plazo limitado '
        'y declarado.',
  ];

  static const String efectosInmediatos =
      'Al confirmar, se cierran tus sesiones, se cancelan tus solicitudes '
      'abiertas y se retiran tus ofertas vigentes. Eso no se restaura si '
      'cambias de opinión.';

  static const String graciaDias =
      'Tienes 7 días para arrepentirte. En ese plazo puedes iniciar sesión '
      'solo para conservar tu cuenta. Pasado el plazo, tus datos '
      'personales se borran y no se pueden recuperar.';
}
