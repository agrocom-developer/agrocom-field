/// Rol bajo el que opera un dispositivo — el `rol` del `201` de
/// `POST /api/auth/token` (`docs/api/openapi.yaml`, operationId
/// `emitirTokenDispositivo`) y cada elemento de `roles` en su `409` cuando
/// hay más de un rol vivo entre el que elegir (ADR 0005 de este repo). Dart
/// puro, sin dependencias de Flutter.
class RolActivo {
  const RolActivo({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory RolActivo.fromJson(Map<String, dynamic> json) => RolActivo(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      other is RolActivo &&
      other.id == id &&
      other.name == name &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, name, description);
}
