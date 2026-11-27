import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/componentes/componentes_campo.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../dominio/dominio.dart';
import 'estado_vacio_marketplace.dart';
import 'formato_marketplace.dart';
import 'superficie_marketplace.dart';

/// Pantalla de calificaciones: el promedio en grande con las estrellas
/// doradas, cuántas hay de cada puntaje y cada reseña con su autor,
/// estrellas, fecha y comentario. La usan `cliente` y `piloto` (cada rol ve
/// lo que escribió la contraparte). Sin calificaciones orienta en vez de
/// mostrar una pantalla vacía.
class CalificacionesPantalla extends StatelessWidget {
  const CalificacionesPantalla({
    required this.resumen,
    this.reloj = DateTime.now,
    super.key,
  });

  final ResumenCalificaciones resumen;
  final DateTime Function() reloj;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ahora = reloj();
    return Scaffold(
      appBar: AppBar(title: Text(t.perfilUxCalificacionesTitulo)),
      body: resumen.total == 0 && resumen.recientes.isEmpty
          ? EstadoVacioMarketplace(
              icono: Icons.star_rounded,
              titulo: t.perfilUxCalificacionesVacioTitulo,
              detalle: t.perfilUxCalificacionesVacioDetalle,
            )
          : ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              children: EntradaCampo.escalonar([
                ResumenCalificacionesCampo(resumen: resumen),
                const SizedBox(height: EspaciadoCampo.l),
                for (final c in resumen.recientes) ...[
                  ResenaCalificacionCampo(calificacion: c, ahora: ahora),
                  const SizedBox(height: EspaciadoCampo.m),
                ],
              ]),
            ),
    );
  }
}

/// Promedio en grande y cuántas calificaciones hay de cada puntaje.
class ResumenCalificacionesCampo extends StatelessWidget {
  const ResumenCalificacionesCampo({required this.resumen, super.key});

  final ResumenCalificaciones resumen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final promedio = resumen.promedio.toStringAsFixed(1).replaceAll('.', ',');
    final mayor = resumen.porPuntaje.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );
    return SuperficieMarketplace(
      key: const Key('perfil-calificaciones'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: l10n.proveedorPerfilCalificacionPromedioSobreCalificaciones(
              promedio,
              resumen.total,
            ),
            excludeSemantics: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: EspaciadoCampo.m,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EstrellaCampo(tamano: 36),
                    const SizedBox(width: EspaciadoCampo.xs),
                    Text(promedio, style: texto.displaySmall),
                  ],
                ),
                Text(
                  resumen.total == 1
                      ? l10n.proveedorPerfilCalificacion
                      : l10n.proveedorPerfilCalificaciones(resumen.total),
                  style: texto.bodyLarge,
                ),
              ],
            ),
          ),
          if (mayor > 0) ...[
            const SizedBox(height: EspaciadoCampo.m),
            for (var puntaje = 5; puntaje >= 1; puntaje--)
              _BarraPuntaje(
                puntaje: puntaje,
                cantidad: resumen.porPuntaje[puntaje] ?? 0,
                mayor: mayor,
              ),
          ],
        ],
      ),
    );
  }
}

class _BarraPuntaje extends StatelessWidget {
  const _BarraPuntaje({
    required this.puntaje,
    required this.cantidad,
    required this.mayor,
  });

  final int puntaje;
  final int cantidad;
  final int mayor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final escala = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      label:
          '$puntaje ${puntaje == 1 ? 'estrella' : 'estrellas'}: '
          '$cantidad',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.xs),
        child: Row(
          children: [
            SizedBox(
              width: escala.scale(14),
              child: Text('$puntaje', style: texto.bodyMedium),
            ),
            EstrellaCampo(tamano: 14, color: paleta.textoSecundario),
            const SizedBox(width: EspaciadoCampo.s),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RadioCampo.capsula),
                child: LinearProgressIndicator(
                  value: cantidad / mayor,
                  minHeight: 8,
                  backgroundColor: paleta.borde,
                  color: paleta.acentoTexto,
                ),
              ),
            ),
            const SizedBox(width: EspaciadoCampo.s),
            SizedBox(
              width: escala.scale(32),
              child: Text(
                '$cantidad',
                style: texto.bodyMedium,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResenaCalificacionCampo extends StatelessWidget {
  const ResenaCalificacionCampo({
    required this.calificacion,
    required this.ahora,
    super.key,
  });

  final CalificacionRecibida calificacion;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final comentario = calificacion.comentario;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(calificacion.autor, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.xs),
          Wrap(
            spacing: EspaciadoCampo.m,
            runSpacing: EspaciadoCampo.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CalificacionCampo(valor: calificacion.puntaje),
              Text(
                FormatoMarketplace.hace(calificacion.fecha, ahora),
                style: texto.bodyMedium,
              ),
            ],
          ),
          if (comentario != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text(comentario, style: texto.bodyLarge),
          ],
        ],
      ),
    );
  }
}
