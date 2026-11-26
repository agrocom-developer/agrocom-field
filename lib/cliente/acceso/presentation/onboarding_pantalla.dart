import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/logo_agrocom_campo.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import 'onboarding_cubit.dart';

/// Tiempo que se queda cada portada antes de avanzar sola.
const Duration _intervaloAutoavance = Duration(milliseconds: 3500);

/// Ancho máximo del bloque de texto y controles en pantallas amplias (iPad):
/// la foto ocupa todo el ancho, el texto queda en una columna legible.
const double _anchoMaximoTexto = 560;

/// Color del texto sobre la foto. No sale de la paleta del tema porque la
/// foto es oscura en la parte baja en claro y en oscuro; el degradado
/// ([_Pagina]) garantiza el contraste.
const Color _textoSobreFoto = Color(0xFFFFFFFF);
const Color _textoSecundarioSobreFoto = Color(0xFFE6EBE7);

class _Portada {
  const _Portada(this.titulo, this.detalle, this.foto, this.fotoAncha);

  final String Function(AppLocalizations l10n) titulo;
  final String Function(AppLocalizations l10n) detalle;

  /// Foto en teléfono vertical y foto en pantalla ancha (iPad, horizontal).
  final String foto;
  final String fotoAncha;
}

final _portadas = <_Portada>[
  _Portada(
    (l10n) => l10n.accesoPortadaPublicaTitulo,
    (l10n) => l10n.accesoPortadaPublicaDetalle,
    ImagenesCampo.dronPulverizandoVertical,
    ImagenesCampo.dronPulverizando,
  ),
  _Portada(
    (l10n) => l10n.accesoPortadaNegociaTitulo,
    (l10n) => l10n.accesoPortadaNegociaDetalle,
    ImagenesCampo.dronAgrasT50,
    ImagenesCampo.dronAgrasT50,
  ),
  _Portada(
    (l10n) => l10n.accesoPortadaPagasTitulo,
    (l10n) => l10n.accesoPortadaPagasDetalle,
    ImagenesCampo.equipoDron,
    ImagenesCampo.equipoDron,
  ),
];

/// Portadas del primer uso: carrusel de tres pantallas que avanza solo cada
/// 3,5 s. Se pausa mientras la persona toca o arrastra, se puede deslizar o
/// tocar un punto, y con «reducir movimiento» no avanza solo.
///
/// «Comenzar» lleva al registro ([alComenzar]; si es nulo, a [alTerminar]);
/// «Ya tengo cuenta» y «Saltar» llevan al ingreso ([alTerminar]).
class OnboardingPantalla extends StatefulWidget {
  const OnboardingPantalla({
    required this.alTerminar,
    this.alComenzar,
    super.key,
  });

  final VoidCallback alTerminar;
  final VoidCallback? alComenzar;

  @override
  State<OnboardingPantalla> createState() => _OnboardingPantallaState();
}

class _OnboardingPantallaState extends State<OnboardingPantalla> {
  bool _haciaRegistro = false;

  void _terminar(OnboardingCubit cubit, {required bool registro}) {
    _haciaRegistro = registro;
    cubit.terminar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(context.read<AccesoRepositorio>()),
      child: BlocListener<OnboardingCubit, OnboardingEstado>(
        listenWhen: (antes, ahora) => !antes.terminado && ahora.terminado,
        listener: (context, estado) {
          final comenzar = widget.alComenzar;
          if (_haciaRegistro && comenzar != null) {
            comenzar();
          } else {
            widget.alTerminar();
          }
        },
        child: Builder(
          builder: (context) => _Vista(
            alComenzar: () =>
                _terminar(context.read<OnboardingCubit>(), registro: true),
            alTenerCuenta: () =>
                _terminar(context.read<OnboardingCubit>(), registro: false),
          ),
        ),
      ),
    );
  }
}

class _Vista extends StatefulWidget {
  const _Vista({required this.alComenzar, required this.alTenerCuenta});

  final VoidCallback alComenzar;
  final VoidCallback alTenerCuenta;

  @override
  State<_Vista> createState() => _VistaState();
}

