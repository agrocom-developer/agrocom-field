import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../ui/paleta_campo.dart';
import '../../ui/componentes/imagen_red_campo.dart';

/// Retrato redondo: la foto si hay (en memoria o por URL) y, debajo, las
/// iniciales sobre el acento, que quedan a la vista mientras la foto carga o
/// si no carga. Nunca rompe el layout.
class AvatarFoto extends StatelessWidget {
  const AvatarFoto({
    required this.iniciales,
    required this.etiqueta,
    this.url,
    this.bytes,
    this.tamano = 48,
    super.key,
  });

  /// Las dos letras de respaldo.
  final String iniciales;

  /// Lo que anuncia el lector de pantalla.
  final String etiqueta;

  /// Foto por URL (firmada) o recurso `assets/…`.
  final String? url;

  /// Foto ya descargada o recién elegida; gana sobre [url].
  final Uint8List? bytes;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final letras = Text(
      iniciales,
      textScaler: TextScaler.noScaling,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: paleta.sobreAcentoContenedor,
        fontWeight: FontWeight.w800,
        fontSize: tamano * 0.36,
      ),
    );
    Widget? foto;
    if (bytes != null) {
      foto = Image.memory(
        bytes!,
        width: tamano,
        height: tamano,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } else if (url != null && url!.isNotEmpty) {
      foto = ImagenRedCampo(
        referencia: url!,
        ancho: tamano,
        alto: tamano,
        respaldo: const SizedBox.shrink(),
      );
    }
    return Semantics(
      label: etiqueta,
      image: foto != null,
      child: ExcludeSemantics(
        child: Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: paleta.acentoContenedor,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Center(child: letras),
              ?foto,
            ],
          ),
        ),
      ),
    );
  }
}
