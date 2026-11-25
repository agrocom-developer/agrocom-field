import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../paleta_campo.dart';

/// Imagen que viene del backend (fotos de avance, del dron, del perfil o del
/// terreno) o un recurso empaquetado (`assets/…`).
///
/// Las de red se guardan en disco (`cached_network_image`): con mala señal una
/// foto ya vista no se vuelve a pedir. Mientras carga muestra un fondo tenue y,
/// si falla, un ícono; nunca rompe el layout. [respaldo] reemplaza a ambos
/// cuando ya hay algo debajo (las iniciales de un avatar).
class ImagenRedCampo extends StatelessWidget {
  const ImagenRedCampo({
    required this.referencia,
    this.ancho,
    this.alto,
    this.fit = BoxFit.cover,
    this.respaldo,
    super.key,
  });

  /// `assets/…` o una URL.
  final String referencia;
  final double? ancho;
  final double? alto;
  final BoxFit fit;
  final Widget? respaldo;

  @override
  Widget build(BuildContext context) {
    if (referencia.startsWith('assets/')) {
      return Image.asset(
        referencia,
        width: ancho,
        height: alto,
        fit: fit,
        errorBuilder: (_, _, _) => _vacio(context),
      );
    }
    return CachedNetworkImage(
      imageUrl: referencia,
      width: ancho,
      height: alto,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => respaldo ?? _cargando(context),
      errorWidget: (context, _, _) => respaldo ?? _vacio(context),
    );
  }

  Widget _cargando(BuildContext context) =>
      ColoredBox(color: context.paleta.borde);

  Widget _vacio(BuildContext context) {
    final paleta = context.paleta;
    return ColoredBox(
      color: paleta.borde,
      child: Center(
        child: Icon(Icons.image_outlined, color: paleta.textoSecundario),
      ),
    );
  }
}
