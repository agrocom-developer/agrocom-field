import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../bloqueo_biometrico.dart';
import '../domain/cuenta_seguridad.dart';
import 'ajustes_seguridad_cubit.dart';
import 'ajustes_seguridad_pantalla.dart';

/// La fila «Seguridad y cuenta» del perfil (cliente y proveedor): dice si el
/// teléfono está verificado y abre [AjustesSeguridadPantalla]. Si la app no
/// provee el repositorio de seguridad (demos mínimas, pruebas), no se muestra.
class FilaSeguridadPerfil extends StatelessWidget {
  const FilaSeguridadPerfil({
    required this.alCerrarSesion,
    this.bloqueo,
    super.key,
  });

  final BloqueoBiometrico? bloqueo;
  final VoidCallback alCerrarSesion;

  /// `true` si el árbol tiene el repositorio de seguridad de la cuenta.
  static bool disponible(BuildContext context) {
    try {
      context.read<CuentaSeguridadRepositorio>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!disponible(context)) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) =>
          AjustesSeguridadCubit(context.read<CuentaSeguridadRepositorio>())
            ..cargar(),
      child: _Fila(bloqueo: bloqueo, alCerrarSesion: alCerrarSesion),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.bloqueo, required this.alCerrarSesion});

  final BloqueoBiometrico? bloqueo;
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AjustesSeguridadCubit>();
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AjustesSeguridadCubit, AjustesSeguridadEstado>(
      builder: (context, estado) {
        final verificado =
            estado is AjustesSeguridadListo && estado.perfil.telefonoVerificado;
        final pendiente =
            estado is AjustesSeguridadListo &&
            !estado.perfil.telefonoVerificado;
        return FilaAjusteCuenta(
          key: const Key('perfil-seguridad'),
          icono: pendiente
              ? Icons.shield_outlined
              : Icons.verified_user_outlined,
          titulo: l10n.cuentaSeguridadTitulo,
          detalle: pendiente
              ? l10n.cuentaTelefonoFaltaVerificar
              : verificado
              ? l10n.cuentaTelefonoVerificado
              : l10n.cuentaSeguridadFilaDetalle,
          alToque: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AjustesSeguridadPantalla(
                  bloqueo: bloqueo,
                  alCerrarSesion: alCerrarSesion,
                ),
              ),
            );
            if (!cubit.isClosed) await cubit.cargar();
          },
        );
      },
    );
  }
}
