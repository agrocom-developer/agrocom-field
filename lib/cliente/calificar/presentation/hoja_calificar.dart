import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/boton_principal.dart';
import '../domain/calificacion_repositorio.dart';
import 'calificar_cubit.dart';

/// Abre la hoja para calificar al proveedor de [servicio]. Devuelve `true`
/// si la calificación quedó registrada.
Future<bool> mostrarHojaCalificar(
  BuildContext context,
  Servicio servicio,
) async {
  final mensajero = ScaffoldMessenger.of(context);
  final enviada = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.paleta.superficieElevada,
    builder: (_) => BlocProvider(
      create: (_) =>
          CalificarCubit(context.read<CalificacionRepositorio>(), servicio.id),
      child: HojaCalificar(servicio: servicio),
    ),
  );
  if (enviada ?? false) {
    mensajero.showSnackBar(
      const SnackBar(content: Text('Gracias por calificar el servicio')),
    );
  }
  return enviada ?? false;
}

/// Calificación en dos toques: una estrella y «Enviar». Las etiquetas y el
/// comentario aparecen después de elegir la estrella y son opcionales.
class HojaCalificar extends StatelessWidget {
  const HojaCalificar({required this.servicio, super.key});

  final Servicio servicio;

  static const _palabras = [
    'Toca una estrella',
    'Mala',
    'Regular',
    'Buena',
    'Muy buena',
    'Excelente',
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final proveedor = servicio.proveedor;
    final duracion = MovimientoCampo.duracion(context, MovimientoCampo.media);
    return BlocConsumer<CalificarCubit, CalificarEstado>(
      listenWhen: (a, b) => a.fase != b.fase,
      listener: (context, estado) {
        if (estado.fase == FaseCalificar.enviada) {
          HapticaCampo.confirmacion();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, estado) {
        final cubit = context.read<CalificarCubit>();
        final enviando = estado.fase == FaseCalificar.enviando;
        return Padding(
          // La hoja sube con el teclado.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              EspaciadoCampo.xl,
              0,
              EspaciadoCampo.xl,
              EspaciadoCampo.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (proveedor != null) ...[
                  Center(child: AvatarProveedor(proveedor, tamano: 64)),
                  const SizedBox(height: EspaciadoCampo.m),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    proveedor == null
                        ? '¿Cómo fue el servicio?'
                        : '¿Cómo fue el servicio de '
                              '${proveedor.nombre.split(' ').first}?',
                    style: texto.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  '${servicio.lote.nombre} · '
                  '${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)}',
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: EspaciadoCampo.l),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CalificacionCampo(
                      valor: estado.puntaje,
                      tamano: 44,
                      onCambio: enviando ? null : cubit.elegirPuntaje,
                    ),
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                AnimatedSwitcher(
                  duration: MovimientoCampo.duracion(
                    context,
                    MovimientoCampo.rapida,
                  ),
                  child: Text(
                    _palabras[estado.puntaje],
                    key: ValueKey(estado.puntaje),
                    style: texto.titleMedium?.copyWith(
                      color: estado.puntaje == 0
                          ? paleta.textoSecundario
                          : paleta.acentoTexto,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                AnimatedSize(
                  duration: duracion,
                  curve: MovimientoCampo.movimiento,
                  alignment: Alignment.topCenter,
                  child: estado.puntaje == 0
                      ? const SizedBox(width: double.infinity)
                      : _Opcionales(estado: estado, bloqueado: enviando),
                ),
                if (estado.fase == FaseCalificar.error) ...[
                  const SizedBox(height: EspaciadoCampo.l),
                  Semantics(
                    liveRegion: true,
                    child: AvisoMarketplace(
                      tono: TonoAviso.error,
                      icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
                      mensaje: estado.sinConexion
                          ? 'Sin conexión. Tu calificación no se envió; '
                                'prueba de nuevo cuando tengas señal.'
                          : 'No pudimos enviar tu calificación. Prueba de '
                                'nuevo.',
                    ),
                  ),
                ],
                const SizedBox(height: EspaciadoCampo.xl),
                BotonPrincipal(
                  key: const ValueKey('enviar-calificacion'),
                  texto: estado.fase == FaseCalificar.error
                      ? 'Reintentar'
                      : 'Enviar calificación',
                  cargando: enviando,
                  onPressed: estado.puedeEnviar ? cubit.enviar : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Opcionales extends StatefulWidget {
  const _Opcionales({required this.estado, required this.bloqueado});

  final CalificarEstado estado;
  final bool bloqueado;

  @override
  State<_Opcionales> createState() => _OpcionalesState();
}

class _OpcionalesState extends State<_Opcionales> {
  late final _comentario = TextEditingController(
    text: widget.estado.comentario,
  );

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<CalificarCubit>();
    final estado = widget.estado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: EspaciadoCampo.xl),
        Text(
          estado.puntaje >= 4 ? '¿Qué destacás?' : '¿Qué se puede mejorar?',
          style: texto.titleSmall,
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Wrap(
          spacing: EspaciadoCampo.s,
          runSpacing: EspaciadoCampo.xs,
          children: [
            for (final e in EtiquetaCalificacion.values)
              FilterChip(
                key: ValueKey('etiqueta-${e.name}'),
                label: Text(e.etiqueta),
                selected: estado.etiquetas.contains(e),
                showCheckmark: true,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                selectedColor: paleta.acento,
                checkmarkColor: paleta.sobreAcento,
                backgroundColor: paleta.superficie,
                side: BorderSide(
                  color: estado.etiquetas.contains(e)
                      ? paleta.acentoTexto
                      : paleta.bordeFuerte,
                ),
                labelStyle: texto.labelLarge?.copyWith(
                  color: estado.etiquetas.contains(e)
                      ? paleta.sobreAcento
                      : paleta.texto,
                ),
                onSelected: widget.bloqueado
                    ? null
                    : (_) {
                        HapticaCampo.seleccion();
                        cubit.alternarEtiqueta(e);
                      },
              ),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.l),
        TextField(
          key: const ValueKey('comentario-calificacion'),
          controller: _comentario,
          enabled: !widget.bloqueado,
          minLines: 2,
          maxLines: 4,
          maxLength: CalificarCubit.largoMaximoComentario,
          textCapitalization: TextCapitalization.sentences,
          onChanged: cubit.cambiarComentario,
          decoration: const InputDecoration(
            labelText: 'Comentario (opcional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
