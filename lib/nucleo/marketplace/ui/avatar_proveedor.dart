import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../dominio/dominio.dart';
import 'imagen_ref.dart';

/// Retrato del proveedor. Sin `fotoRef`, o si la foto no carga, muestra las
/// iniciales sobre un círculo de acento.
class AvatarProveedor extends StatelessWidget {
  const AvatarProveedor(this.proveedor, {this.tamano = 48, super.key});

  final Proveedor proveedor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final iniciales = Text(
      proveedor.iniciales,
      textScaler: TextScaler.noScaling,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: paleta.sobreAcento,
        fontWeight: FontWeight.w800,
        fontSize: tamano * 0.36,
      ),
    );
    final foto = proveedor.fotoRef;
    return Semantics(
      label: proveedor.nombre,
      image: foto != null,
      child: ExcludeSemantics(
        child: Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: paleta.acento,
            shape: BoxShape.circle,
          ),
          child: foto == null
              ? iniciales
              : Image(
                  image: imagenDeRef(foto),
                  width: tamano,
                  height: tamano,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => iniciales,
                ),
        ),
      ),
    );
  }
}
