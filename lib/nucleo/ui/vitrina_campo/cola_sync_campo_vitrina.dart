import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../componentes/componentes_campo.dart';
import '../tipografia_campo.dart';

class _RegistroColaVitrina {
  const _RegistroColaVitrina({
    required this.badge,
    required this.estado,
    required this.titulo,
    required this.subtitulo,
  });

  final String badge;
  final EstadoBadgeCampo estado;
  final String titulo;
  final String subtitulo;
}

const _registros = [
  _RegistroColaVitrina(
    badge: 'PEND',
    estado: EstadoBadgeCampo.pendiente,
    titulo: 'aplicacion',
    subtitulo: 'Lote 14 · 05:24',
  ),
  _RegistroColaVitrina(
    badge: 'PEND',
    estado: EstadoBadgeCampo.pendiente,
    titulo: 'registro_mezcla',
    subtitulo: '3 productos · 05:31',
  ),
  _RegistroColaVitrina(
    badge: 'PEND',
    estado: EstadoBadgeCampo.pendiente,
    titulo: 'evidencia · dron limpio',
    subtitulo: '1,8 MB · 18:02',
  ),
  _RegistroColaVitrina(
    badge: 'RETRY',
    estado: EstadoBadgeCampo.reintento,
    titulo: 'clima',
    subtitulo: 'intento 3 · 05:38',
  ),
  _RegistroColaVitrina(
    badge: 'OK',
    estado: EstadoBadgeCampo.ok,
    titulo: 'recepcion_caldo',
    subtitulo: 'enviado 07:02',
  ),
];

/// 09 · Cola de sincronización — estado offline siempre visible (invariante
/// 1 de `CLAUDE.md`). Recreada del mockup de referencia (ADR 0008); los
/// registros son mock, no vienen del outbox real.
class ColaSyncCampoVitrina extends StatelessWidget {
  const ColaSyncCampoVitrina({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoCampo(
              titulo: 'Cola de sincronización',
              subtitulo: 'Último envío ok: 13/9 07:02',
            ),
            const SizedBox(height: 16),
            TarjetaCampo(
              acento: ColoresCampo.acentoAmbar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '7',
                        style: TipografiaCampo.valorDestacado.copyWith(
                          fontSize: 34,
                          color: ColoresCampo.acentoAmbarTexto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'registros pendientes',
                        style: TipografiaCampo.datoMonoDestacado.copyWith(
                          fontSize: 13,
                          color: ColoresCampo.acentoAmbarTexto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sin conectividad. Nada se pierde: el outbox reintenta '
                    'solo y el envío es idempotente.',
                    style: TipografiaCampo.notaMono.copyWith(
                      height: 1.5,
                      color: ColoresCampo.acentoAmbarTexto.withValues(
                        alpha: OpacidadesCampo.casiPlena,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _registros.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, indice) {
                  final registro = _registros[indice];
                  final esOk = registro.estado == EstadoBadgeCampo.ok;
                  return TarjetaCampo(
                    child: Row(
                      children: [
                        BadgeEstadoCampo(
                          texto: registro.badge,
                          estado: registro.estado,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                registro.titulo,
                                style: TipografiaCampo.tituloTarjeta.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ColoresCampo.textoPrincipal.withValues(
                                    alpha: esOk
                                        ? OpacidadesCampo.alta
                                        : OpacidadesCampo.plena,
                                  ),
                                ),
                              ),
                              Text(
                                registro.subtitulo,
                                style: TipografiaCampo.datoMono.copyWith(
                                  fontSize: 11,
                                  color: ColoresCampo.textoPrincipal.withValues(
                                    alpha: OpacidadesCampo.atenuada,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            BotonSecundarioCampo(texto: 'Reintentar ahora', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
