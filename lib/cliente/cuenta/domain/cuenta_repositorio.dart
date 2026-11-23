/// Datos de la cuenta del cliente.
class CuentaCliente {
  const CuentaCliente({
    required this.nombre,
    required this.empresa,
    required this.telefono,
    required this.correo,
    required this.serviciosTotales,
  });

  final String nombre;
  final String empresa;
  final String telefono;
  final String correo;
  final int serviciosTotales;
}

abstract interface class CuentaRepositorio {
  Future<CuentaCliente> cuenta();
}
