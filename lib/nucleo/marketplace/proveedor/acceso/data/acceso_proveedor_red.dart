import 'package:dio/dio.dart';

import '../../../../api/api_client.dart';
import '../../../../api/api_excepcion.dart';
import '../../../../api/marketplace_http.dart';
import '../../../../auth/dispositivo_store.dart';
import '../../../../auth/token_store.dart';
import '../domain/acceso_proveedor.dart';

/// Acceso contra la API: `POST /api/auth/token` (usuario y contraseña, nunca
/// correo), `GET /api/auth/sesion`, `POST /api/proveedores/registro` y
/// `DELETE /api/auth/token`.
///
/// Un usuario con varios roles (un independiente es `piloto` y `proveedor`)
/// entra con el primero de [rolesPreferidos] que tenga: el flavor `piloto`
/// prefiere `proveedor` (que además administra sus drones) y cae a `piloto`;
/// el flavor `auxiliar` solo entra como `auxiliar`. El token vive solo en
/// almacenamiento seguro.
class AccesoProveedorRed implements AccesoProveedorRepositorio {
  AccesoProveedorRed({
    required ApiClient api,
    required TokenStore tokenStore,
    required DispositivoStore dispositivoStore,
    required this.rolesPreferidos,
    required this.nombreDispositivo,
    Future<void> Function()? alCerrarSesion,
    Future<void> Function()? retirarPush,
  }) : _api = api,
       _tokenStore = tokenStore,
       _dispositivo = dispositivoStore,
       _alCerrarSesion = alCerrarSesion,
       _retirarPush = retirarPush;

  final ApiClient _api;
  final TokenStore _tokenStore;
  final DispositivoStore _dispositivo;
  final Future<void> Function()? _alCerrarSesion;

  /// Retira el token de push del servidor. Va antes de borrar el token de
  /// sesión, porque la baja va autenticada (ADR 0020).
  final Future<void> Function()? _retirarPush;

  /// Roles con los que este flavor puede operar, del preferido al último.
  final List<String> rolesPreferidos;
  final String nombreDispositivo;

  static const _cuentaAjena =
      'Esta cuenta no es de esta app. Usa la app de Agrocom que le corresponde.';

