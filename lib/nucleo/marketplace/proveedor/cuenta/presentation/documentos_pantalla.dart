import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../permisos/domain/permiso.dart';
import '../../../../permisos/presentation/hoja_permiso.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../foto_preparador.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/cuenta_proveedor.dart';
import 'documentos_cubit.dart';
import 'textos_cuenta.dart';

/// Abre «Mis documentos». [alVolver] corre al cerrarla (para releer el estado
/// de la cuenta).
Future<void> abrirDocumentos(
  BuildContext context, {
  VoidCallback? alVolver,
}) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DocumentosPantalla()));
  alVolver?.call();
}

/// Lista de documentos que lanza la cámara por ítem. Cada uno tiene su estado
/// (falta, subiendo, en revisión, aprobado, rechazado, vencido, no se envió)
/// y su acción.
class DocumentosPantalla extends StatelessWidget {
  const DocumentosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => DocumentosCubit(
        context.read<CuentaProveedorRepositorio>(),
        context.read<PreparadorFoto>(),
        l10n,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.documentosTitulo)),
        body: const _Lista(),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return BlocBuilder<DocumentosCubit, DocumentosEstado>(
      builder: (context, estado) {
        if (estado.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.error) {
          return EstadoErrorMarketplace(
            titulo: l10n.documentosErrorCarga,
            detalle: estado.sinRed
                ? l10n.cuentaSinRed
                : l10n.cuentaErrorDetalle,
            sinConexion: estado.sinRed,
            onReintentar: context.read<DocumentosCubit>().cargar,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text(
              l10n.documentosIntro,
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            if (estado.aviso != null) ...[
              const SizedBox(height: EspaciadoCampo.m),
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  mensaje: estado.aviso!,
                  tono: TonoAviso.alerta,
                ),
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            if (estado.items.isEmpty)
              EstadoVacioMarketplace(
                icono: Icons.task_alt_rounded,
                titulo: l10n.documentosVacio,
                detalle: l10n.documentosVacioDetalle,
              )
            else
              for (final item in estado.items) ...[
                _FilaDocumento(item: item),
                const SizedBox(height: EspaciadoCampo.m),
              ],
          ],
        );
      },
    );
  }
}

/// `dd/mm/aaaa`.
String _fecha(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/'
    '${f.month.toString().padLeft(2, '0')}/${f.year}';

class _FilaDocumento extends StatelessWidget {
  const _FilaDocumento({required this.item});

  final ItemDocumento item;

  Future<void> _capturar(BuildContext context) async {
    final cubit = context.read<DocumentosCubit>();
    final gestor = context.read<GestorPermisos>();
    final l10n = AppLocalizations.of(context);

    // Primero se explica para qué; solo entonces sale el aviso del sistema.
    final permiso = await pedirPermisoConExplicacion(
      context,
      gestor,
      PermisoApp.camara,
    );
    if (permiso != ResultadoPermiso.concedido || !context.mounted) return;

    var denegada = false;
    final foto = await cubit.tomar(
      item.tipo,
      alDenegar: () {
        gestor.registrarDenegadoParaSiempre(PermisoApp.camara);
        denegada = true;
      },
    );
    if (!context.mounted) return;
    if (denegada) {
      await pedirPermisoConExplicacion(context, gestor, PermisoApp.camara);
      return;
    }
    if (foto == null) return;

    DateTime? vence;
    if (item.tipo.exigeVencimiento) {
      final hoy = DateTime.now();
      vence = await showDatePicker(
        context: context,
        helpText: l10n.documentosPreguntaVence,
        firstDate: DateTime(hoy.year, hoy.month, hoy.day),
        lastDate: DateTime(hoy.year + 20, hoy.month, hoy.day),
      );
      // Sin fecha no se envía: el servidor la exige y suspendería al vencer.
      if (vence == null) return;
    }
    await cubit.enviar(
      DocumentoPorSubir(tipo: foto.tipo, bytes: foto.bytes, venceEn: vence),
    );
    final subido = cubit.state.items.where((i) => i.tipo == item.tipo);
    if (subido.isNotEmpty && subido.first.etapa == EtapaDocumento.enRevision) {
      HapticaCampo.confirmacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final nombre = item.tipo.etiqueta(l10n);
    final etapa = item.etapa.etiqueta(l10n);
    final color = switch (item.etapa) {
      EtapaDocumento.aprobado => paleta.exito,
      EtapaDocumento.rechazado ||
      EtapaDocumento.vencido ||
      EtapaDocumento.errorEnvio => paleta.error,
      _ => paleta.textoSecundario,
    };
    final detalle = switch (item.etapa) {
      EtapaDocumento.rechazado || EtapaDocumento.errorEnvio => item.mensaje,
      _ when item.venceEn != null => l10n.documentosVence(
        _fecha(item.venceEn!),
      ),
      _ => null,
    };
    final etiquetaBoton = switch (item.etapa) {
      EtapaDocumento.faltante => l10n.documentosTomarFoto,
      EtapaDocumento.errorEnvio => l10n.documentosReintentar,
      _ => l10n.documentosVolverATomar,
    };
    return SuperficieMarketplace(
      key: Key('documento-${item.tipo.codigo}'),
      child: Semantics(
        container: true,
        label: l10n.documentosSemantica(nombre, etapa),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  // El cambio de estado se anima corto; con «reducir
                  // movimiento» es instantáneo.
                  child: AnimatedSwitcher(
                    duration: MovimientoCampo.duracion(
                      context,
                      MovimientoCampo.rapida,
                    ),
                    switchInCurve: MovimientoCampo.entrada,
                    child: item.etapa == EtapaDocumento.subiendo
                        ? const SizedBox.square(
                            key: ValueKey('subiendo'),
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Icon(
                            item.etapa.icono,
                            key: ValueKey(item.etapa),
                            color: color,
                          ),
                  ),
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: texto.titleMedium),
                        Text(
                          etapa,
                          style: texto.bodyMedium?.copyWith(color: color),
                        ),
                        if (detalle != null)
                          Text(
                            detalle,
                            style: texto.bodyMedium?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (item.puedeCapturar) ...[
              const SizedBox(height: EspaciadoCampo.m),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('documento-${item.tipo.codigo}-accion'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  onPressed: () => item.etapa == EtapaDocumento.errorEnvio
                      ? context.read<DocumentosCubit>().reintentar(item.tipo)
                      : _capturar(context),
                  icon: Icon(
                    item.etapa == EtapaDocumento.errorEnvio
                        ? Icons.refresh_rounded
                        : Icons.photo_camera_outlined,
                  ),
                  label: Text(etiquetaBoton),
                ),
              ),
              if (item.etapa == EtapaDocumento.errorEnvio)
                TextButton(
                  key: Key('documento-${item.tipo.codigo}-retomar'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  onPressed: () {
                    context.read<DocumentosCubit>().descartar(item.tipo);
                    _capturar(context);
                  },
                  child: Text(l10n.documentosVolverATomar),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
