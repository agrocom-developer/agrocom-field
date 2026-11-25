import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Stepper ±1: el número en mono al centro y dos botones de 56 de alto. Para
/// valores enteros que se ajustan de uno en uno (ronda, cantidad de drones).
/// Con [alturaCampo] los botones suben a 72 (modo campo, con guantes).
class StepperCampo extends StatelessWidget {
  const StepperCampo({
    required this.valor,
    required this.onCambio,
    required this.etiqueta,
    this.minimo = 0,
    this.maximo = 999,
    this.unidad,
    this.alturaCampo = false,
    super.key,
  });

  final int valor;
  final ValueChanged<int> onCambio;

  /// Qué se está ajustando; se anuncia en lector de pantalla.
  final String etiqueta;
  final int minimo;
  final int maximo;
  final String? unidad;
  final bool alturaCampo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final lado = alturaCampo
        ? ObjetivoTactilCampo.campo
        : ObjetivoTactilCampo.guantes;
    return Semantics(
      container: true,
      label: l10n.componentesStepperSemantica(
        etiqueta,
        valor,
        unidad == null ? '' : l10n.componentesStepperUnidad(unidad!),
      ),
      value: '$valor',
      increasedValue: valor < maximo ? '${valor + 1}' : null,
      decreasedValue: valor > minimo ? '${valor - 1}' : null,
      onIncrease: valor < maximo ? () => onCambio(valor + 1) : null,
      onDecrease: valor > minimo ? () => onCambio(valor - 1) : null,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Boton(
            icono: Icons.remove_rounded,
            lado: lado,
            onTap: valor > minimo ? () => onCambio(valor - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$valor',
                    textAlign: TextAlign.center,
                    style: TipografiaCampo.cifraGrande.copyWith(
                      color: paleta.texto,
                    ),
                  ),
                  if (unidad != null)
                    Text(
                      unidad!,
                      style: TipografiaCampo.cifraUnidad.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _Boton(
            icono: Icons.add_rounded,
            lado: lado,
            onTap: valor < maximo ? () => onCambio(valor + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({required this.icono, required this.lado, required this.onTap});

  final IconData icono;
  final double lado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final activo = onTap != null;
    return Material(
      color: activo ? paleta.superficie2 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioCampo.campo),
        side: BorderSide(color: activo ? paleta.bordeFuerte : paleta.borde),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioCampo.campo),
        ),
        onTap: onTap,
        child: SizedBox.square(
          dimension: lado,
          child: Icon(
            icono,
            size: 28,
            color: activo ? paleta.texto : paleta.textoSecundario,
          ),
        ),
      ),
    );
  }
}
