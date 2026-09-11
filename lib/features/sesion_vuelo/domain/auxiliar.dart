/// Auxiliar disponible para asignar a una sesión (HU-07) — espejo mínimo de
/// `PersonaCatalogo` (id de servidor, nombre), filtrado por rol. Entidad
/// Dart pura, igual criterio que `Sesion`/`Trabajo`: sin `drift` en
/// `domain/`.
class Auxiliar {
  const Auxiliar({required this.id, required this.nombre});

  final int id;
  final String nombre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Auxiliar && other.id == id && other.nombre == nombre);

  @override
  int get hashCode => Object.hash(id, nombre);
}
