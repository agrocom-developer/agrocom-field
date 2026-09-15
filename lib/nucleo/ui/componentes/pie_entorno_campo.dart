import 'package:flutter/material.dart';

import '../../flavor.dart';
import '../colores_campo.dart';
import '../tipografia_campo.dart';

/// Pie de pantalla con flavor · entorno · versión ("PILOTO · 192.168.0.3 ·
/// v0.1.0"), en mono chico y atenuado, con el entorno en ámbar. Va al pie
/// del login para que quien va a cargar trabajo real vea contra qué servidor
/// lo hace antes de entrar (ADR 0004: la URL base la inyecta el build, un
/// APK apuntado al entorno equivocado no se distingue de otro por afuera).
///
/// [entorno] es un texto ya resuelto por quien lo llama (normalmente el host
/// de `API_BASE_URL`): el widget no lee configuración ni decide qué es
/// "producción".
class PieEntornoCampo extends StatelessWidget {
  const PieEntornoCampo({
    required this.flavor,
    required this.entorno,
    required this.version,
    super.key,
  });

  final Flavor flavor;
  final String entorno;
  final String version;

  @override
  Widget build(BuildContext context) {
    final base = TipografiaCampo.datoMonoDestacado.copyWith(
      fontSize: 11,
      color: ColoresCampo.textoPrincipal.withValues(alpha: 0.45),
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: flavor.name.toUpperCase()),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: entorno,
            style: base.copyWith(color: ColoresCampo.acentoAmbar),
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(text: 'v$version'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
