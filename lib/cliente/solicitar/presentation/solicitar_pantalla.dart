import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/solicitud_repositorio.dart';

/// Solicitar un servicio, un paso por pantalla: dónde (lote en el mapa), qué
/// (producto y dosis) y cuándo (fecha y resumen con precio estimado). La
/// clave de idempotencia nace al abrir el formulario y se reutiliza en cada
/// reintento: un doble toque no crea dos servicios (ADR 0009).
class SolicitarPantalla extends StatefulWidget {
  const SolicitarPantalla({required this.alSolicitado, super.key});

  /// Se llama con el servicio creado, para que el contenedor navegue.
  final ValueChanged<Servicio> alSolicitado;

  @override
  State<SolicitarPantalla> createState() => _SolicitarPantallaState();
}

class _SolicitarPantallaState extends State<SolicitarPantalla> {
  final _clave = const Uuid().v4();
  late final Future<(List<Lote>, List<String>)> _datos = _cargar();

  int _paso = 0;
  Lote? _lote;
  String? _producto;
  Decimal _dosis = Decimal.parse('1.0');
  DateTime? _fecha;
  EstimacionServicio? _estimacion;
  bool _enviando = false;
  String? _error;

  static const _pasos = ['Dónde', 'Qué', 'Cuándo'];

  Future<(List<Lote>, List<String>)> _cargar() async {
    final repo = context.read<SolicitudRepositorio>();
    return (await repo.lotesDelCliente(), await repo.productosSugeridos());
  }

  bool get _puedeAvanzar => switch (_paso) {
    0 => _lote != null,
    1 => _producto != null,
    _ => _fecha != null,
  };

  Future<void> _avanzar() async {
    if (_paso < 2) {
      if (_paso == 1) {
        final repo = context.read<SolicitudRepositorio>();
        final e = await repo.estimar(
          lote: _lote!,
          dosisLitrosPorHectarea: _dosis,
        );
        if (!mounted) return;
        setState(() => _estimacion = e);
      }
      setState(() => _paso++);
      return;
    }
    await _enviar();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final servicio = await context.read<SolicitudRepositorio>().solicitar(
        SolicitudServicio(
          lote: _lote!,
          producto: _producto!,
          dosisLitrosPorHectarea: _dosis,
          fechaDeseada: _fecha!,
          claveIdempotencia: _clave,
        ),
      );
      HapticaCampo.confirmacion();
      if (mounted) widget.alSolicitado(servicio);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error =
            'No pudimos enviar la solicitud. Tus datos siguen acá; probá de '
            'nuevo cuando tengas conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_paso > 0 && !_enviando)
                    IconButton(
                      tooltip: 'Paso anterior',
                      onPressed: () => setState(() => _paso--),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      'Solicitar servicio',
                      style: texto.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Paso ${_paso + 1} de 3 · ${_pasos[_paso]}',
                style: texto.labelLarge?.copyWith(
                  color: context.paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_paso + 1) / 3,
                  minHeight: 6,
                  backgroundColor: context.paleta.borde,
                  color: context.paleta.acentoTexto,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FuturoEstable<(List<Lote>, List<String>)>(
            crear: () => _datos,
            builder: (context, snap) {
              final d = snap.data;
              if (d == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      EsqueletoCampo(alto: 240),
                      SizedBox(height: 12),
                      EsqueletoCampo(alto: 72),
                    ],
                  ),
                );
              }
              return switch (_paso) {
                0 => _PasoDonde(
                  lotes: d.$1,
                  seleccionado: _lote,
                  alElegir: (l) => setState(() => _lote = l),
                ),
                1 => _PasoQue(
                  productos: d.$2,
                  producto: _producto,
                  dosis: _dosis,
                  lote: _lote!,
                  alProducto: (p) => setState(() => _producto = p),
                  alDosis: (v) => setState(() => _dosis = v),
                ),
                _ => _PasoCuando(
                  fecha: _fecha,
                  alElegir: (f) => setState(() => _fecha = f),
                  lote: _lote!,
                  producto: _producto!,
                  dosis: _dosis,
                  estimacion: _estimacion,
                  error: _error,
                ),
              };
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: BotonPrimarioCampo(
            texto: _paso < 2 ? 'Continuar' : 'Solicitar servicio',
            cargando: _enviando,
            onPressed: _puedeAvanzar && !_enviando ? _avanzar : null,
          ),
        ),
      ],
    );
  }
}

class _PasoDonde extends StatelessWidget {
  const _PasoDonde({
    required this.lotes,
    required this.seleccionado,
    required this.alElegir,
  });

