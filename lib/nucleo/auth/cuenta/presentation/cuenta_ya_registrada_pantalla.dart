import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';

/// `409 cuenta_ya_registrada`: el teléfono o el documento ya tienen cuenta.
/// No crea nada ni dice cuál de los dos datos chocó; explica y ofrece entrar
/// o recuperar el acceso. Un proveedor con el registro a medias, al iniciar
/// sesión, continúa donde quedó (`siguiente_paso`), sin crear otra cuenta.
class CuentaYaRegistradaPantalla extends StatelessWidget {
  const CuentaYaRegistradaPantalla({
    required this.app,
    required this.alIniciarSesion,
    required this.alRecuperarAcceso,
    this.tipoCuenta,
    super.key,
  });

  final AppCuenta app;

  /// `tipo_cuenta` del cuerpo del `409`, si vino.
  final String? tipoCuenta;
  final VoidCallback alIniciarSesion;
  final VoidCallback alRecuperarAcceso;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    final deOtraApp = tipoCuenta != null && tipoCuenta != app.codigo;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.xl),
              shrinkWrap: true,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.person_search_outlined,
                    size: 56,
                    color: paleta.acentoTexto,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.cuentaYaRegistradaTitulo,
                    style: texto.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.m),
                Text(
                  deOtraApp
                      ? (tipoCuenta == 'proveedor'
                            ? l10n.cuentaYaRegistradaComoPiloto
                            : l10n.cuentaYaRegistradaComoCliente)
                      : l10n.cuentaYaRegistradaDetalle,
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (app == AppCuenta.proveedor && !deOtraApp) ...[
                  const SizedBox(height: EspaciadoCampo.m),
                  Text(
                    l10n.cuentaYaRegistradaRegistroIncompleto,
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: EspaciadoCampo.xl),
                if (!deOtraApp) ...[
                  BotonPrincipalMarketplace(
                    key: const Key('ya-registrada-iniciar-sesion'),
                    texto: l10n.cuentaIniciarSesion,
                    alto: ObjetivoTactilCampo.guantes,
                    onPressed: alIniciarSesion,
                  ),
                  const SizedBox(height: EspaciadoCampo.s),
                  TextButton(
                    key: const Key('ya-registrada-recuperar'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: alRecuperarAcceso,
                    child: Text(l10n.cuentaOlvideContrasena),
                  ),
                ] else
                  BotonPrincipalMarketplace(
                    key: const Key('ya-registrada-volver'),
                    texto: l10n.cuentaVolver,
                    alto: ObjetivoTactilCampo.guantes,
                    onPressed: alIniciarSesion,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