  @override
  Future<SesionProveedor?> sesionActual() async {
    if (await _tokenStore.leerToken() == null) return null;
    try {
      return _desdeSesion(
        Map<String, dynamic>.from(
          (await _api.get('/api/auth/sesion')).data as Map,
        ),
      );
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 401 || e.codigo == 403) {
        await _tokenStore.borrarToken();
        return null;
      }
      rethrow;
    }
  }

  SesionProveedor _desdeSesion(Map<String, dynamic> cuerpo) {
    final usuario = Map<String, dynamic>.from(cuerpo['usuario'] as Map);
    final rol = Map<String, dynamic>.from(cuerpo['rol'] as Map);
    return SesionProveedor(
      nombre: '${usuario['name']}',
      usuario: '${usuario['username']}',
      rol: '${rol['name']}',
    );
  }

  @override
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final uuid = await _dispositivo.obtenerUuidDispositivo();
    final cuerpo = await _pedirToken(usuario.trim(), contrasena, uuid);
    final sesion = _desdeSesion(cuerpo);
    if (!rolesPreferidos.contains(sesion.rol)) {
      await _descartarToken();
      throw const AccesoProveedorExcepcion(
        MotivoFalloAcceso.cuentaAjena,
        mensaje: _cuentaAjena,
      );
    }
    await _tokenStore.guardarToken('${cuerpo['token']}');
    return sesion;
  }

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
          'nombre_dispositivo': nombreDispositivo,
          'role_id': ?rolId,
        },
      );
      return Map<String, dynamic>.from(r.data as Map);
    } on ApiExcepcionRed {
      throw const AccesoProveedorExcepcion(MotivoFalloAcceso.sinConexion);
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 409 && rolId == null) {
        final roles = e.cuerpo is Map ? (e.cuerpo as Map)['roles'] : null;
        final vivos = roles is List
            ? [
                for (final r in roles)
                  if (r is Map) Map<String, dynamic>.from(r),
              ]
            : const <Map<String, dynamic>>[];
        for (final preferido in rolesPreferidos) {
          for (final r in vivos) {
            if (r['name'] == preferido) {
              return _pedirToken(
                usuario,
                contrasena,
                uuid,
                rolId: r['id'] as int,
              );
            }
          }
        }
        throw const AccesoProveedorExcepcion(
          MotivoFalloAcceso.cuentaAjena,
          mensaje: _cuentaAjena,
        );
      }
      throw switch (e.codigo) {
        401 || 422 => const AccesoProveedorExcepcion(
          MotivoFalloAcceso.credencialesInvalidas,
        ),
        403 => const AccesoProveedorExcepcion(
          MotivoFalloAcceso.cuentaAjena,
          mensaje: _cuentaAjena,
        ),
        _ => const AccesoProveedorExcepcion(MotivoFalloAcceso.desconocido),
      };
    } on ApiExcepcionDesconocida {
      throw const AccesoProveedorExcepcion(MotivoFalloAcceso.desconocido);
    }
  }

  @override
  Future<void> registrar(DatosPersona d) async {
    String fecha(DateTime f) =>
        '${f.year.toString().padLeft(4, '0')}-'
        '${f.month.toString().padLeft(2, '0')}-'
        '${f.day.toString().padLeft(2, '0')}';
    try {
      await _api.post(
        '/api/proveedores/registro',
        data: {
          'tipo': 'independiente',
          'nombre': d.nombreCompleto,
          'username': d.usuario.trim(),
          'password': d.contrasena,
          'telefono': d.telefono.trim(),
          'razon_social': d.razonSocial?.trim().isNotEmpty == true
              ? d.razonSocial!.trim()
              : d.nombreCompleto,
          'nombres': d.nombres.trim(),
          'apellidos': d.apellidos.trim(),
          'documento_identidad': d.documentoIdentidad.trim(),
          'fecha_nacimiento': fecha(d.fechaNacimiento),
          'documento_fiscal': d.documentoFiscal?.trim().isNotEmpty == true
              ? d.documentoFiscal!.trim()
              : d.documentoIdentidad.trim(),
          'licencia_numero': d.licenciaNumero.trim(),
          'licencia_vence': fecha(d.licenciaVence),
          'categoria_habilitacion': d.categoriaHabilitacion.trim(),
        },
      );
    } on ApiExcepcionRed {
      throw const AccesoProveedorExcepcion(MotivoFalloAcceso.sinConexion);
    } on ApiExcepcionServidor catch (e) {
      if (e.codigo == 422) {
        throw AccesoProveedorExcepcion(
          MotivoFalloAcceso.validacion,
          mensaje: MarketplaceHttp.mensajeDeServidor(422, e.cuerpo),
          porCampo: MarketplaceHttp.erroresPorCampo(e.cuerpo),
        );
      }
      if (e.codigo == 429) {
        throw const AccesoProveedorExcepcion(
          MotivoFalloAcceso.desconocido,
          mensaje:
              'Hiciste demasiados registros desde esta red. Espera un rato.',
        );
      }
      throw const AccesoProveedorExcepcion(MotivoFalloAcceso.desconocido);
    } on ApiExcepcionDesconocida {
      throw const AccesoProveedorExcepcion(MotivoFalloAcceso.desconocido);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _descartarToken();
    } finally {
      await _alCerrarSesion?.call();
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
    } on DioException {
      // Ídem.
    } finally {
      await _tokenStore.borrarToken();
    }
  }
}

/// Alta de drones y de sus fotos (`POST /api/proveedores/drones` y
/// `/{id}/fotos`).
class RegistroDronesRed implements RegistroDronesRepositorio {
  RegistroDronesRed(this._http);

  final MarketplaceHttp _http;

  @override
  Future<int> registrarDron(DatosDron d) async {
    final cuerpo = await _http.enviar(
      '/api/proveedores/drones',
      datos: {
        'marca': d.marca.trim(),
        'modelo': d.modelo.trim(),
        'numero_serie': d.numeroSerie.trim(),
        'anio': ?d.anio,
        'capacidad_tanque_l': d.capacidadTanqueL.toString(),
        'ancho_pasada_m': d.anchoPasadaM.toString(),
      },
    );
    return (Map<String, dynamic>.from(cuerpo['dron'] as Map))['id'] as int;
  }

  @override
  Future<void> subirFoto(int dronId, FotoDronLista foto) async {
    await _http.subir(
      '/api/proveedores/drones/$dronId/fotos',
      campos: {'tipo': foto.tipo.codigo},
      campoArchivo: 'archivo',
      bytes: foto.bytes,
      nombreArchivo: '${foto.tipo.codigo}.jpg',
    );
  }
}
