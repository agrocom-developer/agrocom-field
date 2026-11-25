import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import 'onboarding_cubit.dart';

/// Tiempo que se queda cada portada antes de avanzar sola.
const Duration _intervaloAutoavance = Duration(milliseconds: 3500);

/// Alto máximo del collage en teléfono; en pantallas bajas toma casi la
/// mitad del alto disponible.
const double _altoColageMaximo = 400;
const double _fraccionColage = 0.5;

class _Portada {
  const _Portada(this.titulo, this.detalle, this.colage);

  final String Function(AppLocalizations l10n) titulo;
  final String Function(AppLocalizations l10n) detalle;
  final Widget Function(BuildContext context, double radio) colage;
}

final _portadas = <_Portada>[
  _Portada(
    (l10n) => l10n.accesoPortadaPublicaTitulo,
    (l10n) => l10n.accesoPortadaPublicaDetalle,
    _colagePublica,
  ),
  _Portada(
    (l10n) => l10n.accesoPortadaNegociaTitulo,
    (l10n) => l10n.accesoPortadaNegociaDetalle,
    _colageNegocia,
  ),
  _Portada(
    (l10n) => l10n.accesoPortadaPagasTitulo,
    (l10n) => l10n.accesoPortadaPagasDetalle,
    _colagePrecioFinal,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OnboardingCubit>();
    final paleta = context.paleta;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final ancho = ClasePantallaCampo.deAncho(c.maxWidth);
          final amplia = ancho != ClasePantallaCampo.compacto;
          final margen = EspaciadoCampo.margenLateral(c.maxWidth);
          final carrusel = Listener(
            onPointerDown: (_) => _pausar(true),
            onPointerUp: (_) => _pausar(false),
            onPointerCancel: (_) => _pausar(false),
            child: PageView.builder(
              controller: _controlador,
              itemCount: _portadas.length,
              onPageChanged: cubit.irA,
              itemBuilder: (context, i) =>
                  _Pagina(portada: _portadas[i], amplia: amplia),
            ),
          );
          final controles = Padding(
            padding: EdgeInsets.fromLTRB(
              margen,
              EspaciadoCampo.s,
              margen,
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
                    foregroundColor: paleta.acentoTexto,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  child: Text(l10n.accesoTengoCuenta),
                ),
              ],
            ),
          );
          final saltar = Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(margen),
                child: _PastillaSaltar(
                  alTocar: () => context.read<OnboardingCubit>().terminar(),
                ),
              ),
            ),
          );
          final contenido = Stack(
            children: [
              Column(
                children: [
                  Expanded(child: carrusel),
                  SafeArea(top: false, child: controles),
                ],
              ),
              saltar,
            ],
          );
          if (!amplia) return contenido;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: contenido,
            ),
          );
        },
      ),
    );
  }
}

/// Una portada: collage arriba (con la marca) y, debajo, título y texto. Si
/// el texto no cabe (letra grande), esa parte se desplaza.
class _Pagina extends StatelessWidget {
  const _Pagina({required this.portada, required this.amplia});

