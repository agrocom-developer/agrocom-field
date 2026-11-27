import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import 'estrella_campo.dart';
import '../tokens_campo.dart';

/// Las cinco estrellas doradas del perfil, con media estrella y el promedio
/// al lado («5,0»). Va sobre la cabecera verde ([CabeceraPerfilCampo]); al
/// tocarla se abre la pantalla de calificaciones. Quien no tiene
/// calificaciones todavía pasa 5,0.
class EstrellasPerfilCampo extends StatelessWidget {
  const EstrellasPerfilCampo({
    required this.valor,
    this.total,
    this.onTap,
    super.key,
  }) : assert(valor >= 0 && valor <= 5);

  final double valor;

  /// Cuántas calificaciones respaldan el promedio; solo lo lee el lector de
  /// pantalla.
  final int? total;

  final VoidCallback? onTap;

  static const double tamanoEstrella = 30;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final numero = valor.toStringAsFixed(1).replaceAll('.', ',');
    final contenido = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ObjetivoTactilCampo.minimo),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            EstrellaCampo(
              tamano: tamanoEstrella,
              llena: valor >= i - 0.25,
              media: valor < i - 0.25 && valor >= i - 0.75,
            ),
          const SizedBox(width: EspaciadoCampo.s),
          Text(
            numero,
            style: texto.titleMedium?.copyWith(
              color: paleta.sobreCabecera,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      label: AppLocalizations.of(context).perfilUxCalificacionSemantica(numero),
      excludeSemantics: true,
      child: onTap == null
          ? contenido
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(RadioCampo.chip),
              child: contenido,
            ),
    );
  }
}
