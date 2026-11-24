import 'package:flutter/material.dart';

import '../dominio/dominio.dart';
import 'avatar_foto.dart';

/// Retrato del proveedor. Sin foto, o si no carga, muestra las iniciales
/// sobre un círculo de acento.
class AvatarProveedor extends StatelessWidget {
  const AvatarProveedor(this.proveedor, {this.tamano = 48, super.key});

  final Proveedor proveedor;
  final double tamano;

  @override
  Widget build(BuildContext context) => AvatarFoto(
    iniciales: proveedor.iniciales,
    etiqueta: proveedor.nombre,
    url: proveedor.fotoRef ?? proveedor.fotoUrl,
    tamano: tamano,
  );
}
