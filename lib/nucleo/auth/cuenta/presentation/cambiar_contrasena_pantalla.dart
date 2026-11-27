import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'flujo_codigo_cubit.dart';
import 'flujo_codigo_vista.dart';

/// Cambiar la contraseña con la sesión abierta: el código llega por el medio
/// que la persona elige y prueba que la cuenta es suya (no se pide la
/// contraseña actual). Los demás dispositivos quedan sin sesión.
class CambiarContrasenaPantalla extends StatelessWidget {
  const CambiarContrasenaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final repositorio = context.read<CuentaSeguridadRepositorio>();
    return BlocProvider(
      create: (_) => FlujoCodigoCubit(
        pedir: (canal) => repositorio.pedirCodigoContrasena(canal),
        confirmar: (codigo, contrasena) async {
          await repositorio.cambiarContrasena(
            codigo: codigo,
            contrasenaNueva: contrasena ?? '',
          );
          return null;
        },
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Cambiar contraseña')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BlocBuilder<FlujoCodigoCubit, FlujoCodigoEstado>(
                builder: (context, estado) => ListView(
                  padding: const EdgeInsets.all(EspaciadoCampo.l),
                  children: [
                    if (estado.etapa == EtapaCodigo.listo)
                      const _Exito()
                    else
                      const FlujoCodigoVista(
                        tituloElegir: 'Confirma que eres tú',
                        detalleElegir:
                            'Te enviamos un código de 6 dígitos. Elige por '
                            'dónde lo quieres recibir.',
                        textoConfirmar: 'Cambiar contraseña',
                        pideContrasenaNueva: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Exito extends StatelessWidget {
  const _Exito();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: paleta.exito,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            'Tu contraseña se cambió',
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          'Tus otros dispositivos deberán iniciar sesión de nuevo. Este '
          'sigue con la sesión abierta.',
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('contrasena-listo'),
          texto: 'Listo',
          alto: ObjetivoTactilCampo.guantes,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
