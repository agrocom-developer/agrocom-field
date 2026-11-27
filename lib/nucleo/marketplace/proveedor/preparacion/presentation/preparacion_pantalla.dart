import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../data/preparacion_local.dart';
import '../domain/preparacion.dart';
import 'preparacion_cubit.dart';
import 'textos_preparacion.dart';

/// «Preparación del equipo»: la lista de lo que se revisa antes de salir, con
/// el progreso arriba. Se guarda en el teléfono, funciona sin red y no
/// bloquea ofertar ni iniciar un servicio.
class PreparacionEquipoPantalla extends StatelessWidget {
  const PreparacionEquipoPantalla({this.store, this.servicioId, super.key});

  /// Dónde se guarda; por defecto, el almacén local del teléfono.
  final PreparacionStore? store;

  /// La lista de un servicio; sin él, la genérica del piloto.
  final int? servicioId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          PreparacionCubit(store ?? PreparacionLocal(), servicioId: servicioId)
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.preparacionTitulo),
          actions: [
            Builder(
              builder: (context) => PopupMenuButton<void>(
                key: const ValueKey('preparacion-menu'),
                tooltip: l10n.preparacionReiniciar,
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    key: const ValueKey('preparacion-reiniciar'),
                    height: ObjetivoTactilCampo.guantes,
                    onTap: context.read<PreparacionCubit>().reiniciar,
                    child: Text(l10n.preparacionReiniciar),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: const SafeArea(child: _Lista()),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<PreparacionCubit, PreparacionEstado>(
      builder: (context, estado) {
        if (estado.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = estado.lista;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text(
              l10n.preparacionIntro,
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _Progreso(lista: lista),
            if (estado.noSeGuardo) ...[
              const SizedBox(height: EspaciadoCampo.m),
              AvisoMarketplace(
                mensaje: l10n.preparacionNoGuardo,
                tono: TonoAviso.alerta,
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            for (final item in ItemPreparacion.values) ...[
              _FilaItem(item: item, hecho: lista.estaHecho(item)),
              const SizedBox(height: EspaciadoCampo.s),
            ],
          ],
        );
      },
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.lista});

  final ChecklistPreparacion lista;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final titulo = lista.completo
        ? l10n.preparacionCompleta
        : l10n.preparacionProgreso(lista.completados, lista.total);
    return Semantics(
      container: true,
      liveRegion: true,
      label: titulo,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (lista.completo) ...[
                Icon(Icons.check_circle_rounded, color: paleta.exito),
                const SizedBox(width: EspaciadoCampo.s),
              ],
              Expanded(child: Text(titulo, style: texto.titleMedium)),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(RadioCampo.capsula),
            child: LinearProgressIndicator(
              key: const ValueKey('preparacion-progreso'),
              value: lista.progreso,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  const _FilaItem({required this.item, required this.hecho});

  final ItemPreparacion item;
  final bool hecho;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<PreparacionCubit>();
    void alternar() {
      HapticaCampo.seleccion();
      cubit.alternar(item);
    }

    return Semantics(
      inMutuallyExclusiveGroup: false,
      checked: hecho,
      label: '${item.titulo(l10n)}. ${item.detalle(l10n)}',
      excludeSemantics: true,
      onTap: alternar,
      child: Material(
        color: hecho ? paleta.acentoContenedor : paleta.superficie,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: InkWell(
          key: ValueKey('preparacion-${item.name}'),
          borderRadius: BorderRadius.circular(RadioCampo.media),
          onTap: alternar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.campo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.m,
                vertical: EspaciadoCampo.s,
              ),
              child: Row(
                children: [
                  Icon(item.icono, color: paleta.textoSecundario),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.titulo(l10n), style: texto.titleSmall),
                        Text(
                          item.detalle(l10n),
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: EspaciadoCampo.s),
                  // La marca es un ícono con forma, no solo un color.
                  Icon(
                    hecho
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: hecho ? paleta.acentoTexto : paleta.bordeFuerte,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La entrada a la preparación para el inicio del piloto: muestra el avance
/// guardado y abre la lista. Una tarjeta, sin bloquear nada.
class AccesoPreparacionEquipo extends StatefulWidget {
  const AccesoPreparacionEquipo({this.store, super.key});

  final PreparacionStore? store;

  @override
  State<AccesoPreparacionEquipo> createState() =>
      _AccesoPreparacionEquipoState();
}

class _AccesoPreparacionEquipoState extends State<AccesoPreparacionEquipo> {
  late final PreparacionStore _store = widget.store ?? PreparacionLocal();
  ChecklistPreparacion _lista = const ChecklistPreparacion();

  @override
  void initState() {
    super.initState();
    _leer();
  }

  Future<void> _leer() async {
    try {
      final lista = await _store.leer();
      if (mounted) setState(() => _lista = lista);
    } on Object {
      // Es solo un resumen: sin lectura se muestra sin avance.
    }
  }

  Future<void> _abrir() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreparacionEquipoPantalla(store: _store),
      ),
    );
    if (mounted) await _leer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          '${l10n.preparacionAcceso}. '
          '${l10n.preparacionProgreso(_lista.completados, _lista.total)}',
      excludeSemantics: true,
      onTap: _abrir,
      child: Material(
        color: paleta.superficie,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: InkWell(
          key: const ValueKey('acceso-preparacion'),
          borderRadius: BorderRadius.circular(RadioCampo.media),
          onTap: _abrir,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.campo,
            ),
            child: Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.m),
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded, color: paleta.acentoTexto),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.preparacionAcceso, style: texto.titleSmall),
                        Text(
                          l10n.preparacionProgreso(
                            _lista.completados,
                            _lista.total,
                          ),
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: paleta.textoSecundario,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
