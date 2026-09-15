import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 03 · Inicio del piloto (HU-70) — el trabajo asignado por el jefe de
/// campo ya resuelto al entrar (`TrabajoCatalogo` del pull: `orden_id`,
/// `lote_id`, `hectareas_declaradas`, `equipo_trabajo_id`), clima resumido
/// y accesos rápidos. Recreada del mockup (ADR 0008); "Rubén", "Lote 14" y
/// los valores de clima son datos mock, no vienen de `drift`. Cultivo y
/// producto no viajan en el catálogo, por eso no se muestran.
class InicioPilotoCampoVitrina extends StatelessWidget {
  const InicioPilotoCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronAgrasT50,
      cobertura: CoberturaFondoFoto.superior,
      altoSuperior: 220,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const BannerAlertaCampo(
              texto: 'SIN CONEXIÓN · LOTE',
              valor: '4 pendientes ↑',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColoresCampo.superficie,
                    border: Border.all(
                      color: ColoresCampo.textoPrincipal.withValues(
                        alpha: 0.14,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: ColoresCampo.textoPrincipal.withValues(
                      alpha: OpacidadesCampo.media,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, Rubén',
                        style: TipografiaCampo.tituloSeccion.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Piloto · Equipo 2 · dom 13 sep',
                        style: TipografiaCampo.cuerpoSecundario.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TarjetaCampo(
              tamano: TamanoTarjetaCampo.grande,
              acento: ColoresCampo.acentoLima,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ASIGNADO POR JEFE DE CAMPO',
                        style: TipografiaCampo.etiquetaMono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColoresCampo.acentoLima,
                        ),
                      ),
                      Text(
                        '07:20',
                        style: TipografiaCampo.datoMono.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lote 14 — La Nena',
                    style: TipografiaCampo.valorDestacado,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Orden 2431 · Equipo 2 · líquido · 12 L/ha',
                    style: TipografiaCampo.cuerpoSecundario,
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: StatChipCampo(
                          etiqueta: 'Hectáreas',
                          valor: '42,5',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StatChipCampo(etiqueta: 'L / ha', valor: '12'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StatChipCampo(etiqueta: 'Lotes', valor: '2'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BotonPrimarioCampo(
                    texto: 'Crear aplicación',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: StatChipCampo(
                    etiqueta: 'Viento',
                    valor: '9',
                    unidad: 'km/h',
                    notaAlerta: 'Ráfagas 21',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatChipCampo(
                    etiqueta: 'Temp / hum',
                    valor: '24°',
                    unidad: '/ 61%',
                    notaAlerta: 'Apto para aplicar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            BarraNavegacionCampo(
              items: const [
                ItemBarraNavegacionCampo(
                  icono: Icons.home_filled,
                  etiqueta: 'Inicio',
                ),
                ItemBarraNavegacionCampo(
                  icono: Icons.list_alt,
                  etiqueta: 'Órdenes',
                ),
                ItemBarraNavegacionCampo(
                  icono: Icons.hub_outlined,
                  etiqueta: 'Equipos',
                ),
                ItemBarraNavegacionCampo(
                  icono: Icons.sync,
                  etiqueta: 'Sync',
                  insignia: 4,
                ),
              ],
              indiceActivo: 0,
              onSeleccionar: (_) {},
              onAccionCentral: () {},
            ),
          ],
        ),
      ),
    );
  }
}
