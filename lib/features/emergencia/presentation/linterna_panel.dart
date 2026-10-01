import 'package:flutter/material.dart';

import '../../../nucleo/linterna/linterna_controlador.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';

/// Panel del modo emergencia (HU-68): un único control de linterna, con su
/// estado visible. No hay más acciones — ver el recorte documentado en
/// `runs/09.md`.
///
/// En modo campo (ADR 0008): título y estado con la tipografía del
/// catálogo, la linterna como `InterruptorCampo` y el error como nota roja.
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
                const Text(
                  'Modo emergencia',
                  style: TipografiaCampo.tituloSeccion,
                ),
                const SizedBox(height: 16),
                InterruptorCampo(
                  key: const Key('linterna_switch'),
                  titulo: 'Linterna',
                  estado: estado,
                  claveEstado: const Key('linterna_estado'),
                  valor: _encendida,
                  onChanged: (!cargando && disponible) ? _alternar : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  NotaInlineCampo(
                    key: const Key('linterna_error'),
                    texto: _error!,
                    color: ColoresCampo.acentoRojo,
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
