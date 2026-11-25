import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/componentes/banner_sin_senal_campo.dart';
import '../domain/conectividad_servicio.dart';
import 'conectividad_cubit.dart';

/// Pone el banner «Sin señal» sobre [child] cuando el celular no tiene red,
/// y lo quita al volver. Va en el shell de cada flavor; [servicio] es el real
/// en producción y el falso en la demo y las pruebas.
class ConBannerDeRed extends StatelessWidget {
  const ConBannerDeRed({
    required this.servicio,
    required this.child,
    super.key,
  });

  final ConectividadServicio servicio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConectividadCubit(servicio),
      child: BlocBuilder<ConectividadCubit, EstadoRed>(
        builder: (context, estado) {
          final sinRed = estado == EstadoRed.sinRed;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sinRed)
                BannerSinSenalCampo(
                  titulo: AppLocalizations.of(context).redSinSenalTitulo,
                  mensaje: AppLocalizations.of(context).redSinSenalMensaje,
                ),
              // El banner ya consumió la zona segura de arriba.
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: sinRed,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
