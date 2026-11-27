import 'package:flutter/material.dart';

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
                    'Ya tienes una cuenta',
                    style: texto.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.m),
                Text(
                  deOtraApp
                      ? 'Ese teléfono o documento ya está registrado como '
                            '${tipoCuenta == 'proveedor' ? 'piloto' : 'cliente'}'
                            '. Usa la app de Agrocom que le corresponde.'
                      : 'Ese teléfono o documento ya está registrado en '
                            'Agrocom, así que no creamos otra cuenta. Inicia '
                            'sesión o recupera tu acceso.',
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (app == AppCuenta.proveedor && !deOtraApp) ...[
                  const SizedBox(height: EspaciadoCampo.m),
                  Text(
                    'Si no terminaste tu registro, al iniciar sesión '
                    'continuarás donde lo dejaste.',
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
                    texto: 'Iniciar sesión',
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
                    child: const Text('Olvidé mi contraseña'),
                  ),
                ] else
                  BotonPrincipalMarketplace(
                    key: const Key('ya-registrada-volver'),
                    texto: 'Volver',
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