  final _Portada portada;
  final bool amplia;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final margen = EspaciadoCampo.margenLateral(c.maxWidth);
        final alto = (c.maxHeight * _fraccionColage).clamp(
          0.0,
          _altoColageMaximo,
        );
        final radio = RadioCampo.hoja;
        final colage = ClipRRect(
          borderRadius: amplia
              ? BorderRadius.circular(radio)
              : BorderRadius.vertical(bottom: Radius.circular(radio)),
          child: SizedBox(
            height: alto,
            width: double.infinity,
            child: portada.colage(context, RadioCampo.tarjetaCompacta),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: amplia
                  ? const EdgeInsets.only(top: EspaciadoCampo.xl)
                  : EdgeInsets.zero,
              child: Stack(
                children: [
                  colage,
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(margen),
                        child: const _SelloAgrocom(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  margen,
                  EspaciadoCampo.xl,
                  margen,
                  EspaciadoCampo.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(portada.titulo(l10n), style: texto.headlineMedium),
                    const SizedBox(height: EspaciadoCampo.m),
                    Text(
                      portada.detalle(l10n),
                      style: texto.bodyLarge?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// «AGROCOM» en mono sobre píldora clara: la marca sobre la foto.
class _SelloAgrocom extends StatelessWidget {
  const _SelloAgrocom();

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      label: 'Agrocom',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paleta.superficie,
          borderRadius: BorderRadius.circular(RadioCampo.media),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EspaciadoCampo.m,
            vertical: EspaciadoCampo.s,
          ),
          child: Text(
            'AGROCOM',
            style: TipografiaCampo.etiquetaMono.copyWith(color: paleta.texto),
          ),
        ),
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
    final paleta = context.paleta;
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
                      color: i == paso ? paleta.acento : paleta.borde,
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

// --- Collages ---------------------------------------------------------------

const double _separacion = EspaciadoCampo.xs;

/// 1 · Foto grande con precios sobre ella, foto del dron y bloque ámbar.
Widget _colagePublica(BuildContext context, double radio) {
  final l10n = AppLocalizations.of(context);
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: FotoColageCampo(
          imagen: ImagenesCampo.dronAgrasT50,
          radio: 0,
          child: const Stack(
            children: [
              Align(
                alignment: Alignment(-0.1, 0.1),
                child: PastillaPrecioCampo(valor: '62', destacada: true),
              ),
              Align(
                alignment: Alignment(0.3, 0.75),
                child: PastillaPrecioCampo(valor: '55'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: _separacion),
      Expanded(
        child: Column(
          children: [
            Expanded(
              child: FotoColageCampo(
                imagen: ImagenesCampo.dronPulverizandoVertical,
                radio: 0,
              ),
            ),
            const SizedBox(height: _separacion),
            Expanded(
              child: BloqueAmbarCampo(
                titulo: '120',
                etiqueta: l10n.accesoHectareasPublicadas,
                radio: 0,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// 2 · Foto a sangre con las ofertas y la barra de rondas.
Widget _colageNegocia(BuildContext context, double radio) {
  const sobreFoto = PaletaCampo.campo;
  return FondoFotoCampo(
    imagen: ImagenesCampo.dronPulverizandoVertical,
    alineacion: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PastillaPrecioCampo(valor: '62'),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          const Align(
            alignment: Alignment.centerRight,
            child: PastillaPrecioCampo(valor: '68', destacada: true),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          const Align(
            alignment: Alignment.centerLeft,
            child: PastillaPrecioCampo(valor: '65'),
          ),
          const SizedBox(height: EspaciadoCampo.l),
          RondasColageCampo(hechas: 3, total: 5, colorTexto: sobreFoto.texto),
        ],
      ),
    ),
  );
}

/// 3 · Foto, post-it con el precio final y foto del dron en tierra.
Widget _colagePrecioFinal(BuildContext context, double radio) {
  final l10n = AppLocalizations.of(context);
  final paleta = context.paleta;
  return Column(
    children: [
      Expanded(
        flex: 5,
        child: FotoColageCampo(
          imagen: ImagenesCampo.dronPulverizando,
          radio: 0,
        ),
      ),
      const SizedBox(height: _separacion),
      Expanded(
        flex: 4,
        child: Row(
          children: [
            Expanded(
              child: ColoredBox(
                color: paleta.ambarContenedor,
                child: Padding(
                  padding: EdgeInsets.all(EspaciadoCampo.m),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: PostItCampo(
                      etiqueta: l10n.accesoPrecioFinal,
                      cuenta: l10n.acceso118,
                      total: l10n.acceso552,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _separacion),
            Expanded(
              child: FotoColageCampo(
                imagen: ImagenesCampo.equipoDron,
                radio: 0,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
