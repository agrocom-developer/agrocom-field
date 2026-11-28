import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/boton_principal_marketplace.dart';
import '../../marketplace/ui/marketplace_ui.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../bloqueo_biometrico.dart';
import 'bloqueo_biometrico_cubit.dart';

/// Pantalla que sale al abrir la app con el bloqueo activo, antes de leer el
/// token guardado. Una acción principal: desbloquear. La salida es entrar con
/// la contraseña de Agrocom.
class PantallaBloqueoBiometrico extends StatelessWidget {
  const PantallaBloqueoBiometrico({
    required this.alDesbloquear,
    required this.alUsarContrasena,
    this.desbloqueando = false,
    super.key,
  });

  final VoidCallback alDesbloquear;
  final VoidCallback alUsarContrasena;
  final bool desbloqueando;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EspaciadoCampo.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 72,
                      color: paleta.acentoTexto,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.biometriaBloqueadaTitulo,
                      style: texto.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  Text(
                    l10n.biometriaBloqueadaDetalle,
                    style: texto.bodyLarge?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: EspaciadoCampo.xl),
                  BotonPrincipalMarketplace(
                    key: const Key('bloqueo-desbloquear'),
                    texto: l10n.biometriaDesbloquear,
                    alto: ObjetivoTactilCampo.guantes,
                    cargando: desbloqueando,
                    onPressed: alDesbloquear,
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  TextButton(
                    key: const Key('bloqueo-usar-contrasena'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: desbloqueando ? null : alUsarContrasena,
                    child: Text(l10n.biometriaUsarContrasena),
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

/// La fila de ajustes de cuenta que activa o apaga el bloqueo.
class FilaBloqueoBiometrico extends StatelessWidget {
  const FilaBloqueoBiometrico({
    required this.bloqueo,
    required this.motivoActivacion,
    super.key,
  });

  final BloqueoBiometrico bloqueo;
  final String motivoActivacion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BloqueoBiometricoCubit(bloqueo, motivoActivacion: motivoActivacion)
            ..cargar(),
      child: const _CuerpoFilaBloqueo(),
    );
  }
}

class _CuerpoFilaBloqueo extends StatelessWidget {
  const _CuerpoFilaBloqueo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return BlocBuilder<BloqueoBiometricoCubit, BloqueoBiometricoEstado>(
      builder: (context, estado) {
        final detalle = switch (estado.etapa) {
          EtapaBloqueoAjuste.cargando ||
          EtapaBloqueoAjuste.listo => l10n.biometriaAjusteDetalle,
          EtapaBloqueoAjuste.sinRegistrar => l10n.biometriaAjusteSinRegistrar,
          EtapaBloqueoAjuste.sinHardware => l10n.biometriaAjusteSinHardware,
        };
        final habilitado =
            estado.etapa == EtapaBloqueoAjuste.listo && !estado.trabajando;
        return SuperficieMarketplace(
          key: const Key('ajuste-bloqueo-biometrico'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
            ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        color: paleta.acentoTexto,
                      ),
                      const SizedBox(width: EspaciadoCampo.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.biometriaAjusteTitulo,
                              style: texto.titleMedium,
                            ),
                            Text(
                              detalle,
                              style: texto.bodyMedium?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        key: const Key('interruptor-bloqueo-biometrico'),
                        value: estado.activo,
                        onChanged: habilitado
                            ? (v) {
                                HapticaCampo.seleccion();
                                context.read<BloqueoBiometricoCubit>().cambiar(
                                  v,
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                  if (estado.noConfirmado) ...[
                    const SizedBox(height: EspaciadoCampo.s),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.biometriaNoConfirmada,
                        style: texto.bodyMedium?.copyWith(color: paleta.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
