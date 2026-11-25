import 'dart:typed_data';

import 'package:decimal/decimal.dart';

/// Quién está dentro: lo mínimo para saludar y saber con qué rol opera.
class SesionProveedor {
  const SesionProveedor({
    required this.nombre,
    required this.usuario,
    required this.rol,
  });

  final String nombre;
  final String usuario;

  /// `piloto` o `proveedor`.
  final String rol;

  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  @override
  bool operator ==(Object other) =>
      other is SesionProveedor &&
      other.nombre == nombre &&
      other.usuario == usuario &&
      other.rol == rol;

  @override
  int get hashCode => Object.hash(nombre, usuario, rol);
}

enum MotivoFalloAcceso {
  credencialesInvalidas,
  sinConexion,
  validacion,

  /// La cuenta existe pero no es de este flavor.
  cuentaAjena,
  desconocido,
}

class AccesoProveedorExcepcion implements Exception {
  const AccesoProveedorExcepcion(
    this.motivo, {
    this.mensaje,
    this.porCampo = const {},
  });

  final MotivoFalloAcceso motivo;
  final String? mensaje;

  /// Errores `422` por campo de la API (`username`, `telefono`...).
  final Map<String, String> porCampo;

  @override
  String toString() => 'AccesoProveedorExcepcion(${motivo.name})';
}

/// Datos de la persona y su licencia para el alta de un proveedor
/// independiente (`POST /api/proveedores/registro`).
class DatosPersona {
  const DatosPersona({
    required this.nombres,
    required this.apellidos,
    required this.documentoIdentidad,
    required this.fechaNacimiento,
    required this.telefono,
    required this.usuario,
    required this.contrasena,
    required this.licenciaNumero,
    required this.licenciaVence,
    required this.categoriaHabilitacion,
    this.razonSocial,
    this.documentoFiscal,
  });

  final String nombres;
  final String apellidos;
  final String documentoIdentidad;
  final DateTime fechaNacimiento;
  final String telefono;
  final String usuario;
  final String contrasena;
  final String licenciaNumero;
  final DateTime licenciaVence;
  final String categoriaHabilitacion;

  /// Si no se escribe, se usa el nombre completo.
  final String? razonSocial;

  /// Si no se escribe, se usa el documento de identidad.
  final String? documentoFiscal;

  String get nombreCompleto => '$nombres $apellidos'.trim();
}

/// Datos del dron del alta o de «Agregar dron». Capacidad y ancho de pasada
/// son decimales exactos (ADR 0002).
class DatosDron {
  const DatosDron({
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    required this.capacidadTanqueL,
    required this.anchoPasadaM,
    this.anio,
  });

  final String marca;
  final String modelo;
  final String numeroSerie;
  final int? anio;
  final Decimal capacidadTanqueL;
  final Decimal anchoPasadaM;
}

/// Tipo de foto que el servidor pide del dron.
enum TipoFotoDron {
  frontal('frontal', 'Frontal', obligatoria: true),
  lateral('lateral', 'Lateral', obligatoria: true),
  placaSerie('placa_serie', 'Placa de serie', obligatoria: true),
  otra('otra', 'Otra', obligatoria: false);

  const TipoFotoDron(this.codigo, this.etiqueta, {required this.obligatoria});
  final String codigo;
  final String etiqueta;
  final bool obligatoria;
}

/// Una foto del dron ya comprimida a menos de 300 KB.
class FotoDronLista {
  const FotoDronLista(this.tipo, this.bytes);

  final TipoFotoDron tipo;
  final Uint8List bytes;
}

/// Acceso del piloto contra la API: iniciar sesión por usuario
/// y contraseña, alta de proveedor y cierre. Requiere red (ADR 0016); la
/// contraseña no se guarda en el dispositivo.
abstract interface class AccesoProveedorRepositorio {
  /// La sesión guardada en el dispositivo, o `null`.
  Future<SesionProveedor?> sesionActual();

  /// Lanza [AccesoProveedorExcepcion].
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  });

  /// Crea el proveedor independiente (queda `pendiente` hasta que un
  /// administrador lo aprueba). No inicia sesión.
  Future<void> registrar(DatosPersona datos);

  /// Revoca el dispositivo, borra el token y descarta lo que el próximo
  /// usuario no debe ver (lo pendiente de subir se conserva).
  Future<void> cerrarSesion();
}

/// Alta de drones y de sus fotos para el proveedor de la sesión.
abstract interface class RegistroDronesRepositorio {
  /// Devuelve el id del dron creado.
  Future<int> registrarDron(DatosDron datos);

  Future<void> subirFoto(int dronId, FotoDronLista foto);
}
