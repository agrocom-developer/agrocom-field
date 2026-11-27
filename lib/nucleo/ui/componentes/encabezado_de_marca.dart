import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../sobre_foto_campo.dart';
import '../tokens_campo.dart';
import 'icono_agrocom.dart';

/// Para quién es la app que se está viendo. El flavor lo fija y no hay
/// selector de rol (ADR 0021): este valor solo decide cómo se rotula.
enum RolApp {
  piloto,
  cliente;

  /// Ícono del distintivo: el piloto con su mando y su dron; el cliente, su
  /// lote.
  IconoAgrocomId get icono => switch (this) {
    piloto => IconoAgrocomId.piloto,
    cliente => IconoAgrocomId.lote,
  };

  /// «Piloto» o «Cliente».
  String distintivo(AppLocalizations l10n) => switch (this) {
    piloto => l10n.marcaDistintivoPiloto,
    cliente => l10n.marcaDistintivoCliente,
  };

  /// «DronAgro, app para pilotos» o «DronAgro, app para clientes».
  String etiquetaSemantica(AppLocalizations l10n) => switch (this) {
    piloto => l10n.marcaEtiquetaPiloto,
    cliente => l10n.marcaEtiquetaCliente,
  };
}

/// Píldora con el ícono y el nombre del rol («Piloto» / «Cliente»): lo que
/// dice a primera vista para quién es esta app. No depende solo del color: lleva
/// ícono y texto.
///
/// Con [sobreFoto] usa texto blanco sobre un fondo oscuro translúcido, para
/// ir encima de las portadas con foto.
class DistintivoRol extends StatelessWidget {
  const DistintivoRol({required this.rol, this.sobreFoto = false, super.key});

  final RolApp rol;
  final bool sobreFoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final fondo = sobreFoto ? SobreFotoCampo.fondoDistintivo : paleta.acento;
    final contenido = sobreFoto ? SobreFotoCampo.texto : paleta.sobreAcento;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(RadioCampo.capsula),
        border: sobreFoto ? Border.all(color: SobreFotoCampo.texto) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconoAgrocom(
              rol.icono,
              tamano: TamanoIconoCampo.chico,
              color: contenido,
              excluirSemantica: true,
            ),
            const SizedBox(width: EspaciadoCampo.xs),
            Flexible(
              child: Text(
                rol.distintivo(l10n),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: contenido,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca de la app: el nombre «DronAgro» con el distintivo del rol debajo
/// («Piloto» o «Cliente») y, a la izquierda, el ícono del rol. Es lo que
/// encabeza la portada, el ingreso y el registro, para que las dos apps se
/// distingan sin mostrar un selector de rol.
///
/// Con [compacto] reduce el tamaño para el encabezado de un formulario largo.
/// Un lector de pantalla lo anuncia como una sola frase.
class EncabezadoDeMarca extends StatelessWidget {
  const EncabezadoDeMarca({
    required this.rol,
    this.compacto = false,
    this.sobreFoto = false,
    super.key,
  });

  final RolApp rol;
  final bool compacto;
  final bool sobreFoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final colorTexto = sobreFoto ? SobreFotoCampo.texto : paleta.texto;
    final medida = compacto
        ? ObjetivoTactilCampo.minimo
        : ObjetivoTactilCampo.campo;
    return Semantics(
      container: true,
      header: true,
      label: rol.etiquetaSemantica(l10n),
      excludeSemantics: true,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: sobreFoto
                  ? SobreFotoCampo.fondoDistintivo
                  : paleta.acentoContenedor,
              borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
            ),
            child: SizedBox(
              width: medida,
              height: medida,
              child: Center(
                child: IconoAgrocom(
                  rol.icono,
                  tamano: compacto
                      ? TamanoIconoCampo.grande
                      : TamanoIconoCampo.destacado,
                  color: sobreFoto
                      ? SobreFotoCampo.texto
                      : paleta.sobreAcentoContenedor,
                  excluirSemantica: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.marcaNombre,
                  style: (compacto ? texto.titleLarge : texto.headlineMedium)
                      ?.copyWith(
                        color: colorTexto,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                DistintivoRol(rol: rol, sobreFoto: sobreFoto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
