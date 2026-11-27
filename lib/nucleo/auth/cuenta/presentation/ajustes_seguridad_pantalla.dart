import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/estado_error_marketplace.dart';
import '../../../marketplace/ui/superficie_marketplace.dart';
import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../bloqueo_biometrico.dart';
import '../../presentation/bloqueo_biometrico_widgets.dart';
import '../domain/cuenta_seguridad.dart';
import 'ajustes_seguridad_cubit.dart';
import 'cambiar_contrasena_pantalla.dart';
import 'eliminar_cuenta_pantalla.dart';
import 'textos_cuenta_seguridad.dart';
import 'verificar_telefono_hoja.dart';

/// «Seguridad y cuenta»: teléfono verificado, contraseña, desbloqueo con
/// huella o rostro, cerrar sesión y, aparte, «Eliminar mi cuenta». Es la misma
/// pantalla en `cliente` y en `piloto`; solo cambian los tokens del tema.
class AjustesSeguridadPantalla extends StatelessWidget {
  const AjustesSeguridadPantalla({
    required this.alCerrarSesion,
    this.bloqueo,
    super.key,
  });

  final BloqueoBiometrico? bloqueo;

  /// Cierra la sesión (revoca este dispositivo en el servidor).
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AjustesSeguridadCubit(context.read<CuentaSeguridadRepositorio>())
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Seguridad y cuenta')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _Cuerpo(bloqueo: bloqueo, alCerrarSesion: alCerrarSesion),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.bloqueo, required this.alCerrarSesion});

  final BloqueoBiometrico? bloqueo;
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final cubit = context.read<AjustesSeguridadCubit>();
    return RefreshIndicator(
      onRefresh: cubit.cargar,
      child: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          BlocBuilder<AjustesSeguridadCubit, AjustesSeguridadEstado>(
            builder: (context, estado) => switch (estado) {
              AjustesSeguridadCargando() => const EsqueletoCampo(alto: 72),
              AjustesSeguridadError(:final falla) => EstadoErrorMarketplace(
                compacto: true,
                titulo: 'No pudimos revisar tu teléfono',
                detalle: TextosCuentaSeguridad.falla(falla),
                sinConexion: falla is CuentaSinConexion,
                onReintentar: cubit.cargar,
              ),
              AjustesSeguridadListo(:final perfil) => FilaAjusteCuenta(
                key: const Key('ajuste-telefono'),
                icono: perfil.telefonoVerificado
                    ? Icons.verified_outlined
                    : Icons.phone_android_rounded,
                titulo: perfil.telefonoVerificado
                    ? 'Teléfono verificado'
                    : 'Verifica tu teléfono',
                detalle: perfil.telefonoVerificado
                    ? 'Podemos ayudarte a recuperar tu cuenta.'
                    : 'Confirma que el número es tuyo con un código.',
                alToque: perfil.telefonoVerificado
                    ? null
                    : () async {
                        final ok = await mostrarVerificarTelefono(context);
                        if (ok) await cubit.cargar();
                      },
              ),
            },
          ),
          const SizedBox(height: EspaciadoCampo.m),
          FilaAjusteCuenta(
            key: const Key('ajuste-contrasena'),
            icono: Icons.lock_outline_rounded,
            titulo: 'Cambiar contraseña',
            detalle: 'Te enviamos un código para confirmar que eres tú.',
            alToque: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => const CambiarContrasenaPantalla(),
              ),
            ),
          ),
          if (bloqueo != null) ...[
            const SizedBox(height: EspaciadoCampo.m),
            FilaBloqueoBiometrico(
              bloqueo: bloqueo!,
              motivoActivacion: l10n.biometriaMotivoActivar,
            ),
          ],
          const SizedBox(height: EspaciadoCampo.m),
          FilaAjusteCuenta(
            key: const Key('ajuste-cerrar-sesion'),
            icono: Icons.logout_rounded,
            titulo: 'Cerrar sesión',
            detalle: 'Este dispositivo dejará de tener acceso a tu cuenta.',
            alToque: alCerrarSesion,
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          Semantics(
            header: true,
            child: Text('Privacidad y datos', style: texto.titleMedium),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          FilaAjusteCuenta(
            key: const Key('ajuste-eliminar-cuenta'),
            icono: Icons.delete_outline_rounded,
            colorIcono: paleta.error,
            titulo: 'Eliminar mi cuenta',
            detalle:
                'Borra tus datos personales. Tienes 7 días para '
                'arrepentirte.',
            alToque: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    EliminarCuentaPantalla(alCerrarSesion: alCerrarSesion),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila de ajuste: ícono, título, detalle y, si tiene acción, la flecha.
class FilaAjusteCuenta extends StatelessWidget {
  const FilaAjusteCuenta({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.alToque,
    this.colorIcono,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback? alToque;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      button: alToque != null,
      label: detalle == null ? titulo : '$titulo. $detalle',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        onTap: alToque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
          ),
          child: Row(
            children: [
              Icon(icono, color: colorIcono ?? paleta.acentoTexto),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleMedium),
                    if (detalle != null)
                      Text(
                        detalle!,
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                  ],
                ),
              ),
              if (alToque != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: paleta.textoSecundario,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
