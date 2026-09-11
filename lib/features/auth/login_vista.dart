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
                      Text(
                        'Agrocom Field',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('login_usuario'),
                        controller: _usuarioController,
                        enabled: !cargando,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: (valor) => (valor == null || valor.isEmpty)
                            ? 'Ingresá tu usuario'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login_contrasena'),
                        controller: _contrasenaController,
                        enabled: !cargando,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
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
        const SizedBox(height: 16),
        for (final rol in roles)
          ListTile(
            key: Key('login_rol_${rol.id}'),
            title: Text(rol.description ?? rol.name),
            onTap: () => context.read<LoginCubit>().elegirRol(rol.id),
          ),
      ],
    );
  }
}
