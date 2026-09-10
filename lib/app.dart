import 'package:flutter/material.dart';

import 'nucleo/flavor.dart';
import 'nucleo/ui/tema.dart';

/// App raíz de Agrocom Field.
///
/// Se instancia desde main_piloto.dart o main_auxiliar.dart según el flavor.
class AgrocomApp extends StatelessWidget {
  final Flavor flavor;

  const AgrocomApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrocom Field',
      theme: AgrocomTheme.light(),
      darkTheme: AgrocomTheme.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Center(child: Text('agrocom-field — ${flavor.name}')),
      ),
    );
  }
}
