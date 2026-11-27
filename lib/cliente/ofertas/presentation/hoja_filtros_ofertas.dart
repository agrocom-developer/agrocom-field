import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/proveedor.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/boton_principal.dart';
import '../domain/comparador_ofertas.dart';
import 'textos_orden.dart';

/// Abre la hoja del comparador: el orden y los filtros de las ofertas.
/// Devuelve los nuevos `FiltrosOfertas`, o `null` si se cierra sin aplicar.
Future<FiltrosOfertas?> mostrarHojaFiltrosOfertas(
  BuildContext context, {
  required FiltrosOfertas inicial,
}) => showModalBottomSheet<FiltrosOfertas>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => HojaFiltrosOfertas(inicial: inicial),
);

class HojaFiltrosOfertas extends StatefulWidget {
  const HojaFiltrosOfertas({required this.inicial, super.key});

  final FiltrosOfertas inicial;

  @override
  State<HojaFiltrosOfertas> createState() => _HojaFiltrosOfertasState();
}

class _HojaFiltrosOfertasState extends State<HojaFiltrosOfertas> {
  static final _calificaciones = [
    null,
    Decimal.fromInt(3),
    Decimal.fromInt(4),
    Decimal.parse('4.5'),
  ];

  late OrdenOfertas _orden = widget.inicial.orden;
  late Decimal? _calificacion = widget.inicial.calificacionMin;
  late TipoProveedor? _tipo = widget.inicial.tipoProveedor;
  late final _precioMin = _controlador(widget.inicial.precioHaMin);
  late final _precioMax = _controlador(widget.inicial.precioHaMax);
  late final _montoMax = _controlador(widget.inicial.montoMax);
  late final _tanqueMin = _controlador(widget.inicial.capacidadTanqueMin);
  bool _intentado = false;

  TextEditingController _controlador(Decimal? valor) =>
      TextEditingController(text: valor == null ? '' : '$valor');

  @override
  void dispose() {
    _precioMin.dispose();
    _precioMax.dispose();
    _montoMax.dispose();
    _tanqueMin.dispose();
    super.dispose();
  }

  bool get _rangoValido {
    final min = LecturaFiltro.leer(_precioMin.text);
    final max = LecturaFiltro.leer(_precioMax.text);
    return min == null || max == null || max >= min;
  }

  bool get _valido =>
      LecturaFiltro.esValido(_precioMin.text) &&
      LecturaFiltro.esValido(_precioMax.text) &&
      LecturaFiltro.esValido(_montoMax.text) &&
      LecturaFiltro.esValido(_tanqueMin.text) &&
      _rangoValido;

  void _aplicar() {
    setState(() => _intentado = true);
    if (!_valido) return;
    Navigator.of(context).pop(
      FiltrosOfertas(
        orden: _orden,
        precioHaMin: LecturaFiltro.leer(_precioMin.text),
        precioHaMax: LecturaFiltro.leer(_precioMax.text),
        montoMax: LecturaFiltro.leer(_montoMax.text),
        calificacionMin: _calificacion,
        tipoProveedor: _tipo,
        capacidadTanqueMin: LecturaFiltro.leer(_tanqueMin.text),
      ),
    );
  }

  void _quitar() => setState(() {
    _precioMin.clear();
    _precioMax.clear();
    _montoMax.clear();
    _tanqueMin.clear();
    _calificacion = null;
    _tipo = null;
    _intentado = false;
  });

  Widget _numero(String clave, String etiqueta, TextEditingController c) {
    final l10n = AppLocalizations.of(context);
    final error = _intentado && !LecturaFiltro.esValido(c.text)
        ? l10n.ofertasFiltrosNumeroInvalido
        : null;
    return TextField(
      key: ValueKey(clave),
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: InputDecoration(labelText: etiqueta, errorText: error),
    );
  }

