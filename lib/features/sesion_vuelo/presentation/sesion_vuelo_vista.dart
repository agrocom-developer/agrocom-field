import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sesion_cubit.dart';
import 'sesion_estado.dart';

/// UI pura de la sesión de vuelo — muestra el ciclo de vida de una sesión de
/// vuelo (inicial, abriendo, activa, cerrando, cerrada, error). Asume que un
/// `SesionCubit` ya está provisto en el árbol (`SesionVueloPantalla`, o
/// `BlocProvider.value` en tests).
class SesionVueloVista extends StatefulWidget {
  const SesionVueloVista({required this.trabajoUuidCliente, super.key});

  final String trabajoUuidCliente;

  @override
  State<SesionVueloVista> createState() => _SesionVueloVistaState();
}

class _SesionVueloVistaState extends State<SesionVueloVista> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _hectareasController;
  late TextEditingController _litrosController;
  String? _motivoSeleccionado;

  static const _motivosCierre = [
    ('completado', 'Completado'),
    ('relevo_piloto', 'Relevo de piloto'),
    ('cambio_dron', 'Cambio de dron'),
    ('falla_equipo', 'Falla de equipo'),
    ('clima', 'Clima'),
    ('fin_jornada', 'Fin de jornada'),
    ('otro', 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _hectareasController = TextEditingController();
    _litrosController = TextEditingController();
  }

  @override
  void dispose() {
    _hectareasController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  void _abrirSesion(BuildContext context) {
    context.read<SesionCubit>().abrir();
  }

  void _mostrarFormularioCierre(BuildContext context) {
    _motivoSeleccionado = null;
    _hectareasController.clear();
    _litrosController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const Key('cierre_hectareas'),
                  controller: _hectareasController,
                  decoration: const InputDecoration(
                    labelText: 'Hectáreas declaradas *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Las hectáreas son obligatorias';
                    }
                    try {
                      final decimal = Decimal.parse(valor);
                      if (decimal < Decimal.zero) {
                        return 'Las hectáreas no pueden ser negativas';
                      }
                    } catch (e) {
                      return 'Ingresá un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('cierre_motivo'),
                  initialValue: _motivoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de cierre *',
                  ),
                  items: _motivosCierre
                      .map(
                        (tuple) => DropdownMenuItem(
                          value: tuple.$1,
                          child: Text(tuple.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setState(() => _motivoSeleccionado = valor);
                  },
                  validator: (valor) => (valor == null || valor.isEmpty)
                      ? 'Seleccioná un motivo de cierre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('cierre_litros'),
                  controller: _litrosController,
                  decoration: const InputDecoration(
                    labelText: 'Litros consumidos (opcional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) return null;
                    try {
                      final decimal = Decimal.parse(valor);
                      if (decimal < Decimal.zero) {
                        return 'Los litros no pueden ser negativos';
                      }
                    } catch (e) {
                      return 'Ingresá un número válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_confirmar_cierre'),
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;

              final hectareas = Decimal.parse(_hectareasController.text);
              final litros = _litrosController.text.isEmpty
                  ? null
                  : Decimal.parse(_litrosController.text);

              context.read<SesionCubit>().cerrar(
                motivoCierre: _motivoSeleccionado!,
                hectareasDeclaradas: hectareas,
                litrosConsumidos: litros,
              );

              Navigator.pop(dialogContext);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión de vuelo')),
      body: BlocConsumer<SesionCubit, SesionEstado>(
        listener: (context, estado) {
          if (estado is SesionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, estado) => switch (estado) {
          SesionInicial() => Center(
            child: FilledButton(
              key: const Key('boton_abrir_sesion'),
              onPressed: () => _abrirSesion(context),
              child: const Text('Abrir sesión'),
            ),
          ),
          SesionAbriendo() => const Center(child: CircularProgressIndicator()),
          SesionActiva(:final sesion) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sesión activa',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(label: 'Secuencia', value: '${sesion.secuencia}'),
                  _InfoRow(
                    label: 'Inicio',
                    value: _formatearHora(sesion.inicio),
                  ),
                  _InfoRow(
                    label: 'Hectáreas declaradas',
                    value: sesion.hectareasDeclaradas.toString(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('boton_cerrar_sesion'),
                    onPressed: () => _mostrarFormularioCierre(context),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
          SesionCerrando() => const Center(child: CircularProgressIndicator()),
          SesionCerrada(:final sesion) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sesión cerrada',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(
                    label: 'Motivo',
                    value: _etiquetaMotivo(sesion.motivoCierre ?? ''),
                  ),
                  _InfoRow(
                    label: 'Hectáreas declaradas (cierre)',
                    value: sesion.hectareasDeclaradasCierre?.toString() ?? '—',
                  ),
                  if (sesion.litrosConsumidos != null)
                    _InfoRow(
                      label: 'Litros consumidos',
                      value: sesion.litrosConsumidos!.toString(),
                    ),
                  _InfoRow(
                    label: 'Fin',
                    value: _formatearHora(sesion.fin ?? DateTime.now()),
                  ),
                ],
              ),
            ),
          ),
          SesionError(:final mensaje) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    mensaje,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('boton_reintentar'),
                    onPressed: () => context.read<SesionCubit>().abrir(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }

  String _formatearHora(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _etiquetaMotivo(String motivo) {
    for (final tuple in _motivosCierre) {
      if (tuple.$1 == motivo) return tuple.$2;
    }
    return motivo;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
