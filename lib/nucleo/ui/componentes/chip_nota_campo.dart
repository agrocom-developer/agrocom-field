import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Jerarquía de un aviso — nunca solo un color: cada tipo lleva su propio
/// ícono, así un usuario que no distingue el color (o el modo campo, que
/// aplana todo a un solo acento muy saturado) igual reconoce qué es.
enum TipoNotaCampo { informacion, exito, advertencia, error, soloLectura }

/// Chip o banner de nota con jerarquía semántica — la unidad común detrás de
/// `BannerAlertaCampo` (que queda para el caso puntual "sin señal") y de
/// cualquier aviso nuevo que necesite los cinco tonos del sistema, incluido
/// el de "esto ya no se puede editar" (candado, sin tono de alarma).
///
/// [variante] controla si se ve como una pastilla compacta (dentro de una
/// fila, junto a un dato) o como una franja completa (arriba de un
/// formulario, explicando por qué está bloqueado).
class ChipNotaCampo extends StatelessWidget {
  const ChipNotaCampo({
    required this.texto,
    this.tipo = TipoNotaCampo.informacion,
    this.variante = VarianteNotaCampo.chip,
    this.accion,
    super.key,
  });

  final String texto;
  final TipoNotaCampo tipo;
  final VarianteNotaCampo variante;

  /// Acción corta a la derecha (p. ej. "Reintentar"), solo en [VarianteNotaCampo.banner].
  final Widget? accion;

  (IconData, Color, Color) _tono(PaletaCampo paleta) => switch (tipo) {
    TipoNotaCampo.informacion => (
      Icons.info_outline_rounded,
      paleta.infoContenedor,
      paleta.sobreInfoContenedor,
    ),
    TipoNotaCampo.exito => (
      Icons.check_circle_outline_rounded,
      paleta.acentoContenedor,
      paleta.sobreAcentoContenedor,
    ),
    TipoNotaCampo.advertencia => (
      Icons.warning_amber_rounded,
      paleta.ambarContenedor,
      paleta.sobreAmbarContenedor,
    ),
    TipoNotaCampo.error => (
      Icons.error_outline_rounded,
      paleta.errorContenedor,
      paleta.sobreErrorContenedor,
    ),
    TipoNotaCampo.soloLectura => (
      Icons.lock_outline_rounded,
      paleta.superficie2,
      paleta.textoSecundario,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final (icono, fondo, sobreFondo) = _tono(paleta);
    final chico = variante == VarianteNotaCampo.chip;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: chico ? EspaciadoCampo.m : EspaciadoCampo.l,
        vertical: chico ? EspaciadoCampo.s : EspaciadoCampo.m,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(
          chico ? RadioCampo.capsula : RadioCampo.media,
        ),
      ),
      child: Row(
        mainAxisSize: chico ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icono, size: chico ? 14 : 18, color: sobreFondo),
          const SizedBox(width: EspaciadoCampo.s),
          Flexible(
            child: Text(
              texto,
              style: chico
                  ? TipografiaCampo.etiqueta.copyWith(
                      color: sobreFondo,
                      fontSize: 11,
                    )
                  : TipografiaCampo.cuerpoSecundario.copyWith(
                      color: sobreFondo,
                    ),
            ),
          ),
          if (!chico && accion != null) ...[
            const SizedBox(width: EspaciadoCampo.m),
            accion!,
          ],
        ],
      ),
    );
  }
}

/// Forma del aviso: [chip] es una pastilla compacta en una fila; [banner]
/// es una franja de ancho completo con más texto y una acción opcional.
enum VarianteNotaCampo { chip, banner }
