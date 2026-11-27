import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'hoja_inferior_campo.dart';

/// Una opción de [mostrarSelectorOpcionesCampo].
@immutable
class OpcionHojaCampo<T> {
  const OpcionHojaCampo({
    required this.valor,
    required this.texto,
    this.subtitulo,
    this.icono,
  });

  final T valor;
  final String texto;
  final String? subtitulo;
  final IconData? icono;
}

/// Abre una hoja inferior con una lista de opciones de elección única —
/// reemplaza un `AlertDialog` con radios o un menú desplegable largo
/// (principio "sin sobrecarga": el menor uso posible de diálogos). Cada fila
/// es un objetivo táctil de 48 px (56 en modo campo); la opción elegida
/// lleva la tilde. Devuelve el [T] elegido, o `null` si se cierra sin elegir.
Future<T?> mostrarSelectorOpcionesCampo<T>({
  required BuildContext context,
  required String titulo,
  required List<OpcionHojaCampo<T>> opciones,
  T? seleccionado,
}) {
  return mostrarHojaInferiorCampo<T>(
    context: context,
    builder: (context) {
      final paleta = context.paleta;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
          ),
          const SizedBox(height: EspaciadoCampo.m),
          for (final opcion in opciones)
            _FilaOpcion<T>(
              opcion: opcion,
              elegida: opcion.valor == seleccionado,
              onTap: () => Navigator.of(context).pop(opcion.valor),
            ),
        ],
      );
    },
  );
}

class _FilaOpcion<T> extends StatelessWidget {
  const _FilaOpcion({
    required this.opcion,
    required this.elegida,
    required this.onTap,
  });

  final OpcionHojaCampo<T> opcion;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.minimo,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.s),
            child: Row(
              children: [
                if (opcion.icono != null) ...[
                  Icon(opcion.icono, size: 22, color: paleta.textoSecundario),
                  const SizedBox(width: EspaciadoCampo.m),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opcion.texto,
                        style: TipografiaCampo.cuerpo.copyWith(
                          color: paleta.texto,
                          fontWeight: elegida
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (opcion.subtitulo != null)
                        Text(
                          opcion.subtitulo!,
                          style: TipografiaCampo.cuerpoSecundario.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                    ],
                  ),
                ),
                if (elegida)
                  Icon(
                    Icons.check_rounded,
                    color: paleta.acentoTexto,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
