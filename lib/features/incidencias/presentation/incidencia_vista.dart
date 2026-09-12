import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/tipo_incidencia.dart';
import 'incidencia_cubit.dart';
import 'incidencia_estado.dart';

/// Etiquetas legibles para el selector — mismo criterio que
/// `_motivosCierre` de `sesion_vuelo_vista.dart`: el catálogo de valores lo
/// valida el servidor ([TipoIncidencia]), esta lista solo decide cómo se
/// muestran acá.
const _tiposIncidencia = [
  (TipoIncidencia.caldo, 'Caldo / mezcla'),
  (TipoIncidencia.esc, 'ESC'),
  (TipoIncidencia.bateria, 'Batería'),
  (TipoIncidencia.mecanica, 'Mecánica'),
  (TipoIncidencia.clima, 'Clima'),
  (TipoIncidencia.otro, 'Otro'),
];

/// UI pura de "reportar incidencia" (HU-08) — asume que un
/// `IncidenciaCubit` ya está provisto más arriba en el árbol
/// (`IncidenciaPantalla`, o `BlocProvider.value` en tests).
///
/// La foto es SIEMPRE obligatoria (mismo espíritu que "sin captura no
/// cierra" de HU-09): el botón de envío queda deshabilitado hasta que haya
/// una, y no hay forma de enviar sin ella.
class IncidenciaVista extends StatefulWidget {
  const IncidenciaVista({super.key});

  @override
  State<IncidenciaVista> createState() => _IncidenciaVistaState();
}

class _IncidenciaVistaState extends State<IncidenciaVista> {
  late TextEditingController _descripcionController;
  TipoIncidencia? _tipoSeleccionado;
  Uint8List? _bytesFoto;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto(BuildContext context) async {
    final cubit = context.read<IncidenciaCubit>();
    final bytes = await cubit.tomarFoto();
    if (!mounted || bytes == null) return;
    setState(() => _bytesFoto = bytes);
  }

  void _guardar(BuildContext context) {
    final tipo = _tipoSeleccionado;
    final bytesFoto = _bytesFoto;
    if (tipo == null || bytesFoto == null) return;

    final descripcion = _descripcionController.text.trim();
    context.read<IncidenciaCubit>().registrar(
      tipo: tipo,
      descripcion: descripcion.isEmpty ? null : descripcion,
      bytesFoto: bytesFoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: BlocConsumer<IncidenciaCubit, IncidenciaEstado>(
        listener: (context, estado) {
          if (estado is IncidenciaExitosa) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incidencia registrada')),
            );
            Navigator.of(context).pop();
          }
          if (estado is IncidenciaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, estado) {
          final enviando = estado is IncidenciaEnviando;
          final puedeGuardar =
              !enviando && _tipoSeleccionado != null && _bytesFoto != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<TipoIncidencia>(
                key: const Key('selector_tipo_incidencia'),
                initialValue: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de incidencia',
                ),
                items: [
                  for (final tuple in _tiposIncidencia)
                    DropdownMenuItem(value: tuple.$1, child: Text(tuple.$2)),
                ],
                onChanged: enviando
                    ? null
                    : (valor) => setState(() => _tipoSeleccionado = valor),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('campo_descripcion'),
                controller: _descripcionController,
                enabled: !enviando,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('boton_tomar_foto'),
                onPressed: enviando ? null : () => _tomarFoto(context),
                child: Text(
                  _bytesFoto == null ? 'Tomar foto' : 'Volver a tomar foto',
                ),
              ),
              if (_bytesFoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Image.memory(
                    _bytesFoto!,
                    key: const Key('preview_foto'),
                    height: 200,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La foto es obligatoria — sin foto no se puede '
                    'registrar la incidencia.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('boton_guardar_incidencia'),
                onPressed: puedeGuardar ? () => _guardar(context) : null,
                child: enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar incidencia'),
              ),
            ],
          );
        },
      ),
    );
  }
}
