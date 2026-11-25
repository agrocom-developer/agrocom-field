import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/api/api_client.dart';
import '../../../nucleo/api/api_excepcion.dart';
import '../../../nucleo/auth/dispositivo_store.dart';
import '../../../nucleo/auth/token_store.dart';
import '../../red/cliente_http.dart';
import '../domain/acceso_repositorio.dart';

/// Si la persona ya vio la presentación inicial. Es una preferencia de la
/// interfaz, no un dato de la cuenta: vive en el dispositivo.
abstract interface class OnboardingStore {
  Future<bool> visto();
  Future<void> marcar();
}

class OnboardingStoreLocal implements OnboardingStore {
  OnboardingStoreLocal([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencias;
  static const _clave = 'cliente_onboarding_visto';

  @override
  Future<bool> visto() async => (await _preferencias).getBool(_clave) ?? false;

  @override
  Future<void> marcar() async => (await _preferencias).setBool(_clave, true);
}

/// Acceso del cliente contra la API: `POST /api/auth/token` (usuario y
/// contraseña, nunca correo), `POST /api/clientes/registro` y
/// `DELETE /api/auth/token`.
///
/// El token vive solo en almacenamiento seguro ([TokenStore]); la contraseña
/// no se guarda. Una cuenta que no es de cliente no entra: se revoca el
/// token recién emitido y se avisa con un mensaje junto al campo.
class AccesoRed implements AccesoRepositorio {
  AccesoRed({
    required ApiClient api,
    required TokenStore tokenStore,
    required DispositivoStore dispositivoStore,
    required OnboardingStore onboarding,
    void Function()? alCerrarSesion,
    Future<void> Function()? retirarPush,
  }) : _api = api,
       _tokenStore = tokenStore,
       _dispositivo = dispositivoStore,
       _onboarding = onboarding,
       _alCerrarSesion = alCerrarSesion,
       _retirarPush = retirarPush;

  final ApiClient _api;
  final TokenStore _tokenStore;
  final DispositivoStore _dispositivo;
  final OnboardingStore _onboarding;

  /// Limpia lo que la app guardó en memoria de esta cuenta.
  final void Function()? _alCerrarSesion;

  /// Retira el token de push del servidor. Va antes de borrar el token de
  /// sesión, porque la baja va autenticada (ADR 0020).
  final Future<void> Function()? _retirarPush;

  static const rolCliente = 'cliente';

  static const _noEsCliente =
      'Esta cuenta no es de cliente. Usa la app de Agrocom que le corresponde.';

  @override
  Future<bool> onboardingVisto() => _onboarding.visto();

  @override
  Future<void> marcarOnboardingVisto() => _onboarding.marcar();

  @override
  Future<SesionCliente?> sesionActual() async {
    if (await _tokenStore.leerToken() == null) return null;
    try {
      return await _sesionDelToken();
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 401 || e.codigo == 403) {
        // Token vencido, revocado o de otro rol: se descarta.
        await _tokenStore.borrarToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SesionCliente> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final uuid = await _dispositivo.obtenerUuidDispositivo();
    final cuerpo = await _pedirToken(usuario, contrasena, uuid);
    final rol = (cuerpo['rol'] as Map?)?['name'];
    await _tokenStore.guardarToken('${cuerpo['token']}');
    if (rol != rolCliente) {
      await _descartarToken();
      throw const AccesoExcepcion(
        MotivoFalloAcceso.validacion,
        porCampo: {CampoAcceso.usuario: _noEsCliente},
      );
    }
    try {
      return await _sesionDelToken();
    } on ApiExcepcionRed {
      await _tokenStore.borrarToken();
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    } on ApiExcepcion {
      await _tokenStore.borrarToken();
      throw const AccesoExcepcion(MotivoFalloAcceso.desconocido);
    }
  }

  /// Pide el token. Si el usuario tiene varios roles, repite con el de
  /// cliente; si ninguno lo es, lanza [AccesoExcepcion].
  Future<Map<String, dynamic>> _pedirToken(
    String usuario,
    String contrasena,
    String uuid, {
    int? rolId,
  }) async {
    try {
      final r = await _api.post(
        '/api/auth/token',
        data: {
          'username': usuario,
          'password': contrasena,
          'uuid_dispositivo': uuid,
          'nombre_dispositivo': 'Agrocom cliente',
          'role_id': ?rolId,
        },
      );
      return Map<String, dynamic>.from(r.data as Map);
    } on ApiExcepcionRed {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 409 && rolId == null) {
        final roles = e.cuerpo is Map ? (e.cuerpo as Map)['roles'] : null;
        final cliente = roles is List
            ? roles.whereType<Map>().where((r) => r['name'] == rolCliente)
            : const <Map>[];
        if (cliente.isEmpty) {
          throw const AccesoExcepcion(
            MotivoFalloAcceso.validacion,
            porCampo: {CampoAcceso.usuario: _noEsCliente},
          );
        }
        return _pedirToken(
          usuario,
          contrasena,
          uuid,
          rolId: cliente.first['id'] as int,
        );
      }
      throw switch (e.codigo) {
        401 ||
        422 => const AccesoExcepcion(MotivoFalloAcceso.credencialesInvalidas),
        403 => const AccesoExcepcion(
          MotivoFalloAcceso.validacion,
          porCampo: {CampoAcceso.usuario: _noEsCliente},
        ),
        _ => const AccesoExcepcion(MotivoFalloAcceso.desconocido),
      };
    } on ApiExcepcionDesconocida {
      throw const AccesoExcepcion(MotivoFalloAcceso.desconocido);
    }
  }

  Future<SesionCliente> _sesionDelToken() async {
    final sesion = (await _api.get('/api/auth/sesion')).data as Map;
    final ficha = (await _api.get('/api/clientes/mi')).data as Map;
    final usuario = sesion['usuario'] as Map;
    final cliente = ficha['cliente'] as Map;
    return SesionCliente(
      nombre: '${usuario['name']}',
      usuario: '${usuario['username']}',
      empresa: cliente['tipo'] == 'empresa'
          ? '${cliente['razon_social']}'
          : null,
      telefono: cliente['telefono'] as String?,
    );
  }

  @override
  Future<SesionCliente> registrar(DatosRegistroCliente datos) async {
    try {
      await _api.post(
        '/api/clientes/registro',
        data: {
          'tipo': datos.tipo.name,
          'nombre': datos.nombre.trim(),
          'username': datos.usuario.trim(),
          'password': datos.contrasena,
          'telefono': datos.telefono.trim(),
          if (datos.tipo == TipoCliente.empresa) ...{
            'razon_social': datos.razonSocial?.trim(),
            'documento_fiscal': datos.documentoFiscal?.trim(),
            // Quien se registra es el contacto principal de la empresa.
            'contactos': [
              {
                'nombre': datos.nombre.trim(),
                'telefono': datos.telefono.trim(),
                if (datos.cargo != null) 'cargo': datos.cargo!.trim(),
                'es_principal': true,
              },
            ],
          },
        },
      );
    } on ApiExcepcionRed {
      throw const AccesoExcepcion(MotivoFalloAcceso.sinConexion);
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 422) {
        throw AccesoExcepcion(
          MotivoFalloAcceso.validacion,
          porCampo: _camposDe(ClienteHttp.erroresPorCampo(e.cuerpo)),
        );
      }
      throw const AccesoExcepcion(MotivoFalloAcceso.desconocido);
    } on ApiExcepcionDesconocida {
      throw const AccesoExcepcion(MotivoFalloAcceso.desconocido);
    }
    return iniciarSesion(
      usuario: datos.usuario.trim(),
      contrasena: datos.contrasena,
    );
  }

  static CampoAcceso? _campoDe(String campoApi) => switch (campoApi) {
    'username' => CampoAcceso.usuario,
    'password' => CampoAcceso.contrasena,
    'telefono' => CampoAcceso.telefono,
    'nombre' => CampoAcceso.nombre,
    'razon_social' => CampoAcceso.razonSocial,
    'documento_fiscal' => CampoAcceso.documentoFiscal,
    _ => null,
  };

  static Map<CampoAcceso, String> _camposDe(Map<String, String> errores) {
    final salida = <CampoAcceso, String>{};
    errores.forEach((campoApi, mensaje) {
      final campo = _campoDe(campoApi);
      if (campo != null) salida[campo] = mensaje;
    });
    return salida;
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _descartarToken();
    } finally {
      _alCerrarSesion?.call();
    }
  }

  /// Revoca el dispositivo en el servidor (si hay red) y borra el token
  /// local pase lo que pase.
  Future<void> _descartarToken() async {
    try {
      // El token de push se retira mientras la sesión aún vale. Si falla
      // (sin red), queda guardado para reintentar y la sesión se cierra igual.
      try {
        await _retirarPush?.call();
      } on Object {
        // Nada que hacer aquí: cerrar sesión no depende del push.
      }
      await _api.delete('/api/auth/token');
    } on ApiExcepcion {
      // Sin red o ya revocado: el token local se borra igual.
    } finally {
      await _tokenStore.borrarToken();
    }
  }
}
