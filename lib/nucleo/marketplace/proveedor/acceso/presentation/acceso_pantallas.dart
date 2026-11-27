import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/cuenta/domain/cuenta_seguridad.dart';
import '../../../../auth/cuenta/presentation/cuenta_en_eliminacion_pantalla.dart';
import '../../../../auth/cuenta/presentation/recuperar_acceso_pantalla.dart';
import '../../../../auth/presentation/bloqueo_biometrico_widgets.dart';
import '../../../../ui/componentes/logo_agrocom_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/acceso_proveedor.dart';
import 'acceso_cubit.dart';
import 'registro_proveedor_pantalla.dart';

/// La puerta de la app real del piloto: mientras no hay
/// sesión muestra el ingreso; con sesión, [construir] arma la superficie.
class PuertaAcceso extends StatelessWidget {
  const PuertaAcceso({
    required this.construir,
    this.permiteRegistro = true,
    this.nota,
    super.key,
  });

  final Widget Function(BuildContext, SesionProveedor) construir;

  /// El proveedor se registra solo y un administrador lo aprueba.
  final bool permiteRegistro;

  /// Host y versión al pie: un build apuntado al entorno equivocado se nota
  /// antes de operar (ADR 0004).
  final String? nota;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccesoCubit, AccesoEstado>(
      builder: (context, estado) => switch (estado) {
        AccesoVerificando() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AccesoSinSesion() => IngresoProveedorPantalla(
          estado: estado,
          permiteRegistro: permiteRegistro,
          nota: nota,
        ),
        AccesoBloqueado(:final desbloqueando) => PantallaBloqueoBiometrico(
          desbloqueando: desbloqueando,
          alDesbloquear: context.read<AccesoCubit>().desbloquear,
          alUsarContrasena: () => context.read<AccesoCubit>().usarContrasena(),
        ),
        AccesoEnEliminacion() => CuentaEnEliminacionPantalla(
          alConservada: context.read<AccesoCubit>().cuentaConservada,
          alCerrarSesion: context.read<AccesoCubit>().salir,
        ),
        AccesoDentro(:final sesion) => construir(context, sesion),
      },
    );
  }
}

class IngresoProveedorPantalla extends StatefulWidget {
  const IngresoProveedorPantalla({
    required this.estado,
    this.permiteRegistro = true,
    this.nota,
    super.key,
  });

  final AccesoSinSesion estado;
  final bool permiteRegistro;
  final String? nota;

  @override
  State<IngresoProveedorPantalla> createState() =>
      _IngresoProveedorPantallaState();
}

class _IngresoProveedorPantallaState extends State<IngresoProveedorPantalla> {
  final _clave = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  /// «Olvidé mi contraseña»: al terminar deja el usuario en el campo.
  Future<void> _recuperarAcceso() async {
    final usuario = await abrirRecuperarAcceso(
      context,
      app: AppCuenta.proveedor,
      identificador: _usuario.text,
    );
    if (usuario != null && usuario.isNotEmpty && mounted) {
      _usuario.text = usuario;
      _contrasena.clear();
    }
  }

  void _entrar() {
    if (!(_clave.currentState?.validate() ?? false)) return;
    context.read<AccesoCubit>().ingresar(_usuario.text, _contrasena.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final e = widget.estado;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.xl),
              children: [
                const Align(child: LogoAgrocomCampo(ancho: 150)),
                const SizedBox(height: EspaciadoCampo.xl),
                Text(
                  l10n.proveedorAccesoEntraCuenta,
                  style: texto.headlineMedium,
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  l10n.proveedorAccesoConUsuarioContrasena,
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                if (e.mensaje != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: AvisoMarketplace(
                      mensaje: e.mensaje!,
                      tono: TonoAviso.error,
                    ),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                ],
                Form(
                  key: _clave,
                  child: Column(
                    children: [
                      CampoFormularioMarketplace(
                        etiqueta: l10n.proveedorAccesoUsuario,
                        controller: _usuario,
                        enabled: !e.enviando,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.proveedorAccesoEscribeUsuario
                            : null,
                      ),
                      const SizedBox(height: EspaciadoCampo.l),
                      CampoFormularioMarketplace(
                        etiqueta: l10n.proveedorAccesoContrasena,
                        controller: _contrasena,
                        enabled: !e.enviando,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _entrar(),
                        validator: (v) => (v ?? '').isEmpty
                            ? l10n.proveedorAccesoEscribeContrasena
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                BotonPrincipalMarketplace(
                  texto: l10n.proveedorAccesoEntrar,
                  cargando: e.enviando,
                  onPressed: e.enEspera ? null : _entrar,
                ),
                const SizedBox(height: EspaciadoCampo.s),
                TextButton(
                  key: const Key('ingreso-recuperar'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  onPressed: e.enviando ? null : _recuperarAcceso,
                  child: const Text('Olvidé mi contraseña'),
                ),
                if (widget.permiteRegistro) ...[
                  const SizedBox(height: EspaciadoCampo.l),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: e.enviando ? null : () => abrirRegistro(context),
                    child: Text(l10n.proveedorAccesoSoyPilotoQuieroRegistrarme),
                  ),
                ],
                if (widget.nota != null) ...[
                  const SizedBox(height: EspaciadoCampo.xl),
                  Text(
                    widget.nota!,
                    textAlign: TextAlign.center,
                    style: texto.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