  Widget _grupo(String titulo, Widget hijo) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(titulo, style: Theme.of(context).textTheme.titleSmall),
      ),
      const SizedBox(height: EspaciadoCampo.s),
      hijo,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final rangoMal = _intentado && !_rangoValido;
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
              child: Text(l10n.ofertasFiltrosTitulo, style: texto.titleLarge),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _grupo(
              l10n.ofertasFiltrosOrdenarPor,
              Wrap(
                spacing: EspaciadoCampo.s,
                runSpacing: EspaciadoCampo.s,
                children: [
                  for (final o in OrdenOfertas.values)
                    ChoiceChip(
                      key: ValueKey('orden-${o.codigo}'),
                      label: Text(o.etiquetaL10n(l10n)),
                      selected: _orden == o,
                      onSelected: (_) => setState(() => _orden = o),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Row(
              children: [
                Expanded(
                  child: _numero(
                    'filtro-precio-min',
                    l10n.ofertasFiltroPrecioMin,
                    _precioMin,
                  ),
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: _numero(
                    'filtro-precio-max',
                    l10n.ofertasFiltroPrecioMax,
                    _precioMax,
                  ),
                ),
              ],
            ),
            if (rangoMal)
              Padding(
                padding: const EdgeInsets.only(top: EspaciadoCampo.xs),
                child: Text(
                  l10n.ofertasFiltrosRangoInvalido,
                  style: texto.bodySmall?.copyWith(color: paleta.error),
                ),
              ),
            const SizedBox(height: EspaciadoCampo.m),
            _numero('filtro-total-max', l10n.ofertasFiltroTotalMax, _montoMax),
            const SizedBox(height: EspaciadoCampo.m),
            _numero(
              'filtro-tanque-min',
              l10n.ofertasFiltroTanqueMin,
              _tanqueMin,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _grupo(
              l10n.ofertasFiltroCalificacionMin,
              Wrap(
                spacing: EspaciadoCampo.s,
                runSpacing: EspaciadoCampo.s,
                children: [
                  for (final c in _calificaciones)
                    ChoiceChip(
                      key: ValueKey('calificacion-${c ?? 'cualquiera'}'),
                      label: Text(
                        c == null
                            ? l10n.ofertasFiltroCalificacionCualquiera
                            : l10n.ofertasFiltroCalificacionDesde(
                                '$c'.replaceAll('.', ','),
                              ),
                      ),
                      selected: _calificacion == c,
                      onSelected: (_) => setState(() => _calificacion = c),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            _grupo(
              l10n.ofertasFiltroTipo,
              Wrap(
                spacing: EspaciadoCampo.s,
                runSpacing: EspaciadoCampo.s,
                children: [
                  ChoiceChip(
                    key: const ValueKey('tipo-todos'),
                    label: Text(l10n.ofertasFiltroTipoTodos),
                    selected: _tipo == null,
                    onSelected: (_) => setState(() => _tipo = null),
                  ),
                  for (final t in TipoProveedor.values)
                    ChoiceChip(
                      key: ValueKey('tipo-${t.codigo}'),
                      label: Text(switch (t) {
                        TipoProveedor.propioAgrocom =>
                          l10n.ofertasFiltroTipoPropio,
                        TipoProveedor.independiente =>
                          l10n.ofertasFiltroTipoIndependiente,
                        TipoProveedor.duenoDeDrones =>
                          l10n.ofertasFiltroTipoTercero,
                      }),
                      selected: _tipo == t,
                      onSelected: (_) => setState(() => _tipo = t),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            BotonPrincipal(
              key: const ValueKey('aplicar-filtros'),
              texto: l10n.ofertasFiltrosAplicar,
              onPressed: _aplicar,
            ),
            TextButton(
              key: const ValueKey('quitar-filtros'),
              onPressed: _quitar,
              child: Text(l10n.ofertasFiltrosQuitar),
            ),
          ],
        ),
      ),
    );
  }
}
