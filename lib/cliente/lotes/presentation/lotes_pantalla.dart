import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../solicitar/domain/solicitud_repositorio.dart';
import 'fila_lote.dart';
import 'lotes_cubit.dart';

/// Pestaña «Lotes»: los lotes registrados del cliente. Los lotes nacen al
/// publicar una solicitud (se marcan en el mapa), así que la salida de la
/// pantalla vacía y la acción principal son «Publicar lote».
class LotesPantalla extends StatelessWidget {
  const LotesPantalla({required this.alPublicar, super.key});

  final VoidCallback alPublicar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LotesCubit(context.read<SolicitudRepositorio>())..cargar(),
      child: _Vista(alPublicar: alPublicar),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.alPublicar});

  final VoidCallback alPublicar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BlocBuilder<LotesCubit, LotesEstado>(
      builder: (context, estado) => switch (estado) {
        LotesCargando() => const Padding(
          padding: EdgeInsets.all(EspaciadoCampo.l),
          child: EsqueletoCampo(alto: 160),
        ),
        LotesError(:final sinConexion) => EstadoFalla(
          sinConexion: sinConexion,
          queNoCargo: t.lotesTitulo.toLowerCase(),
          alReintentar: context.read<LotesCubit>().cargar,
        ),
        LotesListos(:final lotes) when lotes.isEmpty => EstadoVacioMarketplace(
          icono: Icons.crop_square_rounded,
          titulo: t.lotesVacioTitulo,
          detalle: t.lotesVacioDetalle,
          etiquetaAccion: t.publicarLote,
          alAccion: alPublicar,
        ),
        LotesListos(:final lotes) => ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Semantics(
              header: true,
              child: Text(
                t.lotesTitulo,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            SuperficieMarketplace(
              padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
              child: Column(
                children: [for (final lote in lotes) FilaLote(lote: lote)],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            BotonPrincipalMarketplace(
              texto: t.publicarLote,
              icono: Icons.add_rounded,
              onPressed: alPublicar,
            ),
          ],
        ),
      },
    );
  }
}
