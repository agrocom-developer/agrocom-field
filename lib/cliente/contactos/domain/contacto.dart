/// Persona de referencia de un cliente empresa (`ClienteContacto` del
/// contrato): a quien el piloto adjudicado llama o escribe.
class ContactoCliente {
  const ContactoCliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.esPrincipal,
    this.cargo,
  });

  final int id;
  final String nombre;
  final String telefono;

  /// Cargo en la empresa («Encargada de campo»); opcional.
  final String? cargo;

  /// El que se usa cuando una solicitud no elige otro. Hay uno solo.
  final bool esPrincipal;

  @override
  bool operator ==(Object other) =>
      other is ContactoCliente &&
      other.id == id &&
      other.nombre == nombre &&
      other.telefono == telefono &&
      other.cargo == cargo &&
      other.esPrincipal == esPrincipal;

  @override
  int get hashCode => Object.hash(id, nombre, telefono, cargo, esPrincipal);
}

/// Lo que la persona escribe al agregar o corregir un contacto
/// (`ContactoEntrada`).
class DatosContacto {
  const DatosContacto({
    required this.nombre,
    required this.telefono,
    this.cargo,
    this.esPrincipal = false,
  });

  final String nombre;
  final String telefono;
  final String? cargo;
  final bool esPrincipal;

  /// Cuerpo para la API: nada en blanco, cargo solo si lo hay.
  Map<String, dynamic> aApi() => {
    'nombre': nombre.trim(),
    'telefono': telefono.trim(),
    if (cargo != null && cargo!.trim().isNotEmpty) 'cargo': cargo!.trim(),
    if (esPrincipal) 'es_principal': true,
  };
}
