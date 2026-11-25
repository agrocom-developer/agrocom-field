import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/ui/estado_vacio_marketplace.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import 'arranque_cubit.dart';
import 'login_cliente_pantalla.dart';
import 'onboarding_pantalla.dart';
import 'registro_cliente_pantalla.dart';
import 'splash_pantalla.dart';

/// Raíz del flavor cliente: decide entre splash, presentación, acceso y la
/// navegación principal según `ArranqueCubit`, y funde una etapa con la
/// siguiente. [dentro] construye lo que ve una persona con sesión.
///
/// Ingreso y registro se alternan aquí, no con rutas apiladas: al iniciar
/// sesión no queda ninguna pantalla de acceso debajo de la navegación.
class PuertaAccesoCliente extends StatefulWidget {
  const PuertaAccesoCliente({
    required this.dentro,
    this.notaAcceso,
    this.sesionExpirada,
    super.key,
  });

  final WidgetBuilder dentro;
  final String? notaAcceso;

  /// Avisa cuando el servidor rechaza el token: la puerta vuelve al ingreso
  /// con un mensaje que lo explica.
  final Stream<void>? sesionExpirada;

  @override
  State<PuertaAccesoCliente> createState() => _PuertaAccesoClienteState();
}

class _PuertaAccesoClienteState extends State<PuertaAccesoCliente> {
  late final ArranqueCubit _arranque = ArranqueCubit(
    context.read<AccesoRepositorio>(),
  );
  bool _splashLista = false;
  bool _registro = false;
  bool _vencida = false;
  StreamSubscription<void>? _expiracion;

  @override
  void initState() {
    super.initState();
    _arranque.resolver();
    _expiracion = widget.sesionExpirada?.listen((_) {
      if (!mounted) return;
      setState(() {
        _vencida = true;
        _registro = false;
      });
      _arranque.sesionVencida();
    });
  }

  @override
  void dispose() {
    _expiracion?.cancel();
    _arranque.close();
    super.dispose();
  }

  void _entrar(SesionCliente sesion) {
    setState(() {
      _registro = false;
      _vencida = false;
    });
    _arranque.sesionIniciada(sesion);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _arranque,
      child: BlocBuilder<ArranqueCubit, ArranqueEstado>(
        builder: (context, estado) {
          final etapa = _splashLista ? estado.etapa : EtapaArranque.resolviendo;
          final (clave, pantalla) = switch (etapa) {
            EtapaArranque.resolviendo => (
              'splash',
              SplashPantalla(
                alTerminar: () => setState(() => _splashLista = true),
              ),
            ),
            EtapaArranque.error => (
              'error',
              _ErrorArranque(alReintentar: _arranque.resolver),
            ),
            EtapaArranque.onboarding => (
              'onboarding',
              OnboardingPantalla(
                alTerminar: _arranque.onboardingTerminado,
                // «Comenzar» abre el registro; «Ya tengo cuenta», el ingreso.
                alComenzar: () {
                  setState(() => _registro = true);
                  _arranque.onboardingTerminado();
                },
              ),
            ),
            EtapaArranque.acceso when _registro => (
              'registro',
              RegistroClientePantalla(
                alEntrar: _entrar,
                alVolver: () => setState(() => _registro = false),
              ),
            ),
            EtapaArranque.acceso => (
              'login',
              LoginClientePantalla(
                alEntrar: _entrar,
                alCrearCuenta: () => setState(() => _registro = true),
                nota: _vencida
                    ? AppLocalizations.of(context).accesoSesionVencioEntraNuevo
                    : widget.notaAcceso,
              ),
            ),
            EtapaArranque.dentro => ('dentro', widget.dentro(context)),
          };
          return AnimatedSwitcher(
            duration: MovimientoCampo.duracion(context, MovimientoCampo.lenta),
            switchInCurve: MovimientoCampo.entrada,
            switchOutCurve: MovimientoCampo.salida,
            layoutBuilder: (actual, anteriores) =>
                Stack(fit: StackFit.expand, children: [...anteriores, ?actual]),
            child: KeyedSubtree(key: ValueKey(clave), child: pantalla),
          );
        },
      ),
    );
  }
}

class _ErrorArranque extends StatelessWidget {
  const _ErrorArranque({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EstadoVacioMarketplace(
                  icono: Icons.error_outline_rounded,
                  titulo: l10n.accesoPudimosAbrirSesion,
                  detalle: l10n.accesoIntentaNuevoMomento,
                ),
                OutlinedButton.icon(
                  onPressed: alReintentar,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.accesoReintentar),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
