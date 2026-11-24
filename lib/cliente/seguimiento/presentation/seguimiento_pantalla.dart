import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/barra_avance.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../comun/presentation/boton_secundario.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../comun/presentation/fila_dato.dart';
import '../../comun/presentation/linea_tiempo_servicio.dart';
import '../../comun/presentation/tarjeta_proveedor.dart';
import '../../conformidad/presentation/acta_pantalla.dart';
import '../domain/seguimiento_repositorio.dart';
import 'seguimiento_cubit.dart';

/// Mapa a pantalla completa con una hoja inferior arrastrable (peek 30 %,
/// expandida 70 %): avance en hectáreas, ETA, línea de tiempo y proveedor
/// (sistema visual, §9).
class SeguimientoPantalla extends StatelessWidget {
  const SeguimientoPantalla({required this.servicio, super.key});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SeguimientoCubit(context.read<SeguimientoRepositorio>(), servicio.id),
      child: _Vista(servicio: servicio),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.servicio});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: paleta.fondo.withValues(alpha: 0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.xs),
          child: IconButton.filled(
            tooltip: 'Volver',
            style: IconButton.styleFrom(
              backgroundColor: paleta.superficie,
              foregroundColor: paleta.texto,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: BlocBuilder<SeguimientoCubit, SeguimientoEstado>(
        builder: (context, estado) {
          if (estado.fase == FaseSeguimiento.error) {
            return SafeArea(
              child: EstadoFalla(
                sinConexion: estado.sinConexion,
                queNoCargo: 'el seguimiento en vivo',
                alReintentar: context.read<SeguimientoCubit>().reintentar,
              ),
            );
          }
          final f = estado.fotograma;
          return Stack(
            children: [
              Positioned.fill(
                child: _MapaVivo(servicio: servicio, fotograma: f),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.36,
                minChildSize: 0.24,
                maxChildSize: 0.72,
                snap: true,
                builder: (context, controlador) => _Hoja(
                  controlador: controlador,
                  servicio: servicio,
                  estado: estado,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mapa del lote con el dron. Entre dos fotogramas el marcador se desliza de
/// la posición anterior a la nueva; con «reducir movimiento» salta.
class _MapaVivo extends StatefulWidget {
  const _MapaVivo({required this.servicio, required this.fotograma});

  final Servicio servicio;
  final SeguimientoVivo? fotograma;

  @override
  State<_MapaVivo> createState() => _MapaVivoState();
}

class _MapaVivoState extends State<_MapaVivo>
    with SingleTickerProviderStateMixin {
  /// Lo que tarda el marcador en llegar a la posición nueva. Es un
  /// desplazamiento continuo sobre el mapa, no una transición de interfaz.
  static const _deslizamiento = Duration(milliseconds: 1200);

  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: _deslizamiento,
  )..addListener(() => setState(() {}));

  GeoPunto? _desde;
  GeoPunto? _hasta;

  @override
  void initState() {
    super.initState();
    _hasta = widget.fotograma?.posicionDron;
    _controlador.value = 1;
  }

  @override
  void didUpdateWidget(_MapaVivo anterior) {
    super.didUpdateWidget(anterior);
    final nueva = widget.fotograma?.posicionDron;
    if (nueva == null || nueva == _hasta) return;
    final previa = _posicion;
    _hasta = nueva;
    if (previa == null || MovimientoCampo.reducido(context)) {
      _desde = null;
      _controlador.value = 1;
    } else {
      _desde = previa;
      _controlador.forward(from: 0);
    }
  }

  /// Posición que se dibuja en este cuadro.
  GeoPunto? get _posicion {
    final hasta = _hasta;
    final desde = _desde;
    if (hasta == null || desde == null) return hasta;
    final t = _controlador.value;
    return GeoPunto(
      desde.latitud + (hasta.latitud - desde.latitud) * t,
      desde.longitud + (hasta.longitud - desde.longitud) * t,
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posicion = _posicion;
    final trazado = widget.fotograma?.trazado ?? const <GeoPunto>[];
    return MapaLote(
      lotes: [widget.servicio.lote],
      seleccionado: widget.servicio.lote,
      posicionDron: posicion,
      // La estela termina donde está dibujado el dron, no donde va a llegar.
      trazado: posicion == null || trazado.length < 2
          ? trazado
          : [...trazado.take(trazado.length - 1), posicion],
      relleno: const EdgeInsets.fromLTRB(40, 120, 40, 320),
    );
  }
}

class _Hoja extends StatelessWidget {
  const _Hoja({
    required this.controlador,
    required this.servicio,
    required this.estado,
  });

  final ScrollController controlador;
  final Servicio servicio;
  final SeguimientoEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final f = estado.fotograma;
    return Container(
      decoration: BoxDecoration(
        color: paleta.superficieElevada,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EspaciadoCampo.xl + EspaciadoCampo.xs),
        ),
        border: Border.all(color: paleta.borde),
        boxShadow: ElevacionCampo.sombras(paleta, 3),
      ),
      child: ListView(
        controller: controlador,
        padding: const EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          EspaciadoCampo.s,
          EspaciadoCampo.l,
          EspaciadoCampo.xxl,
        ),
        children: [
          Center(
            child: Container(
              width: EspaciadoCampo.xxxl,
              height: EspaciadoCampo.xs,
              decoration: BoxDecoration(
                color: paleta.bordeFuerte,
                borderRadius: BorderRadius.circular(EspaciadoCampo.xs),
              ),
            ),
          ),
          const SizedBox(height: EspaciadoCampo.l),
          if (f == null) const _HojaCargando() else ..._contenido(context, f),
        ],
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, SeguimientoVivo f) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final terminado = estado.terminado;
    final proveedor = servicio.proveedor;
    final cubiertas = FormatoMarketplace.hectareas(f.hectareasCubiertas);
    final declaradas = FormatoMarketplace.hectareas(f.hectareasDeclaradas);
    final eta = f.etaMinutos;
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: InsigniaEstadoServicio(f.estado),
      ),
      const SizedBox(height: EspaciadoCampo.m),
      Semantics(
        liveRegion: true,
        label: '$cubiertas fumigadas de $declaradas',
        child: ExcludeSemantics(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: EspaciadoCampo.s,
            children: [
              Text(
                cubiertas,
                key: const ValueKey('hectareas-cubiertas'),
                style: texto.displaySmall?.copyWith(
                  color: paleta.acentoTexto,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: EspaciadoCampo.xs),
                child: Text(
                  'de $declaradas',
                  style: texto.titleMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: EspaciadoCampo.m),
      BarraAvance(valor: f.progreso, etiqueta: '$cubiertas de $declaradas'),
      const SizedBox(height: EspaciadoCampo.m),
      Row(
        children: [
          Icon(
            terminado ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 20,
            color: paleta.textoSecundario,
          ),
          const SizedBox(width: EspaciadoCampo.s),
          Expanded(
            child: Text(
              terminado
                  ? 'El dron terminó de aplicar sobre ${servicio.lote.nombre}.'
                  : eta == null
                  ? 'Calculando el tiempo restante'
                  : 'Faltan ${FormatoMarketplace.duracionMinutos(eta)}',
              style: texto.bodyLarge,
            ),
          ),
        ],
      ),
      if (estado.fase == FaseSeguimiento.sinSenal) ...[
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          liveRegion: true,
          child: AvisoMarketplace(
            tono: TonoAviso.alerta,
            icono: Icons.wifi_off_rounded,
            mensaje: estado.sinConexion
                ? 'Sin conexión. Ves la última posición que recibimos.'
                : 'Se cortó el seguimiento. Ves la última posición que '
                      'recibimos.',
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonSecundario(
            texto: 'Reintentar',
            icono: Icons.refresh_rounded,
            onPressed: context.read<SeguimientoCubit>().reintentar,
          ),
        ),
      ],
      if (terminado) ...[
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipal(
          texto: 'Ver evidencias y acta',
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ActaPantalla(
                servicio: servicio.copiarCon(
                  estado: EstadoServicio.completado,
                  hectareasCubiertas: f.hectareasCubiertas,
                ),
              ),
            ),
          ),
        ),
      ],
      const TituloSeccion('Qué pasa ahora'),
      LineaTiempoServicio(
        hitos: lineaDeTiempo(
          servicio,
          estadoVivo: f.estado,
          // Recién terminado, lo que sigue es la conformidad del cliente.
          faltaConformidad: true,
        ).where((h) => h.etapa != EtapaServicio.solicitado).toList(),
      ),
      if (proveedor != null) ...[
        const TituloSeccion('Quién fumiga'),
        TarjetaProveedor(proveedor: proveedor, dron: servicio.dron),
      ],
      const TituloSeccion('Aplicación'),
      SuperficieMarketplace(
        child: ListaDatos([
          FilaDato('Producto', servicio.producto),
          FilaDato(
            'Caldo total',
            FormatoMarketplace.litros(servicio.litrosTotales),
          ),
        ]),
      ),
    ];
  }
}

class _HojaCargando extends StatelessWidget {
  const _HojaCargando();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EsqueletoCampo(alto: EspaciadoCampo.xl, ancho: 140),
      SizedBox(height: EspaciadoCampo.m),
      EsqueletoCampo(alto: EspaciadoCampo.xxxl, ancho: 200),
      SizedBox(height: EspaciadoCampo.m),
      EsqueletoCampo(alto: EspaciadoCampo.s),
      SizedBox(height: EspaciadoCampo.xl),
      EsqueletoCampo(alto: 120),
    ],
  );
}
