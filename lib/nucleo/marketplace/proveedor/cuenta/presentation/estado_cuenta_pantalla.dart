import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart' show EstadoAprobacion;
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/cuenta_proveedor.dart';
import 'documentos_pantalla.dart';
import 'estado_cuenta_cubit.dart';
import 'textos_cuenta.dart';

/// Deja pasar al contenido (el mapa de solicitudes) solo a un proveedor
/// aprobado. Mientras no, muestra [EstadoCuentaPantalla]: la app queda en solo
/// lectura (CLAUDE.md, «Alta de proveedores»). Relee el estado al volver de
/// segundo plano; el servidor decide.
class PuertaAprobacion extends StatelessWidget {
  const PuertaAprobacion({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EstadoCuentaCubit(context.read<CuentaProveedorRepositorio>())
            ..cargar(),
      child: _Observador(child: child),
    );
  }
}

class _Observador extends StatefulWidget {
  const _Observador({required this.child});

  final Widget child;

  @override
  State<_Observador> createState() => _ObservadorState();
}

class _ObservadorState extends State<_Observador> with WidgetsBindingObserver {
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
      context.read<EstadoCuentaCubit>().actualizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<EstadoCuentaCubit, EstadoCuentaEstado>(
      builder: (context, estado) => switch (estado) {
        EstadoCuentaCargando() => const Center(
          child: CircularProgressIndicator(),
        ),
        EstadoCuentaError(:final mensaje, :final sinRed) =>
          EstadoErrorMarketplace(
            titulo: l10n.cuentaErrorCarga,
            detalle: sinRed
                ? l10n.cuentaSinRed
                : (mensaje ?? l10n.cuentaErrorDetalle),
            sinConexion: sinRed,
            onReintentar: context.read<EstadoCuentaCubit>().cargar,
          ),
        EstadoCuentaListo(:final cuenta) when cuenta.puedeVerMapa =>
          widget.child,
        EstadoCuentaListo() => const EstadoCuentaPantalla(),
      },
    );
  }
}

/// «En revisión» (o rechazada o suspendida) y qué falta. Una acción
/// principal: subir lo que falta o, tras un rechazo, reenviar.
class EstadoCuentaPantalla extends StatelessWidget {
  const EstadoCuentaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final estado = context.watch<EstadoCuentaCubit>().state;
    if (estado is! EstadoCuentaListo) return const SizedBox.shrink();
    final cuenta = estado.cuenta;
    final (titulo, detalle, icono) = switch (cuenta.aprobacion) {
      EstadoAprobacion.rechazado => (
        l10n.cuentaRechazadaTitulo,
        l10n.cuentaRechazadaDetalle,
        Icons.cancel_outlined,
      ),
      EstadoAprobacion.suspendido => (
        l10n.cuentaSuspendidaTitulo,
        l10n.cuentaSuspendidaDetalle,
        Icons.pause_circle_outline_rounded,
      ),
      _ => (
        l10n.cuentaEnRevisionTitulo,
        l10n.cuentaEnRevisionDetalle,
        Icons.hourglass_top_rounded,
      ),
    };
    final cubit = context.read<EstadoCuentaCubit>();
    return RefreshIndicator(
      onRefresh: cubit.actualizar,
      child: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 36, color: paleta.acentoTexto),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(titulo, style: texto.headlineSmall),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EspaciadoCampo.m),
          Text(detalle, style: texto.bodyLarge),
          if (cuenta.motivo != null &&
              cuenta.aprobacion != EstadoAprobacion.pendiente) ...[
            const SizedBox(height: EspaciadoCampo.m),
            AvisoMarketplace(
              mensaje: l10n.cuentaMotivo(cuenta.motivo!),
              tono: TonoAviso.alerta,
            ),
          ],
          if (estado.aviso != null) ...[
            const SizedBox(height: EspaciadoCampo.m),
            Semantics(
              liveRegion: true,
              child: AvisoMarketplace(
                mensaje: estado.aviso!,
                tono: TonoAviso.error,
              ),
            ),
          ],
          const SizedBox(height: EspaciadoCampo.xl),
          Text(l10n.cuentaQueFalta, style: texto.titleMedium),
          const SizedBox(height: EspaciadoCampo.s),
          if (cuenta.documentosFaltantes.isEmpty)
            Text(
              l10n.cuentaNadaFalta,
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            )
          else
            for (final tipo in cuenta.documentosFaltantes)
              Padding(
                padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: paleta.textoSecundario,
                      ),
                    ),
                    const SizedBox(width: EspaciadoCampo.s),
                    Expanded(
                      child: Text(tipo.etiqueta(l10n), style: texto.bodyLarge),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: EspaciadoCampo.xl),
          if (cuenta.aprobacion == EstadoAprobacion.rechazado)
            BotonPrincipalMarketplace(
              key: const Key('cuenta-reenviar'),
              texto: l10n.cuentaReenviar,
              alto: ObjetivoTactilCampo.guantes,
              cargando: estado.reenviando,
              onPressed: () => cubit.reenviar(mensajeSinRed: l10n.cuentaSinRed),
            )
          else if (cuenta.documentosFaltantes.isNotEmpty)
            BotonPrincipalMarketplace(
              key: const Key('cuenta-subir-documentos'),
              texto: l10n.cuentaSubirDocumentos,
              icono: Icons.photo_camera_outlined,
              alto: ObjetivoTactilCampo.guantes,
              onPressed: () =>
                  abrirDocumentos(context, alVolver: cubit.actualizar),
            ),
          const SizedBox(height: EspaciadoCampo.s),
          TextButton.icon(
            key: const Key('cuenta-actualizar'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
            ),
            onPressed: estado.actualizando ? null : cubit.actualizar,
            icon: estado.actualizando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(l10n.cuentaActualizar),
          ),
        ],
      ),
    );
  }
}
