import 'package:flutter/material.dart';

import '../componentes/componentes_campo.dart';
import '../imagenes_campo.dart';
import '../tipografia_campo.dart';

/// 07 · Reporte de equipos (HU-80) — ajustada al contrato real
/// (`RegistroSync.tipo = evidencia_equipo`, `docs/api/openapi.yaml` de
/// `agrocom-api`): `horas_vuelo_dron` declaradas (no calculadas) y tres
/// fotos OBLIGATORIAS, cada una subida antes por `POST /api/evidencias` con
/// su tipo (`foto_control`, `foto_ciclo_bateria_balanceo`,
/// `foto_dron_limpio`) y referenciada por `uuid_cliente`; falta cualquiera y
/// el servidor rechaza el registro completo.
///
/// Lo que el mockup traía y el contrato no: la lista de baterías con sus
/// ciclos — ese dato lo lleva Mantenimiento en el panel (HU-87, "como el
/// odómetro de un auto") y la app no lo declara. Datos mock.
class ReporteEquiposCampoVitrina extends StatefulWidget {
  const ReporteEquiposCampoVitrina({super.key});

  @override
  State<ReporteEquiposCampoVitrina> createState() =>
      _ReporteEquiposCampoVitrinaState();
}

class _ReporteEquiposCampoVitrinaState
    extends State<ReporteEquiposCampoVitrina> {
  final _horasVuelo = TextEditingController(text: '4,2');

  @override
  void dispose() {
    _horasVuelo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoCampo(
              titulo: 'Reporte de equipos',
              subtitulo: 'Auxiliar · cierre de jornada · evidencia_equipo',
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: CampoTextoCampo(
                          etiqueta: 'Horas de vuelo del dron',
                          controller: _horasVuelo,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        flex: 2,
                        child: StatChipCampo(etiqueta: 'Dron', valor: 'T50 #2'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EVIDENCIAS OBLIGATORIAS · 3 DE 3',
                    style: TipografiaCampo.etiquetaMono,
                  ),
                  const SizedBox(height: 10),
                  GridEvidenciasCampo(
                    celdas: const [
                      CeldaEvidenciaCampo(
                        etiqueta: 'foto de control',
                        miniatura: AssetImage(ImagenesCampo.equipoDron),
                      ),
                      CeldaEvidenciaCampo(
                        etiqueta: 'ciclo de batería y balanceo',
                        miniatura: AssetImage(ImagenesCampo.dronSobreAgua),
                      ),
                      CeldaEvidenciaCampo(etiqueta: 'dron limpio'),
                    ],
                    onAgregar: (_) {},
                  ),
                  const SizedBox(height: 12),
                  const NotaTecnicaCampo(
                    texto:
                        'Las tres fotos van por POST /api/evidencias (cola '
                        'de evidencias, TE-07) antes que el registro; el '
                        'registro las referencia por uuid_cliente. Falta una '
                        'y el servidor rechaza evidencia_equipo entero. Los '
                        'ciclos de batería los lleva el panel (HU-87), acá '
                        'no se declaran.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const NotaInlineCampo(
              texto: '2 de 3 evidencias en cola · falta dron limpio',
            ),
            const SizedBox(height: 12),
            BotonPrimarioCampo(texto: 'Cerrar reporte', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
