import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../ui/marketplace_ui.dart';

/// Los documentos del proveedor (licencia, matrícula, seguro y certificado)
/// con su estado y vigencia. Sale del perfil: allí solo queda el enlace. Si
/// alguno pide una acción, el aviso va arriba.
class DocumentosPantalla extends StatelessWidget {
  const DocumentosPantalla({required this.proveedor, super.key});

  final Proveedor proveedor;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final conAccion = proveedor.documentosConAccion;
    return Scaffold(
      appBar: AppBar(title: Text(t.perfilProveedorDocumentos)),
      body: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: EntradaCampo.escalonar([
          if (conAccion.isNotEmpty && proveedor.aprobacion.habilitado) ...[
            AvisoMarketplace(
              key: const Key('perfil-documentos-accion'),
              tono: TonoAviso.alerta,
              mensaje: conAccion.length == 1
                  ? t.perfilProveedorDocumentoAtencion(conAccion.first.nombre)
                  : t.perfilProveedorDocumentosAtencion(conAccion.length),
            ),
            const SizedBox(height: EspaciadoCampo.m),
          ],
          if (proveedor.documentos.isEmpty)
            Text(t.perfilProveedorDocumentosVacio, style: texto.bodyMedium),
          for (final doc in proveedor.documentos) ...[
            FilaDocumentoProveedor(documento: doc),
            const SizedBox(height: EspaciadoCampo.m),
          ],
        ]),
      ),
    );
  }
}

class FilaDocumentoProveedor extends StatelessWidget {
  const FilaDocumentoProveedor({required this.documento, super.key});

  final DocumentoProveedor documento;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final (tono, icono) = switch (documento.estado) {
      EstadoDocumento.vigente => (TonoEstado.exito, Icons.verified_rounded),
      EstadoDocumento.porVencer => (TonoEstado.alerta, Icons.schedule_rounded),
      EstadoDocumento.enRevision => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
      ),
      EstadoDocumento.rechazado => (TonoEstado.error, Icons.cancel_outlined),
      EstadoDocumento.vencido => (TonoEstado.error, Icons.event_busy_outlined),
    };
    final vence = documento.vence;
    final motivo = documento.motivoRechazo;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(documento.nombre, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.s),
          Wrap(
            spacing: EspaciadoCampo.m,
            runSpacing: EspaciadoCampo.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipEstadoMarketplace(
                etiqueta: documento.estado.etiqueta,
                tono: tono,
                icono: icono,
              ),
              if (vence != null)
                Text(
                  documento.estado == EstadoDocumento.vencido
                      ? l10n.proveedorPerfilVencio(
                          FormatoMarketplace.fechaLarga(vence),
                        )
                      : l10n.proveedorPerfilVence(
                          FormatoMarketplace.fechaLarga(vence),
                        ),
                  style: texto.bodyMedium,
                ),
            ],
          ),
          if (motivo != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text(l10n.proveedorPerfilMotivo(motivo), style: texto.bodyMedium),
          ],
        ],
      ),
    );
  }
}
