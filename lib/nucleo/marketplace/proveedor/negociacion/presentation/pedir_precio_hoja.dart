import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/formato_marketplace.dart';

/// Lo que el piloto escribió al contraofertar.
class PrecioPropuesto {
  const PrecioPropuesto(this.precioHa, this.nota);

  final Decimal precioHa;
  final String? nota;
}

/// Lee un precio escrito por una persona («125», «125,50», «125.5»).
Decimal? leerPrecio(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  final valor = Decimal.tryParse(limpio);
  if (valor == null || valor <= Decimal.zero) return null;
  return valor;
}

/// Hoja para escribir el precio por hectárea de una contraoferta, con el
/// monto estimado a la vista antes de enviar.
Future<PrecioPropuesto?> pedirPrecio(
  BuildContext context, {
  required String titulo,
  required Decimal hectareas,
  required Decimal precioReferencia,
  required String etiquetaReferencia,
  String? textoBoton,
}) {
  return showModalBottomSheet<PrecioPropuesto>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaPrecio(
      titulo: titulo,
      hectareas: hectareas,
      precioReferencia: precioReferencia,
      etiquetaReferencia: etiquetaReferencia,
      textoBoton:
          textoBoton ??
          AppLocalizations.of(context).proveedorNegociacionEnviarContraoferta,
    ),
  );
}

class _HojaPrecio extends StatefulWidget {
  const _HojaPrecio({
    required this.titulo,
    required this.hectareas,
    required this.precioReferencia,
    required this.etiquetaReferencia,
    required this.textoBoton,
  });

  final String titulo;
  final Decimal hectareas;
  final Decimal precioReferencia;
  final String etiquetaReferencia;
  final String textoBoton;

  @override
  State<_HojaPrecio> createState() => _HojaPrecioState();
}

class _HojaPrecioState extends State<_HojaPrecio> {
  final _precio = TextEditingController();
  final _nota = TextEditingController();
  final _clave = GlobalKey<FormState>();

  @override
  void dispose() {
    _precio.dispose();
    _nota.dispose();
    super.dispose();
  }

  Decimal? get _valor => leerPrecio(_precio.text);

  String? _validar(String? texto) {
    final l10n = AppLocalizations.of(context);
    final valor = leerPrecio(texto ?? '');
    if (valor == null) return l10n.proveedorNegociacionEscribePrecioMayorCero;
    if (valor == widget.precioReferencia) {
      return l10n.proveedorNegociacionMismoPrecioCambialoAcepta;
    }
    return null;
  }

  void _enviar() {
    if (!(_clave.currentState?.validate() ?? false)) return;
    final nota = _nota.text.trim();
    Navigator.pop(
      context,
      PrecioPropuesto(_valor!, nota.isEmpty ? null : nota),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final total = _valor == null ? null : widget.hectareas * _valor!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          0,
          EspaciadoCampo.l,
          EspaciadoCampo.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _clave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.titulo, style: texto.titleLarge),
              const SizedBox(height: EspaciadoCampo.xs),
              Text(
                l10n.proveedorNegociacionPor2(
                  widget.etiquetaReferencia,
                  FormatoMarketplace.bs(widget.precioReferencia),
                ),
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              CampoFormularioMarketplace(
                etiqueta: l10n.proveedorNegociacionPrecioPorHectarea,
                controller: _precio,
                validator: _validar,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Semantics(
                liveRegion: true,
                child: Text(
                  total == null
                      ? l10n.proveedorNegociacionTotalApareceCuandoEscribes
                      : '${FormatoMarketplace.hectareas(widget.hectareas)} × '
                            '${FormatoMarketplace.bs(_valor!)} = '
                            '${FormatoMarketplace.bs(total)}',
                  style: texto.bodyLarge,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              CampoFormularioMarketplace(
                etiqueta: l10n.proveedorNegociacionMensajeParaClienteOpcional,
                controller: _nota,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              BotonPrincipalMarketplace(
                texto: widget.textoBoton,
                onPressed: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
