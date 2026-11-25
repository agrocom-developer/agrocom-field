import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/tema_campo.dart';
import '../../../../camara/selector_imagen.dart';
import '../../di/dependencias_proveedor.dart';
import '../domain/acceso_proveedor.dart';
import 'acceso_cubit.dart';
import 'acceso_pantallas.dart';

/// La app real de `piloto`: la puerta de acceso y, con
/// sesión, la superficie que arma [construirShell]. Los repositorios van por
/// encima del `Navigator` para que las rutas apiladas los hereden.
class AppProveedor extends StatelessWidget {
  const AppProveedor({
    required this.proveedor,
    required this.acceso,
    required this.selectorImagen,
    required this.construirShell,
    this.permiteRegistro = true,
    super.key,
  });

  final DependenciasProveedor proveedor;
  final DependenciasAccesoProveedor acceso;
  final SelectorImagen selectorImagen;
  final bool permiteRegistro;

  /// Arma la navegación del flavor; recibe cómo cerrar la sesión.
  final Widget Function(BuildContext, VoidCallback alSalir) construirShell;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AccesoProveedorRepositorio>.value(
          value: acceso.acceso,
        ),
        RepositoryProvider<RegistroDronesRepositorio>.value(
          value: acceso.registroDrones,
        ),
        RepositoryProvider<SelectorImagen>.value(value: selectorImagen),
      ],
      child: BlocProvider(
        create: (_) =>
            AccesoCubit(acceso.acceso, sesionExpirada: acceso.sesionExpirada)
              ..iniciar(),
        child: MaterialApp(
          title: 'Agrocom',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          debugShowCheckedModeBanner: false,
          theme: AgrocomThemeCampo.construir(),
          builder: (context, child) => proveedor.proveer(child: child!),
          home: Builder(
            builder: (context) => PuertaAcceso(
              permiteRegistro: permiteRegistro,
              nota: acceso.nota,
              construir: (context, sesion) => construirShell(
                context,
                () => context.read<AccesoCubit>().salir(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
