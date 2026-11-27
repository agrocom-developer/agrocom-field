import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../ui/componentes/hoja_inferior_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'flujo_codigo_cubit.dart';
import 'flujo_codigo_vista.dart';

/// Abre la hoja «Verifica tu teléfono». Devuelve `true` si quedó verificado.
/// Es opcional: la persona puede cerrarla («Más tarde») y la app se lo
/// vuelve a ofrecer desde Seguridad mientras no lo verifique.
Future<bool> mostrarVerificarTelefono(BuildContext context) async {
  final repositorio = context.read<CuentaSeguridadRepositorio>();
  final verificado = await mostrarHojaInferiorCampo<bool>(
    context: context,
    builder: (_) => HojaVerificarTelefono(repositorio: repositorio),
  );
  return verificado ?? false;
}

/// Como [mostrarVerificarTelefono], pero no hace nada si la app no tiene el
/// repositorio de seguridad (pruebas y demos mínimas).
Future<bool> ofrecerVerificarTelefono(BuildContext context) async {
  try {
    context.read<CuentaSeguridadRepositorio>();
  } on ProviderNotFoundException {
    return false;
  }
  return mostrarVerificarTelefono(context);
}

class HojaVerificarTelefono extends StatelessWidget {
  const HojaVerificarTelefono({required this.repositorio, super.key});

  final CuentaSeguridadRepositorio repositorio;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FlujoCodigoCubit(
        canales: CanalCodigo.paraTelefono,
        pedir: repositorio.pedirCodigoTelefono,
        confirmar: (codigo, _) async {
          await repositorio.confirmarTelefono(codigo);
          return null;
        },
      ),
      child: BlocBuilder<FlujoCodigoCubit, FlujoCodigoEstado>(
        builder: (context, estado) {
          final alto = MediaQuery.sizeOf(context).height * 0.85;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: alto),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: estado.etapa == EtapaCodigo.listo
                  ? const _Verificado()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FlujoCodigoVista(
                          tituloElegir: 'Verifica tu teléfono',
                          detalleElegir:
                              'Así sabemos que el número es tuyo y podemos '
                              'ayudarte a recuperar tu cuenta.',
                          textoConfirmar: 'Verificar',
                        ),
                        const SizedBox(height: EspaciadoCampo.s),
                        TextButton(
                          key: const Key('verificar-mas-tarde'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              ObjetivoTactilCampo.minimo,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Más tarde'),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Verificado extends StatelessWidget {
  const _Verificado();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.verified_outlined, size: 48, color: paleta.exito),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            'Tu teléfono quedó verificado',
            style: texto.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        BotonPrincipalMarketplace(
          key: const Key('telefono-listo'),
          texto: 'Listo',
          alto: ObjetivoTactilCampo.guantes,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
