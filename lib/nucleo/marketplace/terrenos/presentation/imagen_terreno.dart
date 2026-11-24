import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../ui/paleta_campo.dart';
import '../../ui/imagen_ref.dart';

/// La imagen de una foto de terreno: la elegida en este celular o la del
/// servidor por URL; mientras carga, un fondo tenue, y si no carga, un
/// ícono. Nunca rompe el layout.
class ImagenTerreno extends StatelessWidget {
  const ImagenTerreno({
    this.bytes,
    this.url,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Uint8List? bytes;
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final vacio = ColoredBox(
      color: paleta.borde,
      child: Center(
        child: Icon(Icons.image_outlined, color: paleta.textoSecundario),
      ),
    );
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => vacio,
      );
    }
    if (url == null || url!.isEmpty) return vacio;
    return Image(
      image: imagenDeRef(url!),
      fit: fit,
      loadingBuilder: (_, hijo, avance) =>
          avance == null ? hijo : ColoredBox(color: paleta.borde),
      errorBuilder: (_, _, _) => vacio,
    );
  }
}