class _VistaState extends State<_Vista> {
  final _controlador = PageController();
  Timer? _reloj;
  bool _pausado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con «reducir movimiento» el carrusel solo cambia por la persona.
    if (MovimientoCampo.reducido(context)) {
      _reloj?.cancel();
      _reloj = null;
    } else {
      _reloj ??= Timer.periodic(_intervaloAutoavance, (_) => _avanzar());
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _avanzar() {
    if (!mounted || _pausado || !_controlador.hasClients) return;
    final siguiente =
        (context.read<OnboardingCubit>().state.paso + 1) %
        OnboardingCubit.pasos;
    _ir(siguiente);
  }

  void _ir(int indice) {
    if (!_controlador.hasClients) return;
    final duracion = MovimientoCampo.duracion(
      context,
      MovimientoCampo.lenta * 2,
    );
    if (duracion == Duration.zero) {
      _controlador.jumpToPage(indice);
    } else {
      _controlador.animateToPage(
        indice,
        duration: duracion,
        curve: MovimientoCampo.entrada,
      );
    }
  }

  /// Tocar un punto salta a esa portada y reinicia la cuenta de 3,5 s.
  void _irPorPunto(int indice) {
    _reiniciarReloj();
    _ir(indice);
  }

  void _reiniciarReloj() {
    if (_reloj == null) return;
    _reloj!.cancel();
    _reloj = Timer.periodic(_intervaloAutoavance, (_) => _avanzar());
  }

  void _pausar(bool valor) {
    _pausado = valor;
    if (!valor) _reiniciarReloj();
  }

  final _clave = GlobalKey();
  double _altoControles = 0;

  /// Mide los controles para que el texto de cada portada quede justo encima,
  /// también con letra grande.
  void _medirControles() {
    final caja = _clave.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.hasSize) return;
    if ((caja.size.height - _altoControles).abs() > 0.5) {
      setState(() => _altoControles = caja.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OnboardingCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _medirControles();
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Íconos claros de la barra de estado: la foto es oscura arriba.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: LayoutBuilder(
          builder: (context, c) {
            final ancho = ClasePantallaCampo.deAncho(c.maxWidth);
            final amplia = ancho != ClasePantallaCampo.compacto;
            final margen = EspaciadoCampo.margenLateral(c.maxWidth);
            final lateral = amplia
                ? ((c.maxWidth - _anchoMaximoTexto) / 2).clamp(
                    margen,
                    c.maxWidth,
                  )
                : margen;
            final carrusel = Listener(
              onPointerDown: (_) => _pausar(true),
              onPointerUp: (_) => _pausar(false),
              onPointerCancel: (_) => _pausar(false),
              child: PageView.builder(
                controller: _controlador,
                itemCount: _portadas.length,
                onPageChanged: cubit.irA,
                itemBuilder: (context, i) => _Pagina(
                  portada: _portadas[i],
                  ancha: c.maxWidth > c.maxHeight,
                  lateral: lateral,
                  reservaInferior: _altoControles,
                ),
              ),
            );
            final controles = Padding(
              key: _clave,
              padding: EdgeInsets.fromLTRB(
                lateral,
                EspaciadoCampo.s,
                lateral,
                EspaciadoCampo.s,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BlocBuilder<OnboardingCubit, OnboardingEstado>(
                      buildWhen: (a, b) => a.paso != b.paso,
                      builder: (context, estado) =>
                          _Puntos(paso: estado.paso, alElegir: _irPorPunto),
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  BotonPrincipalMarketplace(
                    key: const Key('onboarding-continuar'),
                    texto: l10n.accesoComenzar,
                    onPressed: widget.alComenzar,
                  ),
                  const SizedBox(height: EspaciadoCampo.xs),
                  TextButton(
                    key: const Key('onboarding-tengo-cuenta'),
                    onPressed: widget.alTenerCuenta,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        ObjetivoTactilCampo.minimo,
                      ),
                      foregroundColor: _textoSobreFoto,
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                    child: Text(l10n.accesoTengoCuenta),
                  ),
                ],
              ),
            );
            return Stack(
              children: [
                Positioned.fill(child: carrusel),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(top: false, child: controles),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        lateral,
                        margen,
                        margen,
                        margen,
                      ),
                      child: const _SelloAgrocom(),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        margen,
                        margen,
                        lateral,
                        margen,
                      ),
                      child: _PastillaSaltar(
                        alTocar: () =>
                            context.read<OnboardingCubit>().terminar(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una portada: la foto completa a sangre y, encima, título y texto sobre un
/// degradado que solo oscurece la parte baja. Si el texto no cabe (letra
/// grande), esa parte se desplaza.
class _Pagina extends StatelessWidget {
  const _Pagina({
    required this.portada,
    required this.ancha,
    required this.lateral,
    required this.reservaInferior,
  });

  final _Portada portada;
  final bool ancha;
  final double lateral;

  /// Alto de los controles fijos que quedan debajo del texto.
  final double reservaInferior;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final inferior = MediaQuery.paddingOf(context).bottom;
    final superior = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          ancha ? portada.fotoAncha : portada.foto,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          excludeFromSemantics: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.42, 0.78, 1.0],
              colors: [
                Color(0x00_050A06),
                Color(0x00_050A06),
                Color(0xB3_050A06),
                Color(0xE6_050A06),
              ],
            ),
          ),
        ),
        Padding(
          // El texto nunca sube debajo del sello ni de «Saltar».
          padding: EdgeInsets.only(
            top: superior + ObjetivoTactilCampo.minimo + EspaciadoCampo.l * 2,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SingleChildScrollView(
              reverse: true,
              child: DecoratedBox(
                // Degradado propio del texto: crece con él (letra grande).
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 1.0],
                    colors: [
                      Color(0x00_050A06),
                      Color(0x99_050A06),
                      Color(0xCC_050A06),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    lateral,
                    ObjetivoTactilCampo.minimo,
                    lateral,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portada.titulo(l10n),
                        style: texto.headlineMedium?.copyWith(
                          color: _textoSobreFoto,
                        ),
                      ),
                      const SizedBox(height: EspaciadoCampo.m),
                      Text(
                        portada.detalle(l10n),
                        style: texto.bodyLarge?.copyWith(
                          color: _textoSecundarioSobreFoto,
                        ),
                      ),
                      // Espacio de los controles: el degradado llega hasta
                      // el borde inferior sin cortes.
                      SizedBox(
                        height: reservaInferior + inferior + EspaciadoCampo.l,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// El logo de Agrocom sobre la foto (imagen, no texto), con su sombra.
class _SelloAgrocom extends StatelessWidget {
  const _SelloAgrocom();

  @override
  Widget build(BuildContext context) {
    // Píldora clara: el verde del logo se pierde sobre el follaje.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(RadioCampo.media),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.xs,
        ),
        child: LogoAgrocomCampo(ancho: 96, sombra: false),
      ),
    );
  }
}

class _PastillaSaltar extends StatelessWidget {
  const _PastillaSaltar({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Material(
      color: paleta.superficie,
      shape: const StadiumBorder(),
      child: InkWell(
        key: const Key('onboarding-saltar'),
        customBorder: const StadiumBorder(),
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ObjetivoTactilCampo.minimo,
            minHeight: ObjetivoTactilCampo.minimo,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
            child: Center(
              widthFactor: 1,
              child: Text(
                l10n.accesoSaltar,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: paleta.texto),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puntos del carrusel: el activo es una píldora más ancha (no depende solo
/// del color) y cada uno se puede tocar con un objetivo de 48 dp.
class _Puntos extends StatelessWidget {
  const _Puntos({required this.paso, required this.alElegir});

  final int paso;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _portadas.length; i++)
          Semantics(
            button: true,
            selected: i == paso,
            label: l10n.accesoPortada(i + 1, _portadas.length),
            excludeSemantics: true,
            child: InkResponse(
              key: Key('onboarding-punto-$i'),
              onTap: () => alElegir(i),
              radius: ObjetivoTactilCampo.minimo / 2,
              child: SizedBox(
                width: ObjetivoTactilCampo.minimo / 1.5,
                height: ObjetivoTactilCampo.minimo,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: MovimientoCampo.duracion(
                      context,
                      MovimientoCampo.rapida,
                    ),
                    curve: MovimientoCampo.movimiento,
                    width: i == paso ? EspaciadoCampo.xl : EspaciadoCampo.s,
                    height: EspaciadoCampo.s,
                    decoration: BoxDecoration(
                      color: i == paso
                          ? _textoSobreFoto
                          : const Color(0x80FFFFFF),
                      borderRadius: BorderRadius.circular(EspaciadoCampo.s),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
