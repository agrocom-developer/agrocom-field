import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/precio/justificacion_precio.dart';
import '../../../nucleo/marketplace/precio/presentation/campo_justificacion_precio.dart';
import '../../../nucleo/marketplace/precio/presentation/total_solo_lectura.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../solicitar/domain/reglas_solicitud.dart';
import '../../solicitar/presentation/textos_errores_solicitud.dart';
import 'boton_principal.dart';

/// Precio por hectárea que el cliente escribió en la hoja, con la
/// justificación opcional que verá el piloto. El total no forma parte de lo
/// escrito: se calcula y se muestra de solo lectura.
typedef PrecioEscrito = ({Decimal precio, String? justificacion});

/// Abre una hoja para escribir un precio por hectárea (cambiar el precio de
/// la solicitud o contraofertar). Devuelve `null` si se cierra sin enviar. El
/// total se calcula sobre [hectareas] mientras se escribe, para que el
/// cliente vea cuánto pagaría.
Future<PrecioEscrito?> mostrarHojaPrecio(
  BuildContext context, {
  required String titulo,
  required String textoAccion,
  required Decimal hectareas,
  String? apoyo,
  Decimal? inicial,
  bool conJustificacion = false,
}) => showModalBottomSheet<PrecioEscrito>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => HojaPrecio(
    titulo: titulo,
    textoAccion: textoAccion,
    hectareas: hectareas,
    apoyo: apoyo,
    inicial: inicial,
    conJustificacion: conJustificacion,
  ),
);

class HojaPrecio extends StatefulWidget {
  const HojaPrecio({
    required this.titulo,
    required this.textoAccion,
    required this.hectareas,
    this.apoyo,
    this.inicial,
    this.conJustificacion = false,
    super.key,
  });

  final String titulo;
  final String textoAccion;
  final Decimal hectareas;
  final String? apoyo;
  final Decimal? inicial;
  final bool conJustificacion;

  @override
  State<HojaPrecio> createState() => _HojaPrecioState();
}

class _HojaPrecioState extends State<HojaPrecio> {
  late final _precio = TextEditingController(
    text: widget.inicial == null
        ? ''
        : FormatoMarketplace.numero(
            widget.inicial!,
            decimales: widget.inicial!.scale > 0 ? 2 : 0,
          ).replaceAll('.', ''),
  );
  final _justificacion = TextEditingController();

  @override
  void dispose() {
    _precio.dispose();
    _justificacion.dispose();
    super.dispose();
  }

  Decimal? get _valor => ReglasSolicitud.errorDePrecio(_precio.text) == null
      ? ReglasSolicitud.parsearPrecio(_precio.text)
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final valor = _valor;
    final error = _precio.text.trim().isEmpty
        ? null
        : ReglasSolicitud.errorDePrecio(_precio.text)?.texto(l10n);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          EspaciadoCampo.xl,
          0,
          EspaciadoCampo.xl,
          EspaciadoCampo.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(widget.titulo, style: texto.titleLarge),
            ),
            if (widget.apoyo != null) ...[
              const SizedBox(height: EspaciadoCampo.xs),
              Text(
                widget.apoyo!,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            TextField(
              key: const ValueKey('hoja-precio'),
              controller: _precio,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                LengthLimitingTextInputFormatter(8),
              ],
              style: texto.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.comunPrecioPorHectarea,
                suffixText: l10n.comunBsHa,
                errorText: error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            TotalSoloLectura(hectareas: widget.hectareas, precioHa: valor),
            if (widget.conJustificacion) ...[
              const SizedBox(height: EspaciadoCampo.l),
              CampoJustificacionPrecio(controller: _justificacion),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            BotonPrincipal(
              key: const ValueKey('hoja-precio-enviar'),
              texto: widget.textoAccion,
              onPressed: valor == null
                  ? null
                  : () => Navigator.of(context).pop((
                      precio: valor,
                      justificacion: JustificacionPrecio.normalizar(
                        _justificacion.text,
                      ),
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
