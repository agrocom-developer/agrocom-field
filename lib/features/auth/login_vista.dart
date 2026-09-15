import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nucleo/auth/rol_activo.dart';
import 'login_cubit.dart';
import 'login_estado.dart';

/// UI pura de login — asume que un `LoginCubit` ya está provisto más
/// arriba en el árbol (`LoginPantalla`, o `BlocProvider.value` en tests).
class LoginVista extends StatefulWidget {
  const LoginVista({required this.onIngresoExitoso, super.key});

  final VoidCallback onIngresoExitoso;

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _EntradaAnimada(
              child: Form(
                key: _formKey,
                child: BlocConsumer<LoginCubit, LoginEstado>(
                  listener: (context, estado) {
                    if (estado is LoginExitosoEstado) {
                      widget.onIngresoExitoso();
                    }
                  },
                  builder: (context, estado) {
                    if (estado is LoginRequiereSeleccionRol) {
                      return _SelectorRol(roles: estado.roles);
                    }
                    final cargando = estado is LoginCargando;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/imagenes/agrocom_logo.png',
                          height: 120,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const Key('login_usuario'),
                          controller: _usuarioController,
                          enabled: !cargando,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (valor) => (valor == null || valor.isEmpty)
                              ? 'Ingresá tu usuario'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login_contrasena'),
                          controller: _contrasenaController,
                          enabled: !cargando,
                          obscureText: _ocultarContrasena,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarContrasena
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _ocultarContrasena = !_ocultarContrasena,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) =>
                              cargando ? null : _ingresar(context),
                          validator: (valor) => (valor == null || valor.isEmpty)
                              ? 'Ingresá tu contraseña'
                              : null,
                        ),
                        if (estado is LoginFallido) ...[
                          const SizedBox(height: 16),
                          Text(
                            estado.mensaje,
                            key: const Key('login_error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('login_boton'),
                          onPressed: cargando ? null : () => _ingresar(context),
                          child: cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Ingresar'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tu usuario tiene más de un rol activo. Elegí con cuál entrar:',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (final rol in roles) ...[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: Key('login_rol_${rol.id}'),
              leading: Icon(_iconoRol(rol.name)),
              title: Text(rol.description ?? rol.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.read<LoginCubit>().elegirRol(rol.id),
            ),
          ),
          const SizedBox(height: 12),
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
