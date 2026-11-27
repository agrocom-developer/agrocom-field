import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/ui/aviso_marketplace.dart';
import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../marketplace/ui/estado_error_marketplace.dart';
import '../../../marketplace/ui/formato_marketplace.dart';
import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'eliminar_cuenta_cubit.dart';
import 'eliminar_cuenta_pantalla.dart';
import 'flujo_codigo_vista.dart';
import 'textos_cuenta_seguridad.dart';

/// Lo único que ve una sesión con la cuenta en eliminación (`403
/// cuenta_en_eliminacion` en todo lo demás): cuánto falta, «Conservar mi
/// cuenta» y cerrar sesión. [alConservada] devuelve a la app con la cuenta
/// operando de nuevo.
class CuentaEnEliminacionPantalla extends StatelessWidget {
  const CuentaEnEliminacionPantalla({
    required this.alConservada,
    required this.alCerrarSesion,
    this.ahora,
    super.key,
  });

  final VoidCallback alConservada;
  final VoidCallback alCerrarSesion;

  /// Reloj inyectable para las pruebas.
  final DateTime Function()? ahora;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EliminarCuentaCubit(context.read<CuentaSeguridadRepositorio>())
            ..cargar(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BlocBuilder<EliminarCuentaCubit, EliminarCuentaEstado>(
                builder: (context, estado) => _contenido(context, estado),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, EliminarCuentaEstado estado) {
    final cubit = context.read<EliminarCuentaCubit>();
    switch (estado.etapa) {
      case EtapaEliminar.cargando:
        return const Padding(
          padding: EdgeInsets.all(EspaciadoCampo.l),
          child: EsqueletoCampo(alto: 200),
        );
      case EtapaEliminar.error:
        final falla = estado.falla ?? const CuentaErrorDesconocido();
        return EstadoErrorMarketplace(
          titulo: 'No pudimos revisar tu cuenta',
          detalle: TextosCuentaSeguridad.falla(falla),
          sinConexion: falla is CuentaSinConexion,
          onReintentar: cubit.cargar,
          etiquetaSecundaria: 'Cerrar sesión',
          onSecundaria: alCerrarSesion,
        );
      case EtapaEliminar.conservada:
        return Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          child: VistaCuentaConservada(alListo: alConservada),
        );
      case EtapaEliminar.solicitada:
      case EtapaEliminar.listo:
      case EtapaEliminar.enviando:
        return _Estado(
          eliminacion: estado.consulta?.eliminacion,
          enviando: estado.etapa == EtapaEliminar.enviando,
          falla: estado.falla,
          ahora: (ahora ?? DateTime.now)(),
          alConservar: cubit.conservar,
          alContinuar: alConservada,
          alCerrarSesion: alCerrarSesion,
        );
    }
  }
}

class _Estado extends StatelessWidget {
  const _Estado({
    required this.eliminacion,
    required this.enviando,
    required this.falla,
    required this.ahora,
    required this.alConservar,
    required this.alContinuar,
    required this.alCerrarSesion,
  });

  final EliminacionCuenta? eliminacion;
  final bool enviando;
  final CuentaFalla? falla;
  final DateTime ahora;
  final VoidCallback alConservar;
  final VoidCallback alContinuar;
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final vigente = eliminacion?.vigente ?? false;
    final e = eliminacion;
    final String detalle;
    if (!vigente || e == null) {
      detalle = 'Tu cuenta ya no está en proceso de eliminación.';
    } else if (e.estado == EstadoEliminacion.pospuesta) {
      detalle =
          'Tu plazo ya terminó, pero algo pendiente frena la eliminación. '
          'Se reintenta cada día. Mientras tanto puedes conservar tu cuenta.';
    } else {
      final dias = e.diasRestantes(ahora);
      final hasta = FormatoMarketplace.fechaLarga(e.ejecutarDesde.toLocal());
      detalle =
          'Se borrará el $hasta (${dias == 1 ? 'queda 1 día' : 'quedan $dias días'}). '
          'Hasta entonces puedes arrepentirte.';
    }
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      shrinkWrap: true,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.schedule_rounded,
            size: 56,
            color: paleta.acentoTexto,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          header: true,
          child: Text(
            vigente ? 'Tu cuenta se está eliminando' : 'Tu cuenta sigue activa',
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Text(
          detalle,
          key: const Key('eliminacion-detalle'),
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          textAlign: TextAlign.center,
        ),
        if (vigente) ...[
          const SizedBox(height: EspaciadoCampo.l),
          const AvisoMarketplace(
            mensaje:
                'Mientras tanto no puedes usar la app. Si conservas tu '
                'cuenta, las solicitudes y ofertas que se cancelaron al '
                'pedir la eliminación no se restauran.',
          ),
        ],
        if (falla != null) ...[
          const SizedBox(height: EspaciadoCampo.l),
          AvisoFallaCuenta(falla: falla!),
        ],
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('eliminacion-conservar'),
          texto: vigente ? 'Conservar mi cuenta' : 'Continuar',
          alto: ObjetivoTactilCampo.guantes,
          cargando: enviando,
          onPressed: vigente ? alConservar : alContinuar,
        ),
        const SizedBox(height: EspaciadoCampo.s),
        TextButton(
          key: const Key('eliminacion-cerrar-sesion'),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
          ),
          onPressed: enviando ? null : alCerrarSesion,
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
