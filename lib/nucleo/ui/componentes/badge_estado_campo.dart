import 'package:flutter/material.dart';

import '../colores_campo.dart';

/// Semántica de [BadgeEstadoCampo] — el color sale del `enum`, nunca de un
/// string suelto por pantalla (p. ej. la cola de sync: pendiente/reintento/
/// confirmado; el reporte de equipos: a confirmar/revisar).
enum EstadoBadgeCampo { pendiente, reintento, ok, generico }

/// Pill chico de estado (mock: "PEND"/"RETRY"/"OK") — texto mono en
/// mayúscula sobre un fondo semántico tenue.
class BadgeEstadoCampo extends StatelessWidget {
  const BadgeEstadoCampo({
    required this.texto,
    this.estado = EstadoBadgeCampo.generico,
    super.key,
  });

  final String texto;
  final EstadoBadgeCampo estado;

  Color get _color => switch (estado) {
    EstadoBadgeCampo.pendiente => ColoresCampo.acentoAmbar,
    EstadoBadgeCampo.reintento => ColoresCampo.acentoRojo,
    EstadoBadgeCampo.ok => ColoresCampo.acentoLima,
    EstadoBadgeCampo.generico => ColoresCampo.textoPrincipal,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
