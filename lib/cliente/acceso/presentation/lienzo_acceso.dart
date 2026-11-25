import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Marco de las pantallas de ingreso y registro. En teléfono y iPad vertical
/// es una columna centrada de lectura corta; en iPad horizontal (ancho
/// expandido) suma un panel de marca con foto a la izquierda.
///
/// El contenido siempre se desplaza: con el teclado abierto o el texto al
/// 200 % ningún campo queda tapado ni cortado.
class LienzoAcceso extends StatelessWidget {
  const LienzoAcceso({required this.child, super.key});

  final Widget child;

  /// Ancho máximo del formulario.
  static const double anchoFormulario = 440;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final clase = ClasePantallaCampo.deAncho(c.maxWidth);
          final columna = SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: EspaciadoCampo.margenLateral(c.maxWidth),
                  vertical: EspaciadoCampo.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: anchoFormulario),
                  child: child,
                ),
              ),
            ),
          );
          if (clase != ClasePantallaCampo.expandido) return columna;
          return Row(
            children: [
              const Expanded(flex: 5, child: PanelMarcaAcceso()),
              Expanded(flex: 6, child: columna),
            ],
          );
        },
      ),
    );
  }
}

/// Panel de marca del acceso en pantallas anchas: foto a sangre con el
/// degradado del sistema y una línea de propuesta. El texto usa los roles
/// del modo campo porque el degradado termina siempre en fondo profundo.
class PanelMarcaAcceso extends StatelessWidget {
  const PanelMarcaAcceso({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    const sobreFoto = PaletaCampo.campo;
    return FondoFotoCampo(
      imagen: ImagenesCampo.dronPulverizandoVertical,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.accesoFumigacionConDronesPedido,
                style: texto.displaySmall?.copyWith(color: sobreFoto.texto),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              Text(
                l10n.accesoSolicitaServicioSigueVuelo,
                style: texto.bodyLarge?.copyWith(
                  color: sobreFoto.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
