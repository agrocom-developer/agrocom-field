import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/mezcla_repositorio.dart';

/// Registro de mezcla del auxiliar: cada carga se anota al instante, con su
/// estado de sincronización a la vista. La pantalla cambia antes de que haya
/// señal (invariante 3 de `CLAUDE.md`).
class MezclaPantalla extends StatelessWidget {
  const MezclaPantalla({super.key});

  Future<void> _registrar(BuildContext context) async {
    final repo = context.read<MezclaRepositorio>();
    final litros = await showModalBottomSheet<Decimal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _HojaCarga(),
    );
    if (litros == null) return;
    await repo.registrar(
      producto: 'Glifosato 480 SL + coadyuvante',
      litros: litros,
    );
    HapticaCampo.confirmacion();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return StreamEstable<List<RegistroMezcla>>(
      crear: () => context.read<MezclaRepositorio>().observar(),
      builder: (context, snap) {
        final mezclas = snap.data ?? const <RegistroMezcla>[];
        final total = mezclas.fold<Decimal>(
          Decimal.zero,
          (a, m) => a + m.litros,
        );
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                EspaciadoCampo.l,
                EspaciadoCampo.l,
                EspaciadoCampo.l,
                120,
              ),
              children: [
                Text('Mezcla', style: texto.headlineMedium),
                const SizedBox(height: 16),
                SuperficieMarketplace(
                  resaltada: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CALDO PREPARADO',
                        style: texto.labelSmall?.copyWith(
                          color: paleta.textoSecundario,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        FormatoMarketplace.litros(total),
                        style: texto.displaySmall?.copyWith(
                          color: paleta.acentoTexto,
                        ),
                      ),
                      Text(
                        '${mezclas.length} ${mezclas.length == 1 ? 'carga' : 'cargas'}',
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Cargas', style: texto.titleLarge),
                const SizedBox(height: 12),
                if (snap.data != null && mezclas.isEmpty)
                  const EstadoVacioMarketplace(
                    icono: Icons.science_outlined,
                    titulo: 'Todavía no registraste cargas',
                  ),
                for (final m in mezclas) ...[
                  SuperficieMarketplace(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: paleta.acento.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${m.numeroTanque}',
                            style: texto.titleMedium?.copyWith(
                              color: paleta.acentoTexto,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FormatoMarketplace.litros(m.litros),
                                style: texto.titleMedium,
                              ),
                              Text(
                                '${m.producto} · ${FormatoMarketplace.hora(m.registradoEn)}',
                                style: texto.bodySmall?.copyWith(
                                  color: paleta.textoSecundario,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          m.sincronizado
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_upload_outlined,
                          size: 18,
                          color: m.sincronizado ? paleta.exito : paleta.alerta,
                          semanticLabel: m.sincronizado
                              ? 'Sincronizada'
                              : 'Pendiente de sincronizar',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            Positioned(
              left: EspaciadoCampo.l,
              right: EspaciadoCampo.l,
              bottom: EspaciadoCampo.l,
              child: BotonPrimarioCampo(
                texto: 'Registrar carga',
                onPressed: () => _registrar(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hoja para anotar los litros de una carga. Es dueña de su controlador: se
/// libera cuando la hoja termina de cerrarse, no antes.
class _HojaCarga extends StatefulWidget {
  const _HojaCarga();

  @override
  State<_HojaCarga> createState() => _HojaCargaState();
}

class _HojaCargaState extends State<_HojaCarga> {
  final _controlador = TextEditingController(text: '96');

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final v = Decimal.tryParse(_controlador.text.replaceAll(',', '.').trim());
    if (v != null && v > Decimal.zero) Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        0,
        EspaciadoCampo.l,
        MediaQuery.viewInsetsOf(context).bottom + EspaciadoCampo.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva carga', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controlador,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Litros de caldo',
              suffixText: 'L',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          BotonPrimarioCampo(texto: 'Registrar carga', onPressed: _confirmar),
        ],
      ),
    );
  }
}
