import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../seguimiento/domain/seguimiento_repositorio.dart';

/// Foto de avance o del dron. Una ruta `assets/…` es un recurso empaquetado
/// (la demo); cualquier otra se descarga con la sesión del cliente, porque
/// las fotos del servidor no son públicas. Mientras carga muestra un fondo
/// tenue y, si falla, un ícono: nunca rompe el layout.
class FotoRemota extends StatelessWidget {
  const FotoRemota({
    required this.ruta,
    this.alto,
    this.ancho,
    this.etiqueta,
    super.key,
  });

  final String ruta;
  final double? alto;
  final double? ancho;

  /// Lo que anuncia el lector de pantalla.
  final String? etiqueta;

  /// Descargas ya hechas: una foto no cambia, y volver a abrir la pantalla
  /// no debe volver a pedirla. Se vacía al cerrar sesión.
  static final _cache = <String, Future<Uint8List>>{};

  static void limpiarCache() => _cache.clear();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    Widget marco(Widget hijo) => Semantics(
      image: true,
      label: etiqueta ?? l10n.comunFoto,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadioCampo.chip),
          child: SizedBox(width: ancho, height: alto, child: hijo),
        ),
      ),
    );
    final vacio = ColoredBox(
      color: paleta.borde,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: paleta.textoSecundario,
          size: 28,
        ),
      ),
    );
    if (ruta.startsWith('assets/')) {
      return marco(
        Image.asset(ruta, fit: BoxFit.cover, errorBuilder: (_, _, _) => vacio),
      );
    }
    final futuro = _cache.putIfAbsent(
      ruta,
      () => context.read<SeguimientoRepositorio>().archivo(ruta),
    );
    return marco(
      FutureBuilder<Uint8List>(
        future: futuro,
        builder: (context, snap) {
          if (snap.hasError) {
            _cache.remove(ruta);
            return vacio;
          }
          final bytes = snap.data;
          if (bytes == null) return ColoredBox(color: paleta.borde);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => vacio,
          );
        },
      ),
    );
  }
}
