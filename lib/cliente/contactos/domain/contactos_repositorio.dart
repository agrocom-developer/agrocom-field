import 'contacto.dart';

/// Contactos de referencia del cliente empresa. Online-first: el flavor
/// cliente no tiene outbox. El servidor decide quién es el principal y no
/// deja a una empresa sin contactos.
abstract interface class ContactosRepositorio {
  /// Los contactos vigentes, el principal primero.
  Future<List<ContactoCliente>> listar();

  Future<ContactoCliente> agregar(DatosContacto datos);

  /// Marcar a otro como principal releva al anterior.
  Future<ContactoCliente> actualizar(int id, DatosContacto datos);

  /// Baja lógica. Lanza `OperacionRechazada` si es el único de una empresa.
  Future<void> darDeBaja(int id);
}
