import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 03b · Inicio, variante "una sola decisión" (sección 1b del mockup): el
/// trabajo asignado por el jefe de campo (HU-70, `TrabajoCatalogo` del
/// pull: `orden_id`, `lote_id`, `hectareas_declaradas`, `equipo_trabajo_id`)
/// como titular sobre la foto, una sola acción grande y el clima resumido —
/// menos densidad que 03 para guantes y sol fuerte, a costa de esconder el
/// resto del día. Convive con 03 en la vista previa para que el dueño
/// compare las dos con una pantalla real en la mano. Datos mock.
class InicioDecisionCampoVitrina extends StatelessWidget {
  const InicioDecisionCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronAgrasT50,
      alineacion: const Alignment(-0.6, 0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BannerAlertaCampo(
                texto: 'SIN CONEXIÓN · 4 PENDIENTES',
                valor: 'outbox',
              ),
              const Spacer(),
              Text(
                'TE TOCA HOY',
                style: TipografiaCampo.etiquetaMono.copyWith(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: ColoresCampo.acentoLima,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lote 14\nLa Nena',
                style: TipografiaCampo.tituloHero.copyWith(
                  fontSize: 44,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '42,5 ha · 12 L/ha · líquido\nOrden 2431 · Equipo 2',
                style: TipografiaCampo.cuerpo.copyWith(fontSize: 16),
              ),
              const Spacer(),
              const Row(
                children: [
                  Expanded(
                    child: StatChipCampo(
                      etiqueta: 'Viento',
                      valor: '9',
                      unidad: 'km/h',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: StatChipCampo(
                      etiqueta: 'Temp',
                      valor: '24°',
                      unidad: 'C',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: StatChipCampo(
                      etiqueta: 'Humedad',
                      valor: '61',
                      unidad: '%',
                      notaAlerta: 'Apta',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BotonPrimarioCampo(texto: 'Iniciar aplicación', onPressed: () {}),
              const SizedBox(height: 14),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: TipografiaCampo.datoMonoDestacado.copyWith(
                      color: ColoresCampo.textoPrincipal.withValues(
                        alpha: OpacidadesCampo.secundaria,
                      ),
                    ),
                    children: const [
                      TextSpan(text: 'ÓRDENES      EQUIPOS      '),
                      TextSpan(
                        text: 'SYNC 4',
                        style: TextStyle(color: ColoresCampo.acentoAmbar),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
