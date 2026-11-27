import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../marketplace/ui/campo_formulario_marketplace.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'flujo_codigo_cubit.dart';
import 'flujo_codigo_vista.dart';

/// «Recuperar acceso»: la persona que olvidó su usuario o su contraseña da su
/// usuario, teléfono o correo, elige por dónde recibir el código, lo escribe y
/// fija una contraseña nueva. Al terminar devuelve el usuario de la cuenta
/// (`Navigator.pop`) para que el ingreso lo muestre.
class RecuperarAccesoPantalla extends StatefulWidget {
  const RecuperarAccesoPantalla({
    required this.app,
    this.identificadorInicial,
    super.key,
  });

  final AppCuenta app;

  /// Lo que la persona ya escribió en el ingreso, para no pedirlo dos veces.
  final String? identificadorInicial;

  @override
  State<RecuperarAccesoPantalla> createState() =>
      _RecuperarAccesoPantallaState();
}

class _RecuperarAccesoPantallaState extends State<RecuperarAccesoPantalla> {
  final _formulario = GlobalKey<FormState>();
  late final _identificador = TextEditingController(
    text: widget.identificadorInicial,
  );
  late final FlujoCodigoCubit _flujo;

  /// El identificador con el que se pidió el código: el que se confirma.
  String _enviado = '';

  @override
  void initState() {
    super.initState();
    final repositorio = context.read<CuentaSeguridadRepositorio>();
    _flujo = FlujoCodigoCubit(
      pedir: (canal) async {
        _enviado = _identificador.text.trim();
        await repositorio.pedirRecuperacion(
          identificador: _enviado,
          app: widget.app,
          canal: canal,
        );
        return null;
      },
      confirmar: (codigo, contrasena) => repositorio.confirmarRecuperacion(
        identificador: _enviado,
        app: widget.app,
        codigo: codigo,
        contrasenaNueva: contrasena ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _identificador.dispose();
    _flujo.close();
    super.dispose();
  }

  bool _validar() => _formulario.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _flujo,
      child: Scaffold(
        appBar: AppBar(title: const Text('Recuperar acceso')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BlocBuilder<FlujoCodigoCubit, FlujoCodigoEstado>(
                builder: (context, estado) => ListView(
                  padding: const EdgeInsets.all(EspaciadoCampo.l),
                  children: [
                    if (estado.etapa == EtapaCodigo.listo)
                      _Exito(usuario: '${estado.resultado ?? ''}')
                    else
                      FlujoCodigoVista(
                        tituloElegir: '¿Cómo quieres recibir el código?',
                        detalleElegir:
                            'Escribe tu usuario, teléfono o correo. Te '
                            'enviaremos un código de 6 dígitos para crear una '
                            'contraseña nueva.',
                        textoConfirmar: 'Cambiar contraseña',
                        pideContrasenaNueva: true,
                        envioCondicional: true,
                        validarAntesDeEnviar: _validar,
                        antesDelSelector: Form(
                          key: _formulario,
                          child: CampoFormularioMarketplace(
                            key: const Key('recuperar-identificador'),
                            etiqueta: 'Usuario, teléfono o correo',
                            controller: _identificador,
                            enabled: !estado.ocupado,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.username],
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Escribe tu usuario, teléfono o correo'
                                : null,
                          ),
                        ),
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
  const _Exito({required this.usuario});

  final String usuario;

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
            'Cambiaste tu contraseña',
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          usuario.isEmpty
              ? 'Ya puedes iniciar sesión con tu usuario y la contraseña '
                    'nueva.'
              : 'Tu usuario es $usuario. Ya puedes iniciar sesión con la '
                    'contraseña nueva.',
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('recuperar-ir-al-ingreso'),
          texto: 'Iniciar sesión',
          alto: ObjetivoTactilCampo.guantes,
          onPressed: () => Navigator.of(context).pop(usuario),
        ),
      ],
    );
  }
}

/// Abre «Recuperar acceso» y devuelve el usuario de la cuenta si la persona
/// cambió su contraseña.
Future<String?> abrirRecuperarAcceso(
  BuildContext context, {
  required AppCuenta app,
  String? identificador,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute<String>(
    builder: (_) =>
        RecuperarAccesoPantalla(app: app, identificadorInicial: identificador),
  ),
);
