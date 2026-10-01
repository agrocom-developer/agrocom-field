import 'package:flutter/material.dart';

import '../colores_campo.dart';
import '../tipografia_campo.dart';
import 'tarjeta_campo.dart';

/// Fila con título, estado en mono y un interruptor a la derecha, dentro de
/// una `TarjetaCampo` — el reemplazo del `SwitchListTile` de Material en las
/// pantallas del modo campo (ADR 0008), p. ej. la linterna del modo
/// emergencia (HU-68). Igual que el `SwitchListTile`, toda la fila es
/// tocable y alterna el valor; con [onChanged] en `null` queda deshabilitada
/// y atenuada.
///
/// [claveEstado] identifica el texto de estado para pruebas por `Key`.
class InterruptorCampo extends StatelessWidget {
  const InterruptorCampo({
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.estado,
    this.claveEstado,
    super.key,
  });

  final String titulo;
  final bool valor;
  final ValueChanged<bool>? onChanged;
  final String? estado;
  final Key? claveEstado;

  @override
  Widget build(BuildContext context) {
    final habilitado = onChanged != null;
    return Opacity(
      opacity: habilitado ? OpacidadesCampo.plena : OpacidadesCampo.media,
      child: TarjetaCampo(
        acento: valor ? ColoresCampo.acentoLima : null,
        onTap: habilitado ? () => onChanged!(!valor) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TipografiaCampo.tituloTarjeta.copyWith(fontSize: 16),
                  ),
                  if (estado != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      estado!,
                      key: claveEstado,
                      style: TipografiaCampo.datoMono,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: valor,
              onChanged: onChanged,
              activeThumbColor: ColoresCampo.fondoProfundo,
              activeTrackColor: ColoresCampo.acentoLima,
              inactiveThumbColor: ColoresCampo.textoPrincipal.withValues(
                alpha: OpacidadesCampo.media,
              ),
              inactiveTrackColor: ColoresCampo.superficie,
            ),
          ],
        ),
      ),
    );
  }
}
