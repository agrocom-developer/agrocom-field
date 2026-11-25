import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/oferta_recibida.dart';

/// Perfil público del piloto (pantalla 19): lo que el cliente ve antes de
/// elegir. Solo muestra lo que el contrato entrega con la oferta: nombre,
/// foto, calificación, cancelaciones y el dron. Lo demás (licencia verificada,
/// servicios, hectáreas, reseñas) está en `docs/gestion/brechas-api.md`.
///
/// Devuelve `true` al cerrarse si la persona tocó «Elegir».
class PerfilProveedorPantalla extends StatelessWidget {
  const PerfilProveedorPantalla({
    required this.oferta,
    required this.nombreLote,
    this.puedeElegir = true,
    super.key,
  });

  final OfertaRecibida oferta;
  final String nombreLote;

  /// La oferta sigue vigente y espera la respuesta del cliente.
  final bool puedeElegir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = oferta.proveedor;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.perfilPublicoOfertaPara(nombreLote),
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            Text(t.perfilPublicoTitulo, style: texto.titleLarge),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(margen),
        children: [
          Row(
            children: [
              AvatarFoto(
                iniciales: p.iniciales,
                etiqueta: t.perfilPublicoFotoDe(p.nombre),
                url: p.fotoUrl,
                tamano: 72,
              ),
              const SizedBox(width: EspaciadoCampo.l),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(p.nombre, style: texto.headlineSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.l),
          SuperficieMarketplace(
            child: Row(
              children: [
                Expanded(
                  child: _Cifra(
                    p.calificaciones == 0
                        ? '—'
                        : p.calificacion
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                    t.perfilPublicoEstadCalificacion,
                  ),
                ),
                Expanded(
                  child: _Cifra(
                    '${p.calificaciones}',
                    t.perfilPublicoEstadResenas,
                  ),
                ),
                Expanded(
                  child: _Cifra(
                    '${(p.tasaCancelacion * 100).round()} %',
                    t.perfilPublicoEstadCumplimiento,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          Semantics(
            header: true,
            child: Text(
              t.perfilPublicoEquipo,
              style: TipografiaCampo.etiquetaMono.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          SuperficieMarketplace(child: _Dron(proveedor: p)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: paleta.superficie,
            border: Border(top: BorderSide(color: paleta.borde)),
          ),
          child: Padding(
            padding: EdgeInsets.all(margen),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.perfilPublicoSuOferta,
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      Text(
                        l10n.ofertasBsHa(
                          FormatoMarketplace.bsNumero(oferta.precioHa),
                        ),
                        key: const ValueKey('perfil-publico-precio'),
                        style: TipografiaCampo.cifraMedia.copyWith(
                          color: paleta.texto,
                        ),
                      ),
                      Text(
                        t.perfilPublicoTotal(
                          FormatoMarketplace.bs(oferta.montoEstimado),
                        ),
                        style: TipografiaCampo.datoMono.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                if (puedeElegir) ...[
                  const SizedBox(width: EspaciadoCampo.l),
                  SizedBox(
                    width: 160,
                    child: BotonPrincipalMarketplace(
                      key: const ValueKey('perfil-publico-elegir'),
                      texto: t.perfilPublicoElegir,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dron extends StatelessWidget {
  const _Dron({required this.proveedor});

  final ProveedorOfertante proveedor;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = proveedor;
    if (p.dron.isEmpty) {
      return Text(
        t.perfilPublicoSinDron,
        style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
      );
    }
    final litros = p.capacidadLitros;
    return Row(
      children: [
        Container(
          width: ObjetivoTactilCampo.minimo,
          height: ObjetivoTactilCampo.minimo,
          decoration: BoxDecoration(
            color: paleta.grafito,
            borderRadius: BorderRadius.circular(RadioCampo.media),
          ),
          child: Icon(Icons.flight_rounded, color: paleta.sobreGrafito),
        ),
        const SizedBox(width: EspaciadoCampo.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                litros == null
                    ? p.dron
                    : t.perfilPublicoDron(
                        p.dron,
                        FormatoMarketplace.numero(litros, decimales: 0),
                      ),
                style: texto.titleMedium,
              ),
              if (p.anioDron != null)
                Text(
                  t.perfilPublicoDronAnio(p.anioDron!),
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TipografiaCampo.cifraMedia.copyWith(
            color: context.paleta.texto,
          ),
        ),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ],
    );
  }
}
