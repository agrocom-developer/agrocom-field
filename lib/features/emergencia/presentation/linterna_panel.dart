import 'package:flutter/material.dart';

import '../../../nucleo/linterna/linterna_controlador.dart';

/// Panel del modo emergencia (HU-68): un único control de linterna, con su
/// estado visible. No hay más acciones — ver el recorte documentado en
/// `runs/09.md`.
class LinternaPanel extends StatefulWidget {
  const LinternaPanel({required this.controlador, super.key});

  final LinternaControlador controlador;

  @override
  State<LinternaPanel> createState() => _LinternaPanelState();
}

class _LinternaPanelState extends State<LinternaPanel> {
  late final Future<bool> _disponible = widget.controlador.disponible();
  bool _encendida = false;
  String? _error;

  Future<void> _alternar(bool encender) async {
    setState(() => _error = null);
    try {
      if (encender) {
        await widget.controlador.encender();
      } else {
        await widget.controlador.apagar();
      }
      setState(() => _encendida = encender);
    } catch (_) {
      setState(() => _error = 'No se pudo controlar la linterna');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<bool>(
          future: _disponible,
          builder: (context, snapshot) {
            final cargando = snapshot.connectionState != ConnectionState.done;
            final disponible = snapshot.data ?? false;
            final String estado;
            if (cargando) {
              estado = 'Comprobando...';
            } else if (!disponible) {
              estado = 'No disponible en este dispositivo';
            } else {
              estado = _encendida ? 'Encendida' : 'Apagada';
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Modo emergencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  key: const Key('linterna_switch'),
                  title: const Text('Linterna'),
                  subtitle: Text(estado, key: const Key('linterna_estado')),
                  value: _encendida,
                  onChanged: (!cargando && disponible) ? _alternar : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: const Key('linterna_error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
