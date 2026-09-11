import 'package:flutter/material.dart';

import 'features/auth/login_cubit.dart';
import 'features/auth/login_pantalla.dart';
import 'nucleo/auth/token_store.dart';
import 'nucleo/flavor.dart';
import 'nucleo/ui/tema.dart';

/// App raíz de Agrocom Field.
///
/// Se instancia desde main_piloto.dart o main_auxiliar.dart según el flavor.
class AgrocomApp extends StatelessWidget {
  final Flavor flavor;
  final TokenStore tokenStore;
  final LoginCubit Function() crearLoginCubit;

  const AgrocomApp({
    required this.flavor,
    required this.tokenStore,
    required this.crearLoginCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom Field',
      theme: AgrocomTheme.light(),
      darkTheme: AgrocomTheme.dark(),
      themeMode: ThemeMode.system,
      home: _RaizApp(
        flavor: flavor,
        tokenStore: tokenStore,
        crearLoginCubit: crearLoginCubit,
      ),
    );
  }
}

/// Decide, al arrancar, si hay que pedir login (`TokenStore.leerToken()` ==
/// null) o ir directo al placeholder — HU-03 solo cubre esa bifurcación,
/// nunca decide una pantalla "home" nueva (eso es HU-04/HU-05).
class _RaizApp extends StatefulWidget {
  const _RaizApp({
    required this.flavor,
    required this.tokenStore,
    required this.crearLoginCubit,
  });

  final Flavor flavor;
  final TokenStore tokenStore;
  final LoginCubit Function() crearLoginCubit;

  @override
  State<_RaizApp> createState() => _RaizAppState();
}

class _RaizAppState extends State<_RaizApp> {
  late Future<String?> _tokenInicial;
  bool _ingresoExitoso = false;

  @override
  void initState() {
    super.initState();
    _tokenInicial = widget.tokenStore.leerToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null && !_ingresoExitoso) {
          return LoginPantalla(
            crearCubit: widget.crearLoginCubit,
            onIngresoExitoso: () => setState(() => _ingresoExitoso = true),
          );
        }

        return Scaffold(
          body: Center(child: Text('agrocom-field — ${widget.flavor.name}')),
        );
      },
    );
  }
}
