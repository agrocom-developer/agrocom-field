import 'package:flutter/widgets.dart';

/// Resuelve una referencia de imagen del dominio (`fotoRef`, `imagenRef`):
/// un recurso empaquetado si empieza con `assets/`, una URL en otro caso.
ImageProvider imagenDeRef(String ref) =>
    ref.startsWith('assets/') ? AssetImage(ref) : NetworkImage(ref);
