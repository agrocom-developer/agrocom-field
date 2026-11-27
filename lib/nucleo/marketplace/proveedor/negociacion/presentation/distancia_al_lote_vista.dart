import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/hoja_inferior_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/geo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/formato_marketplace.dart';
import '../../ejecucion/domain/ejecucion.dart';
import 'distancia_cubit.dart';

/// «A 12,4 km del lote»: la distancia del piloto al lote para decidir su
/// precio. Se calcula en el teléfono cuando la persona la pide; el permiso de
/// ubicación aparece en ese momento, con su explicación. Nada se guarda ni se
/// envía.
class DistanciaAlLoteVista extends StatelessWidget {
  const DistanciaAlLoteVista({
    required this.lote,
    required this.servicio,
    super.key,
  });

  /// El punto del lote (centro de su polígono); `null` si no hay.
  final GeoPunto? lote;
  final ServicioUbicacion servicio;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DistanciaCubit(servicio),
    child: _Contenido(lote: lote),
  );
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.lote});

  final GeoPunto? lote;

  Future<bool> _explicar(BuildContext context) async =>
      await mostrarHojaInferiorCampo<bool>(
        context: context,
        builder: (_) => const _HojaDistancia(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<DistanciaCubit>();
    return BlocBuilder<DistanciaCubit, DistanciaEstado>(
      builder: (context, e) {
        final calculando = e.fase == FaseDistancia.calculando;
        final (String titulo, String? detalle) = switch (e.fase) {
          FaseDistancia.lista => (
            l10n.distanciaResultado(FormatoMarketplace.kilometros(e.km!)),
            l10n.distanciaResultadoAyuda,
          ),
          FaseDistancia.calculando => (l10n.distanciaCalculando, null),
          FaseDistancia.sinPermiso => (l10n.distanciaSinPermiso, null),
          FaseDistancia.denegadoParaSiempre => (
            l10n.distanciaDenegadoSiempre,
            null,
          ),
          FaseDistancia.servicioApagado => (
            l10n.distanciaServicioApagado,
            null,
          ),
          FaseDistancia.sinPosicion => (l10n.distanciaSinPosicion, null),
          FaseDistancia.sinLote => (l10n.distanciaSinLote, null),
          FaseDistancia.inicial => (
            l10n.distanciaPregunta,
            l10n.distanciaAyuda,
          ),
        };
        final hayAccion =
            e.fase != FaseDistancia.sinLote &&
            e.fase != FaseDistancia.denegadoParaSiempre;
        return Semantics(
          container: true,
          liveRegion: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes,
            ),
            child: Row(
              key: const ValueKey('distancia-al-lote'),
              children: [
                Icon(
                  e.fase == FaseDistancia.lista
                      ? Icons.near_me_rounded
                      : Icons.near_me_outlined,
                  color: paleta.acentoTexto,
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: texto.titleSmall),
                      if (detalle != null)
                        Text(
                          detalle,
                          style: texto.bodySmall?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                    ],
                  ),
                ),
                if (calculando)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hayAccion)
                  TextButton(
                    key: const ValueKey('distancia-calcular'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        ObjetivoTactilCampo.guantes,
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: () => cubit.calcular(
                      lote,
                      explicar: () => _explicar(context),
                    ),
                    child: Text(
                      e.fase == FaseDistancia.lista
                          ? l10n.distanciaActualizar
                          : l10n.distanciaVer,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HojaDistancia extends StatelessWidget {
  const _HojaDistancia();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EspaciadoCampo.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.near_me_outlined, size: 36, color: paleta.acentoTexto),
          const SizedBox(height: EspaciadoCampo.m),
          Semantics(
            header: true,
            child: Text(l10n.distanciaHojaTitulo, style: texto.titleLarge),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(l10n.distanciaHojaMotivo, style: texto.bodyLarge),
          const SizedBox(height: EspaciadoCampo.m),
          Text(
            l10n.distanciaHojaPrivacidad,
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrincipalMarketplace(
            key: const ValueKey('distancia-continuar'),
            texto: l10n.distanciaHojaContinuar,
            alto: ObjetivoTactilCampo.guantes,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          TextButton(
            key: const ValueKey('distancia-ahora-no'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.distanciaHojaAhoraNo),
          ),
        ],
      ),
    );
  }
}