  final List<Lote> lotes;
  final Lote? seleccionado;
  final ValueChanged<Lote> alElegir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text('¿Qué lote querés fumigar?', style: texto.titleLarge),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 240,
            child: MapaLote(
              lotes: lotes,
              seleccionado: seleccionado,
              alSeleccionar: alElegir,
              relleno: const EdgeInsets.all(28),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final l in lotes) ...[
          _TarjetaLote(
            lote: l,
            elegido: l.id == seleccionado?.id,
            alTocar: () {
              HapticaCampo.seleccion();
              alElegir(l);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TarjetaLote extends StatelessWidget {
  const _TarjetaLote({
    required this.lote,
    required this.elegido,
    required this.alTocar,
  });

  final Lote lote;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      selected: elegido,
      button: true,
      child: SuperficieMarketplace(
        resaltada: elegido,
        onTap: alTocar,
        child: Row(
          children: [
            Icon(
              elegido
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: elegido ? paleta.acentoTexto : paleta.bordeFuerte,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lote.nombre, style: texto.titleMedium),
                  Text(
                    '${lote.zona} · ${lote.cultivo}',
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              FormatoMarketplace.hectareas(lote.hectareas),
              style: texto.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoQue extends StatelessWidget {
  const _PasoQue({
    required this.productos,
    required this.producto,
    required this.dosis,
    required this.lote,
    required this.alProducto,
    required this.alDosis,
  });

  final List<String> productos;
  final String? producto;
  final Decimal dosis;
  final Lote lote;
  final ValueChanged<String> alProducto;
  final ValueChanged<Decimal> alDosis;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final paso = Decimal.parse('0.1');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text('¿Qué vas a aplicar?', style: texto.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in productos)
              ChoiceChip(
                label: Text(p),
                selected: p == producto,
                onSelected: (_) {
                  HapticaCampo.seleccion();
                  alProducto(p);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Dosis por hectárea', style: texto.titleMedium),
        const SizedBox(height: 8),
        SuperficieMarketplace(
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Bajar la dosis',
                onPressed: dosis > paso ? () => alDosis(dosis - paso) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '${FormatoMarketplace.numero(dosis, decimales: 1)} L/ha',
                  textAlign: TextAlign.center,
                  style: texto.headlineSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Subir la dosis',
                onPressed: () => alDosis(dosis + paso),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Caldo total: ${FormatoMarketplace.litros(lote.hectareas * dosis)} '
          'para ${FormatoMarketplace.hectareas(lote.hectareas)}',
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
      ],
    );
  }
}

class _PasoCuando extends StatelessWidget {
  const _PasoCuando({
    required this.fecha,
    required this.alElegir,
    required this.lote,
    required this.producto,
    required this.dosis,
    required this.estimacion,
    required this.error,
  });

  final DateTime? fecha;
  final ValueChanged<DateTime> alElegir;
  final Lote lote;
  final String producto;
  final Decimal dosis;
  final EstimacionServicio? estimacion;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final hoy = DateTime.now();
    final dias = [
      for (var i = 1; i <= 7; i++)
        DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: i)),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text('¿Cuándo lo necesitás?', style: texto.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in dias)
              ChoiceChip(
                label: Text(FormatoMarketplace.fechaCorta(d)),
                selected: fecha == d,
                onSelected: (_) {
                  HapticaCampo.seleccion();
                  alElegir(d);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Resumen', style: texto.titleMedium),
        const SizedBox(height: 8),
        SuperficieMarketplace(
          child: Column(
            children: [
              _FilaResumen('Lote', '${lote.nombre} · ${lote.zona}'),
              _FilaResumen(
                'Superficie',
                FormatoMarketplace.hectareas(lote.hectareas),
              ),
              _FilaResumen('Producto', producto),
              _FilaResumen(
                'Dosis',
                '${FormatoMarketplace.numero(dosis, decimales: 1)} L/ha',
              ),
              if (estimacion != null) ...[
                const Divider(height: 24),
                _FilaResumen(
                  'Precio estimado',
                  FormatoMarketplace.bs(estimacion!.precio),
                  destacado: true,
                ),
                _FilaResumen(
                  'Tarifa',
                  '${FormatoMarketplace.bs(estimacion!.precioPorHectarea)}/ha',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'El pago se acuerda con el proveedor: la app no cobra.',
          style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          AvisoMarketplace(mensaje: error!, tono: TonoAviso.error),
        ],
      ],
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.valor, {this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: texto.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? texto.titleLarge : texto.bodyMedium)
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
