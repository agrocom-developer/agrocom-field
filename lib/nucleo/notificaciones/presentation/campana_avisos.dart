import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/aviso.dart';
import '../domain/avisos_de_la_cuenta.dart';
import '../domain/preferencias_canales.dart';
import '../domain/presentador_avisos.dart';
import 'bandeja_cubit.dart';
import 'bandeja_pantalla.dart';

/// La campana del encabezado: muestra cuántos avisos hay sin leer y abre
/// «Mis notificaciones». Lee la bandeja al montarse y cada vez que la app
/// vuelve a primer plano; la lectura no bloquea nada. Con un [presentador],
/// lo nuevo sale también como notificación del sistema.
class CampanaAvisos extends StatelessWidget {
  const CampanaAvisos({
    required this.repositorio,
    this.presentador,
    this.alAbrir,
    this.preferencias,
    super.key,
  });

  final PreferenciasCanalesStore? preferencias;
  final BandejaRepositorio repositorio;
  final PresentadorAvisos? presentador;
  final void Function(Aviso aviso)? alAbrir;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        BandejaCubit(repositorio, presentador: presentador)..cargar(),
    child: _Campana(alAbrir: alAbrir, preferencias: preferencias),
  );
}

class _Campana extends StatefulWidget {
  const _Campana({required this.alAbrir, required this.preferencias});

  final void Function(Aviso aviso)? alAbrir;
  final PreferenciasCanalesStore? preferencias;

  @override
  State<_Campana> createState() => _CampanaState();
}

class _CampanaState extends State<_Campana> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      context.read<BandejaCubit>().cargar();
    }
  }

  Future<void> _abrir(BuildContext context) async {
    final cubit = context.read<BandejaCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: BandejaPantalla(
            alAbrir: widget.alAbrir,
            preferencias: widget.preferencias,
          ),
        ),
      ),
    );
    if (mounted) await cubit.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<BandejaCubit, BandejaEstado>(
      buildWhen: (a, b) => a.noLeidas != b.noLeidas,
      builder: (context, estado) {
        final n = estado.noLeidas;
        return IconButton(
          key: const ValueKey('campana-avisos'),
          tooltip: n == 0
              ? l10n.avisosCampana
              : l10n.avisosCampanaConPendientes(n),
          onPressed: () => _abrir(context),
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n > 99 ? '99+' : '$n'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        );
      },
    );
  }
}

/// La campana de la cuenta: toma la bandeja y el presentador del árbol
/// (`RepositoryProvider<AvisosDeLaCuenta>`), de modo que cualquier encabezado
/// la ponga con una línea.
class CampanaAvisosDeLaCuenta extends StatelessWidget {
  const CampanaAvisosDeLaCuenta({this.alAbrir, super.key});

  final void Function(Aviso aviso)? alAbrir;

  @override
  Widget build(BuildContext context) {
    final avisos = context.read<AvisosDeLaCuenta>();
    return CampanaAvisos(
      repositorio: avisos.bandeja,
      presentador: avisos.presentador,
      alAbrir: alAbrir,
    );
  }
}
