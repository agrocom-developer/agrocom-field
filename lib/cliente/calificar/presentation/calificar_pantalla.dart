import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/calificacion_repositorio.dart';
import 'calificar_cubit.dart';

/// Abre la pantalla para calificar al proveedor de [servicio]. Devuelve
/// `true` si la calificación quedó registrada.
Future<bool> abrirCalificar(BuildContext context, Solicitud servicio) async {
  final mensajero = ScaffoldMessenger.of(context);
  final enviada = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => BlocProvider(
        create: (c) =>
            CalificarCubit(c.read<CalificacionRepositorio>(), servicio.id),
        child: CalificarPantalla(servicio: servicio),
      ),
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
/// comentario aparecen después de elegir la estrella y son opcionales;
/// «Omitir» cierra sin calificar.
class CalificarPantalla extends StatelessWidget {
  const CalificarPantalla({required this.servicio, super.key});

  final Solicitud servicio;

  static const _palabras = [
    'Toca una estrella',
    'Malo',
    'Regular',
    'Bueno',
    'Muy bueno',
    'Excelente',
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final nombre = servicio.nombreProveedor;
    final primerNombre = nombre?.split(' ').first;
    final proveedor = nombre == null
        ? null
        : Proveedor(
            id: servicio.proveedorId ?? '0',
            nombre: nombre,
            tipo: TipoProveedor.independiente,
            calificacion: 0,
            serviciosCompletados: 0,
            zonas: const [],
          );
    final duracion = MovimientoCampo.duracion(context, MovimientoCampo.media);
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
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
        return Scaffold(
          // La pantalla sube con el teclado: el comentario queda a la vista.
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: margen),
                        child: TextButton(
                          key: const ValueKey('omitir-calificacion'),
                          onPressed: enviando
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: paleta.textoSecundario,
                            minimumSize: const Size(
                              ObjetivoTactilCampo.minimo,
                              ObjetivoTactilCampo.minimo,
                            ),
                          ),
                          child: const Text('Omitir'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: margen),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (proveedor != null) ...[
                              Center(
                                child: AvatarProveedor(
                                  proveedor,
                                  tamano: ObjetivoTactilCampo.campo + 8,
                                ),
                              ),
                              const SizedBox(height: EspaciadoCampo.l),
                            ],
                            Semantics(
                              header: true,
                              child: Text(
                                primerNombre == null
                                    ? '¿Cómo fue el servicio?'
                                    : '¿Cómo fue el servicio de '
                                          '$primerNombre?',
                                style: TipografiaCampo.tituloBloque.copyWith(
                                  color: paleta.texto,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: EspaciadoCampo.s),
                            Text(
                              _resumen(servicio),
                              style: TipografiaCampo.datoMono.copyWith(
                                color: paleta.textoSecundario,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: EspaciadoCampo.xl),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: CalificacionCampo(
                                  valor: estado.puntaje,
                                  tamano: 48,
                                  onCambio: enviando
                                      ? null
                                      : cubit.elegirPuntaje,
                                ),
                              ),
                            ),
                            const SizedBox(height: EspaciadoCampo.s),
                            AnimatedSwitcher(
                              duration: MovimientoCampo.duracion(
                                context,
                                MovimientoCampo.rapida,
                              ),
                              child: Text(
                                _palabras[estado.puntaje],
                                key: ValueKey(estado.puntaje),
                                style: TipografiaCampo.tituloSeccion.copyWith(
                                  color: estado.puntaje == 0
                                      ? paleta.textoSecundario
                                      : paleta.texto,
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
                                  : _Opcionales(
                                      estado: estado,
                                      bloqueado: enviando,
                                    ),
                            ),
                            if (estado.fase == FaseCalificar.error) ...[
                              const SizedBox(height: EspaciadoCampo.l),
                              Semantics(
                                liveRegion: true,
                                child: AvisoMarketplace(
                                  key: const ValueKey('aviso-calificacion'),
                                  tono: TonoAviso.error,
                                  icono: estado.sinConexion
                                      ? Icons.wifi_off_rounded
                                      : null,
                                  mensaje: estado.sinConexion
                                      ? 'Sin conexión. Tu calificación no se '
                                            'envió; prueba de nuevo cuando '
                                            'tengas señal.'
                                      : 'No pudimos enviar tu calificación. '
                                            'Prueba de nuevo.',
                                ),
                              ),
                            ],
                            const SizedBox(height: EspaciadoCampo.l),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        margen,
                        EspaciadoCampo.s,
                        margen,
                        EspaciadoCampo.l,
                      ),
                      child: BotonPrincipal(
                        key: const ValueKey('enviar-calificacion'),
                        texto: estado.fase == FaseCalificar.error
                            ? 'Reintentar'
                            : 'Enviar calificación',
                        cargando: enviando,
                        onPressed: estado.puedeEnviar ? cubit.enviar : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// «El Tajibo Norte · 118 ha · Bs 7.552», con lo ejecutado y lo acordado
  /// cuando el servidor ya los congeló.
  static String _resumen(Solicitud s) {
    final ejecutadas = s.hectareasEjecutadas ?? s.hectareas;
    return '${s.lote.nombre} · ${FormatoMarketplace.hectareas(ejecutadas)}'
        ' · ${FormatoMarketplace.bs(s.totalAPagar)}';
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
    final cubit = context.read<CalificarCubit>();
    final estado = widget.estado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: EspaciadoCampo.xl),
        Text(
          estado.puntaje >= 4 ? '¿Qué destacas?' : '¿Qué se puede mejorar?',
          style: TipografiaCampo.etiqueta.copyWith(
            color: paleta.textoSecundario,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspaciadoCampo.s,
          runSpacing: EspaciadoCampo.s,
          children: [
            for (final e in EtiquetaCalificacion.values)
              _EtiquetaElegible(
                key: ValueKey('etiqueta-${e.name}'),
                texto: e.etiqueta,
                elegida: estado.etiquetas.contains(e),
                alElegir: widget.bloqueado
                    ? null
                    : () {
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
          minLines: 3,
          maxLines: 4,
          maxLength: CalificarCubit.largoMaximoComentario,
          textCapitalization: TextCapitalization.sentences,
          onChanged: cubit.cambiarComentario,
          decoration: InputDecoration(
            hintText: 'Comentario opcional',
            alignLabelWithHint: true,
            filled: true,
            fillColor: paleta.superficie,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadioCampo.campo),
              borderSide: BorderSide(color: paleta.bordeFuerte),
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta de la calificación: píldora tonal con tilde cuando está elegida
/// (el estado no depende solo del color) y objetivo táctil de 48.
class _EtiquetaElegible extends StatelessWidget {
  const _EtiquetaElegible({
    required this.texto,
    required this.elegida,
    required this.alElegir,
    super.key,
  });

  final String texto;
  final bool elegida;
  final VoidCallback? alElegir;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final forma = BorderRadius.circular(RadioCampo.chip);
    final color = elegida ? paleta.sobreAcentoContenedor : paleta.texto;
    return Semantics(
      button: true,
      selected: elegida,
      child: AnimatedContainer(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
        constraints: const BoxConstraints(
          minHeight: ObjetivoTactilCampo.minimo,
        ),
        decoration: BoxDecoration(
          color: elegida ? paleta.acentoContenedor : paleta.superficie,
          borderRadius: forma,
          border: Border.all(
            color: elegida ? paleta.acentoTexto : paleta.borde,
            width: elegida ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: forma,
            onTap: alElegir,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (elegida) ...[
                    Icon(Icons.check_rounded, size: 18, color: color),
                    const SizedBox(width: EspaciadoCampo.xs),
                  ],
                  Flexible(
                    child: Text(
                      texto,
                      style: TipografiaCampo.tituloTarjeta.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
