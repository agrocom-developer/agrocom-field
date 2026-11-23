import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/sesion_vuelo/presentation/fabricas_sesion_vuelo.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Abre la sesión de vuelo del servicio [servicio] con las factories que la
/// app provee sobre el `Navigator`. El `id` del servicio es el
/// `uuid_cliente` del trabajo.
void abrirSesionDeVuelo(BuildContext context, Servicio servicio) {
  HapticaCampo.seleccion();
  final fabricas = context.read<FabricasSesionVuelo>();
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => fabricas.pantalla(servicio.id)),
  );
}
