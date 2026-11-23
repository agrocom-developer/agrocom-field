import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import 'onboarding_cubit.dart';

class _Paso {
  const _Paso(this.etiqueta, this.titulo, this.detalle, this.imagen);

  final String etiqueta;
  final String titulo;
  final String detalle;
  final String imagen;
}

const _pasos = [
  _Paso(
    'Solicita',
    'Pide tu fumigación en minutos',
    'Marca el lote, elige el producto y la fecha. Ves el precio estimado '
        'antes de confirmar.',
    ImagenesCampo.dronPulverizandoVertical,
  ),
  _Paso(
    'Asignamos',
    'Un piloto verificado lo toma',
    'Ofrecemos tu servicio primero a la flota de Agrocom y después a '
        'pilotos verificados de tu zona.',
    ImagenesCampo.equipoDron,
  ),
  _Paso(
    'Sigue y califica',
    'Mira el vuelo en vivo',
    'Sigue el avance en el mapa, hectárea por hectárea, y califica el '
        'servicio al terminar.',
    ImagenesCampo.dronAgrasT50,
  ),
];

/// Presentación de tres pasos del primer uso. Una idea por paso, una sola
/// acción principal («Continuar», «Empezar» en el último) y «Saltar» como
/// salida secundaria. Se avanza también deslizando.
class OnboardingPantalla extends StatelessWidget {
  const OnboardingPantalla({required this.alTerminar, super.key});

  final VoidCallback alTerminar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(context.read<AccesoRepositorio>()),
      child: BlocConsumer<OnboardingCubit, OnboardingEstado>(
        listenWhen: (antes, ahora) => !antes.terminado && ahora.terminado,
        listener: (context, estado) => alTerminar(),
        builder: (context, estado) => _Vista(paso: estado.paso),
      ),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final ultimo = paso == _pasos.length - 1;

    final saltar = Align(
      alignment: Alignment.centerRight,
      child: Visibility(
        visible: !ultimo,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: TextButton(
          key: const Key('onboarding-saltar'),
          onPressed: cubit.terminar,
          style: TextButton.styleFrom(
            minimumSize: const Size(
              ObjetivoTactilCampo.minimo,
              ObjetivoTactilCampo.minimo,
            ),
            foregroundColor: context.paleta.textoSecundario,
          ),
          child: const Text('Saltar'),
        ),
      ),
    );

    final controles = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Puntos(paso: paso),
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('onboarding-continuar'),
          texto: ultimo ? 'Empezar' : 'Continuar',
          onPressed: cubit.siguiente,
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -200) cubit.siguiente();
            if (v > 200) cubit.anterior();
          },
          child: LayoutBuilder(
            builder: (context, c) {
              final margen = EspaciadoCampo.margenLateral(c.maxWidth);
              if (ClasePantallaCampo.deAncho(c.maxWidth) ==
                  ClasePantallaCampo.expandido) {
                return Padding(
                  padding: const EdgeInsets.all(EspaciadoCampo.xl),
                  child: Row(
                    children: [
                      Expanded(child: _Foto(paso: paso)),
                      const SizedBox(width: EspaciadoCampo.xxxl),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                saltar,
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: _Texto(paso: paso),
                                    ),
                                  ),
                                ),
                                controles,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      margen,
                      EspaciadoCampo.s,
                      margen,
                      EspaciadoCampo.xl,
                    ),
                    child: Column(
                      children: [
                        saltar,
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, area) => SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: (area.maxHeight * 0.56).clamp(
                                      140.0,
                                      460.0,
                                    ),
                                    child: _Foto(paso: paso),
                                  ),
                                  const SizedBox(height: EspaciadoCampo.xl),
                                  _Texto(paso: paso),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: EspaciadoCampo.l),
                        controles,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Foto del paso, con fundido cruzado al cambiar.
class _Foto extends StatelessWidget {
  const _Foto({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaGrande ?? 24;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: AnimatedSwitcher(
        duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
        switchInCurve: MovimientoCampo.entrada,
        switchOutCurve: MovimientoCampo.salida,
        layoutBuilder: (actual, anteriores) =>
            Stack(fit: StackFit.expand, children: [...anteriores, ?actual]),
        child: Image.asset(
          _pasos[paso].imagen,
          key: ValueKey(paso),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Etiqueta, título y detalle del paso. Al cambiar, el texto nuevo entra
/// con opacidad y un desplazamiento corto.
class _Texto extends StatelessWidget {
  const _Texto({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = _pasos[paso];
    final reducido = MovimientoCampo.reducido(context);
    return AnimatedSwitcher(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
      switchInCurve: MovimientoCampo.entrada,
      switchOutCurve: MovimientoCampo.salida,
      transitionBuilder: (child, animacion) => FadeTransition(
        opacity: animacion,
        child: reducido
            ? child
            : SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animacion),
                child: child,
              ),
      ),
      layoutBuilder: (actual, anteriores) => Stack(
        alignment: Alignment.topLeft,
        children: [...anteriores, ?actual],
      ),
      child: Semantics(
        key: ValueKey(paso),
        container: true,
        liveRegion: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paso ${paso + 1} de ${_pasos.length} · ${p.etiqueta}'
                    .toUpperCase(),
                style: texto.labelSmall?.copyWith(color: paleta.acentoTexto),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              Text(p.titulo, style: texto.headlineMedium),
              const SizedBox(height: EspaciadoCampo.m),
              Text(
                p.detalle,
                style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de avance: el paso activo es una pastilla más ancha, así no
/// depende solo del color.
class _Puntos extends StatelessWidget {
  const _Puntos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      label: 'Paso ${paso + 1} de ${_pasos.length}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _pasos.length; i++)
              AnimatedContainer(
                duration: MovimientoCampo.duracion(
                  context,
                  MovimientoCampo.rapida,
                ),
                curve: MovimientoCampo.movimiento,
                margin: const EdgeInsets.symmetric(
                  horizontal: EspaciadoCampo.xs,
                ),
                width: i == paso ? EspaciadoCampo.xl : EspaciadoCampo.s,
                height: EspaciadoCampo.s,
                decoration: BoxDecoration(
                  color: i == paso ? paleta.acentoTexto : paleta.bordeFuerte,
                  borderRadius: BorderRadius.circular(EspaciadoCampo.s),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
