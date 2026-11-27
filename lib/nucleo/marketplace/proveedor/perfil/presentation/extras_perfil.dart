import 'package:flutter/material.dart';

import '../../../../ui/componentes/fila_accion_campo.dart';

class FilaAccionPerfil extends StatelessWidget {
  const FilaAccionPerfil({
    required this.icono,
    required this.titulo,
    required this.alToque,
    this.detalle,
    this.clave,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alToque;
  final Key? clave;

  @override
  Widget build(BuildContext context) => FilaAccionCampo(
    clave: clave,
    icono: icono,
    titulo: titulo,
    detalle: detalle,
    alToque: alToque,
  );
}
