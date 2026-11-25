import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/contacto.dart';
import '../domain/contactos_repositorio.dart';

/// Contactos en memoria para la demo y las pruebas. Imita al servidor: el
/// primero queda principal, marcar a otro releva al anterior y una empresa no
/// se queda sin contactos.
class ContactosDemo implements ContactosRepositorio {
  ContactosDemo({
    List<ContactoCliente>? iniciales,
    Duration latencia = Duration.zero,
  }) : _lista = [...(iniciales ?? _ejemplo)],
       _latencia = latencia;

  /// Los de `docs/api/ejemplos/contactos-lista.json` de `agrocom-api`.
  static const _ejemplo = [
    ContactoCliente(
      id: 1,
      nombre: 'Rosario Antelo Vaca',
      telefono: '+591 76543210',
      cargo: 'Gerente',
      esPrincipal: true,
    ),
    ContactoCliente(
      id: 2,
      nombre: 'Mario Suárez Rojas',
      telefono: '+591 71234567',
      cargo: 'Encargado de campo',
      esPrincipal: false,
    ),
  ];

  final List<ContactoCliente> _lista;
  final Duration _latencia;
  int _siguiente = 3;

  Future<void> _espera() => Future<void>.delayed(_latencia);

  List<ContactoCliente> get _ordenada => [
    ..._lista.where((c) => c.esPrincipal),
    ..._lista.where((c) => !c.esPrincipal),
  ];

  @override
  Future<List<ContactoCliente>> listar() async {
    await _espera();
    return _ordenada;
  }

  ContactoCliente _con(ContactoCliente c, DatosContacto d, {bool? principal}) =>
      ContactoCliente(
        id: c.id,
        nombre: d.nombre.trim(),
        telefono: d.telefono.trim(),
        cargo: (d.cargo?.trim().isEmpty ?? true) ? null : d.cargo!.trim(),
        esPrincipal: principal ?? c.esPrincipal,
      );

  void _unicoPrincipal(int id) {
    for (var i = 0; i < _lista.length; i++) {
      final c = _lista[i];
      _lista[i] = ContactoCliente(
        id: c.id,
        nombre: c.nombre,
        telefono: c.telefono,
        cargo: c.cargo,
        esPrincipal: c.id == id,
      );
    }
  }

  @override
  Future<ContactoCliente> agregar(DatosContacto datos) async {
    await _espera();
    final nuevo = _con(
      ContactoCliente(
        id: _siguiente++,
        nombre: '',
        telefono: '',
        esPrincipal: false,
      ),
      datos,
      principal: _lista.isEmpty,
    );
    _lista.add(nuevo);
    if (datos.esPrincipal) _unicoPrincipal(nuevo.id);
    return _lista.firstWhere((c) => c.id == nuevo.id);
  }

  @override
  Future<ContactoCliente> actualizar(int id, DatosContacto datos) async {
    await _espera();
    final i = _lista.indexWhere((c) => c.id == id);
    if (i < 0) throw const OperacionRechazada('No existe ese contacto.');
    _lista[i] = _con(_lista[i], datos);
    if (datos.esPrincipal) _unicoPrincipal(id);
    return _lista.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> darDeBaja(int id) async {
    await _espera();
    if (_lista.length <= 1) {
      throw const OperacionRechazada(
        'Una empresa necesita al menos un contacto.',
      );
    }
    final era = _lista.firstWhere((c) => c.id == id).esPrincipal;
    _lista.removeWhere((c) => c.id == id);
    if (era) _unicoPrincipal(_lista.first.id);
  }
}
