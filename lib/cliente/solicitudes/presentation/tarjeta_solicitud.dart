import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/barra_avance.dart';
import '../../comun/presentation/insignia_estado_solicitud.dart';
import '../domain/solicitud.dart';

/// Resumen de una solicitud para listas: lote, estado, cifras en mono
/// (superficie, precio por hectárea y total) y, según el estado, el avance
/// «48 / 85 ha» o el piloto elegido.
///
/// Con [destacada] es la tarjeta protagonista del inicio: radio grande, el
/// nombre del lote en grande y el [titulo] en mayúsculas encima.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({
    required this.solicitud,
    this.onTap,
    this.acciones = const [],
    this.resaltada = false,
    this.destacada = false,
    this.titulo,
    super.key,
  });

  final Solicitud solicitud;
  final VoidCallback? onTap;
  final List<Widget> acciones;
  final bool resaltada;
  final bool destacada;

  /// Rótulo de la tarjeta destacada («Solicitud activa»).
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final s = solicitud;
    final conteoOfertas = s.estado == EstadoSolicitud.conOfertas
        ? s.ofertasVigentes
        : null;
    final enEjecucion = s.estado == EstadoSolicitud.enEjecucion;
    final secundario = TipografiaCampo.cuerpoSecundario.copyWith(
      color: paleta.textoSecundario,
    );
    return SuperficieMarketplace(
      onTap: onTap,
      resaltada: resaltada,
      radio: destacada ? RadioCampo.tarjeta : RadioCampo.tarjetaCompacta,
      padding: EdgeInsets.all(destacada ? EspaciadoCampo.xl : EspaciadoCampo.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (titulo != null)
                Expanded(
                  child: Text(
                    titulo!.toUpperCase(),
                    style: TipografiaCampo.etiquetaMono.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    s.lote.nombre,
                    style: TipografiaCampo.tituloSeccion.copyWith(
                      color: paleta.texto,
                    ),
                  ),
                ),
              const SizedBox(width: EspaciadoCampo.s),
              Flexible(
                child: InsigniaEstadoSolicitud(
                  s.estado,
                  ofertas: conteoOfertas,
                ),
              ),
            ],
          ),
          if (titulo != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text(
              s.lote.nombre,
              style: TipografiaCampo.valorDestacado.copyWith(
                color: paleta.texto,
              ),
            ),
          ],
          const SizedBox(height: EspaciadoCampo.xs),
          Text('${s.lote.zona} · ${s.cultivo}', style: secundario),
          const SizedBox(height: EspaciadoCampo.m),
          if (enEjecucion)
            _Avance(solicitud: s)
          else
            GrupoStatsCampo(
              children: [
                _Dato(
                  etiqueta: l10n.solicitudesSuperficie,
                  valor: FormatoMarketplace.hectareasNumero(s.hectareas),
                  unidad: 'ha',
                ),
                _Dato(
                  etiqueta: s.precioHaAcordado != null
                      ? l10n.solicitudesPrecioAcordado
                      : l10n.solicitudesPrecio,
                  valor: FormatoMarketplace.bsNumero(s.precioHaVigente),
                  unidad: 'Bs/ha',
                ),
                _Dato(
                  etiqueta: l10n.solicitudesTotal,
                  valor: FormatoMarketplace.bsNumero(s.totalAPagar),
                  unidad: 'Bs',
                ),
              ],
            ),
          if (s.nombreProveedor != null && s.estado.conPiloto) ...[
            const SizedBox(height: EspaciadoCampo.m),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: paleta.textoSecundario,
                ),
                const SizedBox(width: EspaciadoCampo.xs),
                Expanded(
                  child: Text(
                    s.nombreProveedor!,
                    style: secundario,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (s.estado == EstadoSolicitud.calificada &&
              s.puntajeDelCliente != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Row(
              children: [
                const EstrellaCampo(tamano: 16),
                const SizedBox(width: EspaciadoCampo.xs),
                Text(
                  l10n.solicitudesCalificasteCon(s.puntajeDelCliente!),
                  style: secundario,
                ),
              ],
            ),
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: EspaciadoCampo.l),
            Row(children: [for (final a in acciones) Expanded(child: a)]),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta y cifra en mono, para la fila de datos de la tarjeta.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
  });

  final String etiqueta;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TipografiaCampo.cuerpoSecundario.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
        CifraCampo(
          valor: valor,
          unidad: unidad,
          estilo: TipografiaCampo.cifraMedia,
        ),
      ],
    );
  }
}

/// «48 / 85 ha» en mono, el porcentaje a la derecha y la barra debajo.
class _Avance extends StatelessWidget {
  const _Avance({required this.solicitud});

  final Solicitud solicitud;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final s = solicitud;
    final ejecutadas = s.hectareasEjecutadas;
    final porcentaje = s.porcentajeAvance?.toStringAsFixed(0) ?? '0';
    final etiqueta = l10n.solicitudesAvanceHectareas(
      ejecutadas == null ? '0' : FormatoMarketplace.hectareasNumero(ejecutadas),
      FormatoMarketplace.hectareasNumero(s.hectareas),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: TipografiaCampo.cifraMedia.copyWith(color: paleta.texto),
              ),
            ),
            Text(
              '$porcentaje %',
              style: TipografiaCampo.datoMono.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.s),
        BarraAvance(valor: s.progreso, etiqueta: etiqueta),
      ],
    );
  }
}
