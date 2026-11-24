import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../solicitar/domain/reglas_solicitud.dart';
import 'boton_principal.dart';

/// Precio por hectárea que el cliente escribió en la hoja, con una nota
/// opcional para el piloto.
typedef PrecioEscrito = ({Decimal precio, String? nota});

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
  bool conNota = false,
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
    conNota: conNota,
  ),
);

class HojaPrecio extends StatefulWidget {
  const HojaPrecio({
    required this.titulo,
    required this.textoAccion,
    required this.hectareas,
    this.apoyo,
    this.inicial,
    this.conNota = false,
    super.key,
  });

  final String titulo;
  final String textoAccion;
  final Decimal hectareas;
  final String? apoyo;
  final Decimal? inicial;
  final bool conNota;

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
  final _nota = TextEditingController();

  @override
  void dispose() {
    _precio.dispose();
    _nota.dispose();
    super.dispose();
  }

  Decimal? get _valor => ReglasSolicitud.errorDePrecio(_precio.text) == null
      ? ReglasSolicitud.parsearPrecio(_precio.text)
      : null;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final valor = _valor;
    final error = _precio.text.trim().isEmpty
        ? null
        : ReglasSolicitud.errorDePrecio(_precio.text);
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
                labelText: 'Precio por hectárea',
                suffixText: 'Bs/ha',
                errorText: error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Semantics(
              liveRegion: true,
              child: Text(
                valor == null
                    ? 'Escribe un precio para ver el total.'
                    : 'Total estimado: '
                          '${FormatoMarketplace.bs(widget.hectareas * valor)} '
                          'por ${FormatoMarketplace.hectareas(widget.hectareas)}',
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ),
            if (widget.conNota) ...[
              const SizedBox(height: EspaciadoCampo.l),
              TextField(
                key: const ValueKey('hoja-nota'),
                controller: _nota,
                maxLength: 200,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mensaje para el piloto (opcional)',
                ),
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            BotonPrincipal(
              key: const ValueKey('hoja-precio-enviar'),
              texto: widget.textoAccion,
              onPressed: valor == null
                  ? null
                  : () => Navigator.of(context).pop((
                      precio: valor,
                      nota: _nota.text.trim().isEmpty
                          ? null
                          : _nota.text.trim(),
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
