import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../data/almacenes_locales.dart';
import '../domain/canal_aviso.dart';
import '../domain/preferencias_canales.dart';
import 'textos_canal.dart';

class CanalesEstado {
  const CanalesEstado({
    this.cargando = true,
    this.preferencias = const PreferenciasCanales(),
  });

  final bool cargando;
  final PreferenciasCanales preferencias;
}

/// Las preferencias de cada canal en este teléfono: activar o silenciar y el
/// horario de silencio. Se guardan al momento y no necesitan red.
class CanalesCubit extends Cubit<CanalesEstado> {
  CanalesCubit(this._store) : super(const CanalesEstado());

  final PreferenciasCanalesStore _store;

  Future<void> cargar() async {
    final p = await _store.leer();
    if (!isClosed) emit(CanalesEstado(cargando: false, preferencias: p));
  }

  Future<void> cambiar(CanalAviso canal, PreferenciaCanal valor) async {
    if (canal.obligatorio) return;
    final nuevas = state.preferencias.con(canal, valor);
    emit(CanalesEstado(cargando: false, preferencias: nuevas));
    await _store.guardar(nuevas);
  }
}

class CanalesPantalla extends StatelessWidget {
  const CanalesPantalla({this.store, super.key});

  /// Dónde se guardan; por defecto, el almacén local del teléfono.
  final PreferenciasCanalesStore? store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          CanalesCubit(store ?? PreferenciasCanalesLocal())..cargar(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.avisosCanalesTitulo)),
        body: SafeArea(
          child: BlocBuilder<CanalesCubit, CanalesEstado>(
            builder: (context, estado) {
              if (estado.cargando) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(EspaciadoCampo.l),
                children: [
                  Text(
                    l10n.avisosCanalesIntro,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  for (final c in CanalAviso.values) ...[
                    _TarjetaCanal(
                      canal: c,
                      preferencia: estado.preferencias.de(c),
                    ),
                    const SizedBox(height: EspaciadoCampo.m),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _hora(int minutos) =>
    '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutos % 60).toString().padLeft(2, '0')}';

class _TarjetaCanal extends StatelessWidget {
  const _TarjetaCanal({required this.canal, required this.preferencia});

  final CanalAviso canal;
  final PreferenciaCanal preferencia;

  Future<void> _elegirHora(BuildContext context, {required bool desde}) async {
    final cubit = context.read<CanalesCubit>();
    final actual =
        (desde ? preferencia.silencioDesde : preferencia.silencioHasta) ??
        (desde ? 22 * 60 : 6 * 60);
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual ~/ 60, minute: actual % 60),
    );
    if (hora == null) return;
    final minutos = hora.hour * 60 + hora.minute;
    final otro =
        (desde ? preferencia.silencioHasta : preferencia.silencioDesde) ??
        (desde ? 6 * 60 : 22 * 60);
    await cubit.cambiar(
      canal,
      preferencia.copiarCon(
        silencioDesde: () => desde ? minutos : otro,
        silencioHasta: () => desde ? otro : minutos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<CanalesCubit>();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.superficie,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        border: Border.all(color: paleta.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(canal.icono, color: paleta.acentoTexto),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(canal.nombre(l10n), style: texto.titleMedium),
                      Text(
                        canal.obligatorio
                            ? l10n.avisosCanalObligatorio
                            : canal.descripcion(l10n),
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label:
                      '${canal.nombre(l10n)}: '
                      '${preferencia.activo ? l10n.avisosCanalActivo : l10n.avisosCanalSilenciado}',
                  child: Switch(
                    key: ValueKey('canal-${canal.codigo}'),
                    value: canal.obligatorio || preferencia.activo,
                    onChanged: canal.obligatorio
                        ? null
                        : (v) => cubit.cambiar(
                            canal,
                            preferencia.copiarCon(activo: v),
                          ),
                  ),
                ),
              ],
            ),
            if (!canal.obligatorio && preferencia.activo) ...[
              const Divider(height: EspaciadoCampo.xl),
              Text(
                preferencia.tieneHorario
                    ? l10n.avisosHorarioSilencioDetalle(
                        _hora(preferencia.silencioDesde!),
                        _hora(preferencia.silencioHasta!),
                      )
                    : l10n.avisosSinHorario,
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Wrap(
                spacing: EspaciadoCampo.s,
                children: [
                  OutlinedButton(
                    key: ValueKey('desde-${canal.codigo}'),
                    onPressed: () => _elegirHora(context, desde: true),
                    child: Text(
                      '${l10n.avisosHorarioDesde} '
                      '${_hora(preferencia.silencioDesde ?? 22 * 60)}',
                    ),
                  ),
                  OutlinedButton(
                    key: ValueKey('hasta-${canal.codigo}'),
                    onPressed: () => _elegirHora(context, desde: false),
                    child: Text(
                      '${l10n.avisosHorarioHasta} '
                      '${_hora(preferencia.silencioHasta ?? 6 * 60)}',
                    ),
                  ),
                  if (preferencia.tieneHorario)
                    TextButton(
                      key: ValueKey('quitar-${canal.codigo}'),
                      onPressed: () => cubit.cambiar(
                        canal,
                        preferencia.copiarCon(
                          silencioDesde: () => null,
                          silencioHasta: () => null,
                        ),
                      ),
                      child: Text(l10n.avisosQuitarHorario),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
