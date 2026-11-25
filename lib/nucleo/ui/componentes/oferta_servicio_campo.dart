import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Oferta entrante de un servicio (proveedor): qué, dónde, cuánto y cuánto
/// tiempo queda para decidir. Es el momento más sensible del producto, por
/// eso la jerarquía es una sola: el pago y el tiempo arriba, aceptar abajo
/// con el botón más grande de la pantalla.
///
/// No lleva reloj propio: quien la muestra (un bloc) entrega [restante] y
/// [total]; así la cuenta regresiva es testeable y una sola fuente de
/// verdad. El monto llega ya formateado — nunca un `double` (invariante 9).
class OfertaServicioCampo extends StatelessWidget {
  const OfertaServicioCampo({
    required this.titulo,
    required this.detalle,
    required this.distancia,
    required this.monto,
    required this.restante,
    required this.total,
    required this.onAceptar,
    required this.onRechazar,
    this.etiqueta,
    this.mapa,
    this.onDetalle,
    this.respondiendo = false,
    this.sinConexion = false,
    super.key,
  });

  /// "Soja · 42 ha".
  final String titulo;

  /// "Lote 14, a 12 km de tu base".
  final String detalle;

  /// "12 km".
  final String distancia;

  /// Pago estimado ya formateado ("Bs 3.150").
  final String monto;

  final Duration restante;
  final Duration total;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  /// Rótulo en mono sobre el título ("PRIORITARIA · FLOTA DE AGROCOM").
  final String? etiqueta;

  /// Mapa del lote, entre el detalle y los datos. Sin él la tarjeta es solo
  /// texto.
  final Widget? mapa;

  /// Abre el detalle de la oferta.
  final VoidCallback? onDetalle;

  /// La respuesta viaja al servidor: los botones quedan en espera para que
  /// un segundo toque no dispare otra.
  final bool respondiendo;

  /// Sin red no se puede responder (ADR 0009): los botones se apagan y la
  /// tarjeta dice por qué.
  final bool sinConexion;

  /// "00:47" por debajo de la hora; "1 h 05" por encima (ofertas
  /// programadas, con ventana de horas).
  static String textoRestante(Duration restante) {
    final seg = restante.inSeconds.clamp(0, 359999);
    if (seg >= 3600) {
      final minutos = ((seg % 3600) ~/ 60).toString().padLeft(2, '0');
      return '${seg ~/ 3600} h $minutos';
    }
    final m = (seg ~/ 60).toString().padLeft(2, '0');
    final s = (seg % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final progreso = total.inMilliseconds == 0
        ? 0.0
        : (restante.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final porVencer = restante.inSeconds <= 10;
    final colorTiempo = porVencer ? paleta.error : paleta.acentoTexto;
    final bloqueada = respondiendo || sinConexion;
    final tiempo = textoRestante(restante);

    return Semantics(
      container: true,
      label: l10n.componentesOfertaServicioQuedanPara(titulo, monto, tiempo),
      child: Container(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        decoration: BoxDecoration(
          color: ElevacionCampo.superficie(paleta, 2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: paleta.borde),
          boxShadow: ElevacionCampo.sombras(paleta, 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    etiqueta ?? l10n.componentesNuevoServicio,
                    style: texto.labelSmall?.copyWith(
                      color: paleta.acentoTexto,
                    ),
                  ),
                ),
                const SizedBox(width: EspaciadoCampo.m),
                _AnilloTiempo(
                  progreso: progreso,
                  color: colorTiempo,
                  pista: paleta.borde,
                  texto: tiempo,
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text(titulo, style: texto.headlineMedium),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(detalle, style: texto.bodyMedium),
            if (mapa != null) ...[
              const SizedBox(height: EspaciadoCampo.l),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(height: 132, child: mapa),
              ),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            // Dos columnas mientras entren; con el texto al 200 % cada dato
            // ocupa su propia línea en vez de recortarse.
            LayoutBuilder(
              builder: (context, c) {
                final mitad = (c.maxWidth - EspaciadoCampo.l) / 2;
                return Wrap(
                  spacing: EspaciadoCampo.l,
                  runSpacing: EspaciadoCampo.m,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: mitad),
                      child: _Dato(
                        etiqueta: l10n.componentesPago,
                        valor: monto,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: mitad),
                      child: _Dato(
                        etiqueta: l10n.componentesDistancia,
                        valor: distancia,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            if (sinConexion) ...[
              Row(
                key: const Key('oferta-sin-conexion'),
                children: [
                  Icon(Icons.wifi_off_rounded, size: 20, color: paleta.alerta),
                  const SizedBox(width: EspaciadoCampo.s),
                  Expanded(
                    child: Text(
                      l10n.componentesSinConexionParaResponder,
                      style: texto.bodyMedium?.copyWith(color: paleta.texto),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
            FilledButton(
              onPressed: bloqueada
                  ? null
                  : () {
                      HapticaCampo.confirmacion();
                      onAceptar();
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
                disabledBackgroundColor: paleta.borde,
                disabledForegroundColor: paleta.textoSecundario,
              ),
              child: Text(
                respondiendo
                    ? l10n.componentesEnviando
                    : l10n.componentesAceptarServicio,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            // El alto lo pone el tema: 48 en claro y oscuro, 56 en modo campo.
            OutlinedButton(
              onPressed: bloqueada ? null : onRechazar,
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: paleta.textoSecundario,
              ),
              child: Text(l10n.componentesRechazar),
            ),
            if (onDetalle != null) ...[
              const SizedBox(height: EspaciadoCampo.xs),
              TextButton(
                onPressed: onDetalle,
                style: TextButton.styleFrom(
                  foregroundColor: paleta.acentoTexto,
                  minimumSize: const Size.fromHeight(
                    ObjetivoTactilCampo.minimo,
                  ),
                ),
                child: Text(l10n.componentesVerDetalleMapa),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: texto.labelSmall),
        const SizedBox(height: EspaciadoCampo.xs),
        Text(valor, style: texto.headlineSmall),
      ],
    );
  }
}

class _AnilloTiempo extends StatelessWidget {
  const _AnilloTiempo({
    required this.progreso,
    required this.color,
    required this.pista,
    required this.texto,
  });

  final double progreso;
  final Color color;
  final Color pista;
  final String texto;

  @override
  Widget build(BuildContext context) {
    // El anillo crece con el texto del sistema hasta vez y media: más allá
    // le quita el ancho al rótulo de al lado.
    final factor = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      1.5,
    );
    return SizedBox(
      width: 64 * factor,
      height: 64 * factor,
      child: CustomPaint(
        painter: _AnilloPainter(progreso: progreso, color: color, pista: pista),
        child: Center(
          child: Text(
            texto,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
              fontSize: 14 * factor,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  const _AnilloPainter({
    required this.progreso,
    required this.color,
    required this.pista,
  });

  final double progreso;
  final Color color;
  final Color pista;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final area = rect.deflate(3);
    canvas.drawArc(area, 0, 2 * math.pi, false, trazo..color = pista);
    canvas.drawArc(
      area,
      -math.pi / 2,
      2 * math.pi * progreso,
      false,
      trazo..color = color,
    );
  }

  @override
  bool shouldRepaint(_AnilloPainter anterior) =>
      anterior.progreso != progreso ||
      anterior.color != color ||
      anterior.pista != pista;
}
