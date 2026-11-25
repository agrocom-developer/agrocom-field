import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../domain/contacto.dart';
import '../domain/contactos_repositorio.dart';

/// `GET/POST /api/clientes/mi/contactos` y `PUT/DELETE …/{id}`.
class ContactosRed implements ContactosRepositorio {
  ContactosRed(this._http);

  final ClienteHttp _http;

  static const _ruta = '/api/clientes/mi/contactos';

  /// Lee un `ClienteContacto` del contrato.
  static ContactoCliente contacto(Map<dynamic, dynamic> m) => ContactoCliente(
    id: (m['id'] as num).toInt(),
    nombre: '${m['nombre']}',
    telefono: '${m['telefono']}',
    cargo: m['cargo'] as String?,
    esPrincipal: m['es_principal'] == true,
  );

  ContactoCliente _uno(Map<String, dynamic> r) {
    final c = r['contacto'];
    if (c is! Map) {
      throw const OperacionRechazada('No pudimos leer el contacto.');
    }
    return contacto(c);
  }

  @override
  Future<List<ContactoCliente>> listar() async {
    final r = await _http.obtener(_ruta);
    final lista = r['contactos'];
    return [
      if (lista is List)
        for (final c in lista)
          if (c is Map) contacto(c),
    ];
  }

  @override
  Future<ContactoCliente> agregar(DatosContacto datos) async =>
      _uno(await _http.enviar(_ruta, datos: datos.aApi()));

  @override
  Future<ContactoCliente> actualizar(int id, DatosContacto datos) async =>
      _uno(await _http.reemplazar('$_ruta/$id', datos: datos.aApi()));

  @override
  Future<void> darDeBaja(int id) => _http.borrar('$_ruta/$id');
}
