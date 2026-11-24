import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../dominio/falla.dart';
import '../../ui/formato_marketplace.dart';
import '../precio_referencia.dart';

/// Los valores de `tipo_aplicacion` del contrato para un texto de producto o
/// de aplicación escrito por una persona. Sin coincidencia, `otro`.
String tipoAplicacionDe(String? texto) {
  final t = (texto ?? '').toLowerCase().replaceAll('_', ' ');
  if (t.contains('herbicida') || t.contains('glifosato')) return 'herbicida';
  if (t.contains('insecticida')) return 'insecticida';
  if (t.contains('fungicida')) return 'fungicida';
  if (t.contains('foliar') || t.contains('fertiliz')) {
    return 'fertilizante_foliar';
  }
  if (t.contains('desecante')) return 'desecante';
  return 'otro';
}

/// Sugerencia tocable «Referencia: Bs X por ha» junto al campo de precio.
///
/// Es una guía, no un límite: tocarla solo llama a [alUsar] con el valor; la
/// persona sigue pudiendo escribir el que quiera. Tiene todos sus estados:
/// carga, sin referencia (vacío), sin red, error con reintento y el valor ya
/// usado ([actual] igual a la referencia).
class SugerenciaPrecioReferencia extends StatefulWidget {
  const SugerenciaPrecioReferencia({
    required this.tipoAplicacion,
    required this.alUsar,
    this.zonaId,
    this.macrorregion,
    this.actual,
    super.key,
  });

  final String tipoAplicacion;
  final int? zonaId;
  final String? macrorregion;

  /// Lo que hay escrito en el campo, para marcar la sugerencia como usada.
  final Decimal? actual;
  final ValueChanged<Decimal> alUsar;

  @override
  State<SugerenciaPrecioReferencia> createState() =>
      _SugerenciaPrecioReferenciaState();
}

enum _Fase { cargando, lista, sinReferencia, sinRed, error }

class _SugerenciaPrecioReferenciaState
    extends State<SugerenciaPrecioReferencia> {
  _Fase _fase = _Fase.cargando;
  PrecioReferencia? _referencia;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(SugerenciaPrecioReferencia anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.tipoAplicacion != widget.tipoAplicacion ||
        anterior.zonaId != widget.zonaId ||
        anterior.macrorregion != widget.macrorregion) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() => _fase = _Fase.cargando);
    final repositorio = context.read<ReferenciasRepositorio>();
    _Fase fase;
    PrecioReferencia? r;
    try {
      r = await repositorio.precio(
        tipoAplicacion: widget.tipoAplicacion,
        zonaId: widget.zonaId,
        macrorregion: widget.macrorregion,
      );
      fase = r.precioHa == null ? _Fase.sinReferencia : _Fase.lista;
    } on SinConexion {
      fase = _Fase.sinRed;
    } on Object {
      fase = _Fase.error;
    }
    if (!mounted) return;
    setState(() {
      _referencia = r;
      _fase = fase;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final apagado = texto.bodyMedium?.copyWith(color: paleta.textoSecundario);
    return Align(
      alignment: Alignment.topLeft,
      child: switch (_fase) {
        _Fase.cargando => Semantics(
          label: 'Buscando el precio de referencia',
          child: const EsqueletoCampo(
            key: Key('referencia-carga'),
            alto: ObjetivoTactilCampo.minimo,
            radio: 14,
          ),
        ),
        _Fase.sinReferencia => Padding(
          key: const Key('referencia-vacia'),
          padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.s),
          child: Text(
            'Todavía no hay un precio de referencia para esta aplicación. '
            'Escribe el que te parezca justo.',
            style: apagado,
          ),
        ),
        _Fase.sinRed || _Fase.error => _Reintento(
          mensaje: _fase == _Fase.sinRed
              ? 'Sin conexión para traer el precio de referencia.'
              : 'No pudimos traer el precio de referencia.',
          alReintentar: _cargar,
        ),
        _Fase.lista => _Ficha(
          referencia: _referencia!,
          usada:
              widget.actual != null && widget.actual == _referencia!.precioHa,
          alToque: () => widget.alUsar(_referencia!.precioHa!),
        ),
      },
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.referencia,
    required this.usada,
    required this.alToque,
  });

  final PrecioReferencia referencia;
  final bool usada;
  final VoidCallback alToque;

  String get _origen => switch (referencia.nivel) {
    NivelPrecio.zona => 'Precio habitual en tu zona',
    NivelPrecio.macrorregion => 'Precio habitual en tu región',
    _ => 'Precio habitual en el país',
  };

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final precio = FormatoMarketplace.bs(referencia.precioHa!);
    return Semantics(
      button: true,
      label:
          'Precio de referencia: $precio por hectárea. $_origen. '
          '${usada ? 'Ya lo estás usando.' : 'Toca para usarlo.'}',
      excludeSemantics: true,
      child: Material(
        color: usada
            ? paleta.acentoTexto.withValues(alpha: 0.12)
            : paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioCampo.media),
          side: BorderSide(
            color: usada ? paleta.acentoTexto : paleta.bordeFuerte,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('referencia-usar'),
          onTap: usada ? null : alToque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.s,
              ),
              child: Row(
                children: [
                  Icon(
                    usada ? Icons.check_circle_rounded : Icons.insights_rounded,
                    color: paleta.acentoTexto,
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Referencia: $precio por ha',
                          style: texto.titleSmall,
                        ),
                        Text(
                          usada ? 'Estás usando este precio' : _origen,
                          style: texto.bodySmall?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!usada)
                    Text(
                      'Usar',
                      style: texto.labelLarge?.copyWith(
                        color: paleta.acentoTexto,
                      ),
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

class _Reintento extends StatelessWidget {
  const _Reintento({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Row(
      key: const Key('referencia-reintento'),
      children: [
        Icon(Icons.cloud_off_rounded, size: 20, color: paleta.textoSecundario),
        const SizedBox(width: EspaciadoCampo.s),
        Expanded(
          child: Text(
            mensaje,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(
              ObjetivoTactilCampo.minimo,
              ObjetivoTactilCampo.guantes,
            ),
          ),
          onPressed: alReintentar,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
