import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/componentes/banner_sin_senal_campo.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tipografia_campo.dart';
import '../../ui/tokens_campo.dart';
import 'superficie_marketplace.dart';

/// Pantalla de error con salida (pantalla 21 del diseño): con falta de red,
/// el banner ámbar «Sin señal»; un «!» en un contenedor tonal de 88, el qué
/// pasó en un título y un texto, la tabla «qué funciona sin red» si aplica y
/// las acciones al pie: «Reintentar ahora» y, si hay otra salida, un botón
/// secundario («Volver a la negociación»).
///
/// Sirve para los errores de carga de las listas y para los de envío (una
/// oferta, una solicitud): el texto dice qué quedó guardado y qué hacer.
class EstadoErrorMarketplace extends StatelessWidget {
  const EstadoErrorMarketplace({
    required this.titulo,
    required this.onReintentar,
    this.detalle,
    this.sinConexion = false,
    this.tablaSinRed = false,
    this.etiquetaReintentar,
    this.etiquetaSecundaria,
    this.onSecundaria,
    super.key,
  }) : assert(
         (etiquetaSecundaria == null) == (onSecundaria == null),
         'La etiqueta y la acción secundaria van juntas',
       );

  final String titulo;
  final String? detalle;

  /// El fallo fue falta de red: muestra el banner ámbar.
  final bool sinConexion;

  /// Muestra «Qué funciona sin red» (solo en el flavor `piloto`, que
  /// trabaja sin señal en el lote).
  final bool tablaSinRed;

  /// Por defecto «Reintentar ahora».
  final String? etiquetaReintentar;
  final VoidCallback onReintentar;

  final String? etiquetaSecundaria;
  final VoidCallback? onSecundaria;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: paleta.errorContenedor,
              borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
            ),
            child: Text(
              '!',
              style: TipografiaCampo.cifraGrande.copyWith(
                color: paleta.sobreErrorContenedor,
              ),
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(titulo, style: texto.headlineSmall),
        ),
        if (detalle != null) ...[
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            detalle!,
            style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          ),
        ],
        if (tablaSinRed) ...[
          const SizedBox(height: EspaciadoCampo.xl),
          const _TablaSinRed(),
        ],
      ],
    );
    final acciones = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('estado-reintentar'),
          onPressed: onReintentar,
          child: Text(etiquetaReintentar ?? t.estadoReintentarAhora),
        ),
        if (etiquetaSecundaria != null) ...[
          const SizedBox(height: EspaciadoCampo.s),
          OutlinedButton(
            key: const ValueKey('estado-secundaria'),
            onPressed: onSecundaria,
            child: Text(etiquetaSecundaria!),
          ),
        ],
      ],
    );
    final banner = sinConexion
        ? BannerSinSenalCampo(mensaje: t.estadoSinSenalBanner)
        : null;
    return LayoutBuilder(
      builder: (context, c) {
        // Pantalla completa: contenido centrado y acciones al pie. Dentro de
        // una lista (alto sin tope): todo en su lugar, en orden.
        if (!c.hasBoundedHeight) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?banner,
              Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.xl),
                child: contenido,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EspaciadoCampo.l,
                  0,
                  EspaciadoCampo.l,
                  EspaciadoCampo.l,
                ),
                child: acciones,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?banner,
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(EspaciadoCampo.xl),
                  child: contenido,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EspaciadoCampo.l,
                  0,
                  EspaciadoCampo.l,
                  EspaciadoCampo.l,
                ),
                child: acciones,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// «Fotos y avance: Funcionan sin red · Ofertas y chat: Requieren red». El
/// estado va en texto, no solo en color.
class _TablaSinRed extends StatelessWidget {
  const _TablaSinRed();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    Widget fila(String clave, String valor, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              clave,
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
          ),
          Text(
            valor,
            style: texto.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: t.estadoTablaTitulo,
      child: SuperficieMarketplace(
        key: const ValueKey('tabla-sin-red'),
        child: Column(
          children: [
            fila(t.estadoTablaFotos, t.estadoTablaFuncionan, paleta.exito),
            fila(t.estadoTablaOfertas, t.estadoTablaRequieren, paleta.alerta),
          ],
        ),
      ),
    );
  }
}
