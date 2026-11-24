import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/boton_principal.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/problema_repositorio.dart';
import 'reportar_problema_cubit.dart';

/// El cliente reporta un problema con un servicio: elige un motivo, cuenta
/// qué vio y envía. Devuelve `true` al cerrarse si el reporte quedó
/// registrado.
class ReportarProblemaPantalla extends StatelessWidget {
  const ReportarProblemaPantalla({required this.servicio, super.key});

  final Solicitud servicio;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportarProblemaCubit(
        context.read<ProblemaRepositorio>(),
        servicioId: servicio.id,
        claveIdempotencia: const Uuid().v4(),
      ),
      child: _Vista(servicio: servicio),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.servicio});

  final Solicitud servicio;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportarProblemaCubit, ReportarProblemaEstado>(
      builder: (context, estado) {
        final enviado = estado.fase == FaseReporte.enviado;
        return PopScope(
          canPop: !enviado,
          onPopInvokedWithResult: (salio, _) {
            if (!salio) Navigator.of(context).pop(true);
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Reportar un problema')),
            body: AnimatedSwitcher(
              duration: MovimientoCampo.duracion(
                context,
                MovimientoCampo.media,
              ),
              switchInCurve: MovimientoCampo.entrada,
              child: enviado
                  ? _Enviado(key: const ValueKey('enviado'), caso: estado.caso!)
                  : _Formulario(
                      key: const ValueKey('formulario'),
                      servicio: servicio,
                      estado: estado,
                    ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(EspaciadoCampo.l),
              child: enviado
                  ? BotonPrincipal(
                      texto: 'Volver al servicio',
                      onPressed: () => Navigator.of(context).pop(true),
                    )
                  : BotonPrincipal(
                      key: const ValueKey('enviar-reporte'),
                      texto: estado.fase == FaseReporte.error
                          ? 'Reintentar'
                          : 'Enviar reporte',
                      cargando: estado.fase == FaseReporte.enviando,
                      onPressed: estado.puedeEnviar
                          ? context.read<ReportarProblemaCubit>().enviar
                          : null,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({required this.servicio, required this.estado, super.key});

  final Solicitud servicio;
  final ReportarProblemaEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<ReportarProblemaCubit>();
    final bloqueado = estado.fase == FaseReporte.enviando;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            margen,
            EspaciadoCampo.l,
            margen,
            EspaciadoCampo.xl,
          ),
          children: [
            Text(
              '${servicio.lote.nombre} · '
              '${FormatoMarketplace.fechaLarga(servicio.ventanaDesde)}',
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Semantics(
              header: true,
              child: Text('¿Qué pasó?', style: texto.headlineSmall),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Semantics(
              container: true,
              label: 'Motivo del problema',
              child: Column(
                children: [
                  for (final m in MotivoProblema.values) ...[
                    _OpcionMotivo(
                      motivo: m,
                      elegido: estado.motivo == m,
                      alElegir: bloqueado ? null : () => cubit.elegirMotivo(m),
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                  ],
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            TextField(
              key: const ValueKey('detalle-problema'),
              enabled: !bloqueado,
              minLines: 3,
              maxLines: 6,
              maxLength: ReportarProblemaCubit.largoMaximoDetalle,
              textCapitalization: TextCapitalization.sentences,
              onChanged: cubit.cambiarDetalle,
              decoration: const InputDecoration(
                labelText: 'Cuéntanos qué viste',
                helperText: 'Al menos una oración: dónde, cuándo y qué.',
                helperMaxLines: 3,
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            if (estado.fase == FaseReporte.error)
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  tono: TonoAviso.error,
                  icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
                  mensaje: estado.sinConexion
                      ? 'Sin conexión. El reporte no se envió; prueba de '
                            'nuevo cuando tengas señal.'
                      : 'No pudimos enviar el reporte. Prueba de nuevo.',
                ),
              )
            else
              const AvisoMarketplace(
                mensaje:
                    'Soporte te responde en 24 horas hábiles. El proveedor '
                    'también ve el reporte y puede responder.',
              ),
          ],
        ),
      ),
    );
  }
}

class _OpcionMotivo extends StatelessWidget {
  const _OpcionMotivo({
    required this.motivo,
    required this.elegido,
    required this.alElegir,
  });

  final MotivoProblema motivo;
  final bool elegido;
  final VoidCallback? alElegir;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final forma = BorderRadius.circular(EspaciadoCampo.l);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegido,
      button: true,
      enabled: alElegir != null,
      label: '${motivo.etiqueta}. ${motivo.ayuda}',
      excludeSemantics: true,
      child: Material(
        color: paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: forma,
          side: BorderSide(
            color: elegido ? paleta.acentoTexto : paleta.borde,
            width: elegido ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('motivo-${motivo.name}'),
          onTap: alElegir == null
              ? null
              : () {
                  HapticaCampo.seleccion();
                  alElegir!();
                },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspaciadoCampo.l,
                vertical: EspaciadoCampo.m,
              ),
              child: Row(
                children: [
                  Icon(
                    elegido
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: elegido ? paleta.acentoTexto : paleta.bordeFuerte,
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(motivo.etiqueta, style: texto.titleSmall),
                        Text(
                          motivo.ayuda,
                          style: texto.bodySmall?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
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

class _Enviado extends StatelessWidget {
  const _Enviado({required this.caso, super.key});

  final ProblemaReportado caso;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspaciadoCampo.xxl),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: EspaciadoCampo.xxxl,
                color: paleta.acentoTexto,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              Text(
                'Recibimos tu reporte',
                style: texto.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                'Caso ${caso.numeroCaso} · ${caso.motivo.etiqueta}',
                style: texto.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                'Soporte te responde en 24 horas hábiles. Mientras tanto, el '
                'servicio queda en revisión.',
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
