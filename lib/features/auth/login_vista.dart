import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/auth/rol_activo.dart';
import '../../nucleo/entorno/info_entorno.dart';
import '../../nucleo/ui/colores_campo.dart';
import '../../nucleo/ui/componentes/componentes_campo.dart';
import '../../nucleo/ui/imagenes_campo.dart';
import '../../nucleo/ui/tema_campo.dart';
import '../../nucleo/ui/tipografia_campo.dart';
import '../../nucleo/ui/vitrina_campo/vitrina_campo_pantalla.dart';
import 'login_cubit.dart';
import 'login_estado.dart';

/// UI pura de login — asume que un `LoginCubit` ya está provisto más
/// arriba en el árbol (`LoginPantalla`, o `BlocProvider.value` en tests).
///
/// Primera pantalla real en modo campo (ADR 0008, ampliación del
/// 14/9/2026): variante "foto plena" de la ronda 2 del mockup — el logo
/// sobre la foto en la mitad superior, los campos al alcance del pulgar,
/// flavor/host/versión al pie. La variante "hoja + último usuario" no
/// aplica: el token por dispositivo persiste (HU-03), así que un piloto
/// habitual no vuelve a pasar por acá — no hay "último usuario" que ofrecer.
class LoginVista extends StatefulWidget {
  const LoginVista({
    required this.onIngresoExitoso,
    required this.infoEntorno,
    super.key,
  });

  final VoidCallback onIngresoExitoso;
  final InfoEntorno infoEntorno;

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _ingresar(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().ingresar(
      usuario: _usuarioController.text,
      contrasena: _contrasenaController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: ColoresCampo.fondoProfundo,
          body: FondoFotoCampo(
            imagen: ImagenesCampo.dronPulverizando,
            alineacion: const Alignment(0.15, 0),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: ConstrainedBox(
                    // El contenido ocupa al menos toda la pantalla (el
                    // `Spacer` empuja el formulario al pulgar) y, si el
                    // teclado lo achica, se vuelve desplazable.
                    constraints: BoxConstraints(
                      minHeight: (restricciones.maxHeight - 36).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: _EntradaAnimada(
                        child: Form(
                          key: _formKey,
                          child: BlocConsumer<LoginCubit, LoginEstado>(
                            listener: (context, estado) {
                              if (estado is LoginExitosoEstado) {
                                widget.onIngresoExitoso();
                              }
                            },
                            builder: (context, estado) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 40),
                                const Center(child: LogoAgrocomCampo()),
                                const SizedBox(height: 14),
                                Text(
                                  'APLICACIÓN CON DRONES',
                                  textAlign: TextAlign.center,
                                  style: TipografiaCampo.etiquetaMono.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 2.6,
                                    color: ColoresCampo.textoPrincipal
                                        .withValues(
                                          alpha: OpacidadesCampo.media,
                                        ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 32),
                                if (estado is LoginRequiereSeleccionRol)
                                  _SelectorRol(roles: estado.roles)
                                else
                                  ..._formulario(context, estado),
                                const SizedBox(height: 18),
                                PieEntornoCampo(
                                  flavor: widget.infoEntorno.flavor,
                                  entorno: widget.infoEntorno.hostApi,
                                  version: widget.infoEntorno.version,
                                ),
                                if (kDebugMode) _AccesoVitrina(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _formulario(BuildContext context, LoginEstado estado) {
    final cargando = estado is LoginCargando;
    return [
      CampoTextoCampo(
        key: const Key('login_usuario'),
        etiqueta: 'Usuario',
        controller: _usuarioController,
        enabled: !cargando,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        validator: (valor) =>
            (valor == null || valor.isEmpty) ? 'Ingresá tu usuario' : null,
      ),
      const SizedBox(height: 12),
      CampoTextoCampo(
        key: const Key('login_contrasena'),
        etiqueta: 'Contraseña',
        controller: _contrasenaController,
        enabled: !cargando,
        obscureText: _ocultarContrasena,
        textInputAction: TextInputAction.done,
        accionTexto: _ocultarContrasena ? 'Ver' : 'Ocultar',
        onAccion: () =>
            setState(() => _ocultarContrasena = !_ocultarContrasena),
        onFieldSubmitted: (_) => cargando ? null : _ingresar(context),
        validator: (valor) =>
            (valor == null || valor.isEmpty) ? 'Ingresá tu contraseña' : null,
      ),
      if (estado is LoginFallido) ...[
        const SizedBox(height: 14),
        NotaInlineCampo(
          key: const Key('login_error'),
          texto: estado.mensaje,
          color: ColoresCampo.acentoRojo,
        ),
      ],
      const SizedBox(height: 18),
      BotonPrimarioCampo(
        key: const Key('login_boton'),
        texto: 'Ingresar',
        cargando: cargando,
        onPressed: () => _ingresar(context),
      ),
    ];
  }
}

/// Entrada suave (opacidad + deslizamiento) para el contenido del login —
/// animación implícita de Flutter, sin paquetes nuevos: corre una sola vez
/// al construirse, así que no interfiere con `tester.pumpAndSettle()`.
class _EntradaAnimada extends StatelessWidget {
  const _EntradaAnimada({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, (1 - valor) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Selector de rol tras un `409` en el flavor `auxiliar` (HU-69, ADR 0005
/// de este repo) — solo se muestra ahí, `LoginCubit` nunca emite
/// `LoginRequiereSeleccionRol` en el flavor `piloto`.
class _SelectorRol extends StatelessWidget {
  const _SelectorRol({required this.roles});

  final List<RolActivo> roles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Elegí con qué rol entrar',
          style: TipografiaCampo.tituloPantalla.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Tu usuario tiene más de un rol activo.',
          style: TipografiaCampo.cuerpo,
        ),
        const SizedBox(height: 18),
        for (final rol in roles) ...[
          ItemListaCampo(
            key: Key('login_rol_${rol.id}'),
            titulo: rol.description ?? rol.name,
            subtitulo: rol.description == null ? null : rol.name,
            icono: _iconoRol(rol.name),
            onTap: () => context.read<LoginCubit>().elegirRol(rol.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  IconData _iconoRol(String nombre) => switch (nombre) {
    'piloto' => Icons.flight_takeoff,
    'auxiliar' => Icons.support_agent,
    _ => Icons.person_outline,
  };
}

/// Acceso de depuración a la vista previa del modo campo (ADR 0008) — solo
/// existe en `kDebugMode`; un build de release no lo compila.
class _AccesoVitrina extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('vitrina_campo_boton'),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const VitrinaCampoPantalla())),
      style: TextButton.styleFrom(
        foregroundColor: ColoresCampo.textoPrincipal.withValues(alpha: 0.45),
        textStyle: TipografiaCampo.datoMono.copyWith(fontSize: 11),
      ),
      child: const Text('Vista previa · modo campo'),
    );
  }
}
