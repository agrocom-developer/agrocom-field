import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Contenido de una hoja inferior: radio 32 arriba, manija de 36×4 y el
/// [child] debajo. Es el patrón de todo lo que va sobre el mapa.
///
/// El contenido va dentro de un scroll acotado a la altura disponible: con
/// el texto del sistema al 200 % (o un [child] con más líneas de las que
/// caben) la hoja se desplaza en vez de desbordar o recortar la última
/// fila — nunca agranda la pantalla más allá de lo que el dedo puede
/// arrastrar.
class HojaInferiorCampo extends StatelessWidget {
  const HojaInferiorCampo({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    // Sin tamaño de pantalla conocido (MediaQuery vacío) no se acota: un
    // máximo de 0 colapsaría la hoja entera.
    final alto = MediaQuery.sizeOf(context).height;
    final altoMaximo = alto > 0 ? alto * 0.9 : double.infinity;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ElevacionCampo.superficie(paleta, 2),
        border: Border.all(color: paleta.borde),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RadioCampo.hoja),
        ),
        boxShadow: ElevacionCampo.sombras(paleta, 3),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: altoMaximo),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EspaciadoCampo.m),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: paleta.bordeFuerte,
                      borderRadius: BorderRadius.circular(RadioCampo.capsula),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EspaciadoCampo.l,
                    EspaciadoCampo.l,
                    EspaciadoCampo.l,
                    EspaciadoCampo.xl,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre una [HojaInferiorCampo] modal que se arrastra para cerrar.
Future<T?> mostrarHojaInferiorCampo<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: ColoresCampo.visorFoto.withValues(alpha: 0.54),
    sheetAnimationStyle: AnimationStyle(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.lenta),
      curve: MovimientoCampo.entrada,
    ),
    builder: (c) => HojaInferiorCampo(child: builder(c)),
  );
}
