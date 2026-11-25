import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paleta_campo.dart';
import 'tema_visual_cubit.dart';

/// Provee el [TemaVisualCubit] y reconstruye la app cuando cambia el tema.
/// Cada flavor dice su [predeterminado]: el cliente sigue al sistema
/// (`claro`) y el piloto arranca en modo campo.
class TemaVisualApp extends StatelessWidget {
  const TemaVisualApp({
    required this.predeterminado,
    required this.construir,
    this.almacen,
    super.key,
  });

  final ModoVisualCampo predeterminado;
  final Widget Function(BuildContext context, ConfiguracionTema tema) construir;

  /// Dónde se guarda la elección; por defecto `shared_preferences`.
  final AlmacenTemaVisual? almacen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TemaVisualCubit(almacen ?? AlmacenTemaVisualLocal())..cargar(),
      child: BlocBuilder<TemaVisualCubit, ModoVisualCampo?>(
        builder: (context, elegido) => construir(
          context,
          ConfiguracionTema.de(
            elegido: elegido,
            predeterminado: predeterminado,
          ),
        ),
      ),
    );
  }
}
