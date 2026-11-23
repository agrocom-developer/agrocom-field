import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../dominio/dominio.dart';

/// Iniciales sobre un círculo de acento: no hay fotos en la demo.
class AvatarProveedor extends StatelessWidget {
  const AvatarProveedor(this.proveedor, {this.tamano = 48, super.key});

  final Proveedor proveedor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      label: proveedor.nombre,
      child: ExcludeSemantics(
        child: Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: paleta.acento,
            shape: BoxShape.circle,
          ),
          child: Text(
            proveedor.iniciales,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: paleta.sobreAcento,
              fontWeight: FontWeight.w800,
              fontSize: tamano * 0.36,
            ),
          ),
        ),
      ),
    );
  }
}
