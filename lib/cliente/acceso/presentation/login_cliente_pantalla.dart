import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/aviso_marketplace.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/campo_formulario_marketplace.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import '../domain/reglas_acceso.dart';
import 'formulario_acceso_estado.dart';
import 'lienzo_acceso.dart';
import 'login_cliente_cubit.dart';

/// Ingreso del cliente: usuario, contraseña y una sola acción. Requiere red;
/// si falla, el aviso explica por qué y lo escrito se conserva.
class LoginClientePantalla extends StatelessWidget {
  const LoginClientePantalla({
    required this.alEntrar,
    required this.alCrearCuenta,
    this.nota,
    super.key,
  });

  final ValueChanged<SesionCliente> alEntrar;
  final VoidCallback alCrearCuenta;

  /// Nota de entorno bajo el formulario (la define el modo demo).
  final String? nota;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginClienteCubit(context.read<AccesoRepositorio>()),
      child: BlocListener<LoginClienteCubit, FormularioAccesoEstado>(
        listenWhen: (antes, ahora) => ahora.sesion != null,
        listener: (context, estado) {
          HapticaCampo.confirmacion();
          alEntrar(estado.sesion!);
        },
        child: LienzoAcceso(
          child: _Formulario(alCrearCuenta: alCrearCuenta, nota: nota),
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.alCrearCuenta, this.nota});

  final VoidCallback alCrearCuenta;
  final String? nota;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _intentado = false;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _intentado = true);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<LoginClienteCubit>().enviar(
      usuario: _usuario.text,
      contrasena: _contrasena.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<LoginClienteCubit>();
    return BlocBuilder<LoginClienteCubit, FormularioAccesoEstado>(
      builder: (context, estado) {
        final mensaje = estado.mensajeFallo;
        return Form(
          key: _formulario,
          autovalidateMode: _intentado
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoAgrocomCampo(ancho: 104, sombra: false),
                const SizedBox(height: EspaciadoCampo.xl),
                Text('Ingresa a tu cuenta', style: texto.headlineMedium),
                const SizedBox(height: EspaciadoCampo.s),
                Text(
                  'Solicita un servicio y síguelo en vivo.',
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                AnimatedSwitcher(
                  duration: MovimientoCampo.duracion(
                    context,
                    MovimientoCampo.media,
                  ),
                  switchInCurve: MovimientoCampo.entrada,
                  switchOutCurve: MovimientoCampo.salida,
                  child: mensaje == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          key: ValueKey(mensaje),
                          padding: const EdgeInsets.only(
                            bottom: EspaciadoCampo.l,
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: AvisoMarketplace(
                              mensaje: mensaje,
                              tono: estado.sinConexion
                                  ? TonoAviso.alerta
                                  : TonoAviso.error,
                              icono: estado.sinConexion
                                  ? Icons.wifi_off_rounded
                                  : null,
                            ),
                          ),
                        ),
                ),
                CampoFormularioMarketplace(
                  key: const Key('login-usuario'),
                  etiqueta: 'Usuario',
                  controller: _usuario,
                  enabled: !estado.enviando,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: ReglasAcceso.usuario,
                  errorServidor: estado.porCampo[CampoAcceso.usuario],
                  onChanged: (_) => cubit.limpiarFallo(),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                CampoFormularioMarketplace(
                  key: const Key('login-contrasena'),
                  etiqueta: 'Contraseña',
                  controller: _contrasena,
                  enabled: !estado.enviando,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: ReglasAcceso.contrasena,
                  errorServidor: estado.porCampo[CampoAcceso.contrasena],
                  onChanged: (_) => cubit.limpiarFallo(),
                  onFieldSubmitted: (_) => _enviar(),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                BotonPrincipalMarketplace(
                  key: const Key('login-ingresar'),
                  texto: 'Ingresar',
                  cargando: estado.enviando,
                  onPressed: _enviar,
                ),
                const SizedBox(height: EspaciadoCampo.s),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿Primera vez en Agrocom?',
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                      TextButton(
                        key: const Key('login-crear-cuenta'),
                        onPressed: estado.enviando
                            ? null
                            : widget.alCrearCuenta,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            ObjetivoTactilCampo.minimo,
                            ObjetivoTactilCampo.minimo,
                          ),
                          foregroundColor: paleta.acentoTexto,
                        ),
                        child: const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ),
                if (widget.nota != null) ...[
                  const SizedBox(height: EspaciadoCampo.l),
                  AvisoMarketplace(mensaje: widget.nota!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
