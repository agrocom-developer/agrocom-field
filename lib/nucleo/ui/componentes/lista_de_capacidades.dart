import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../sobre_foto_campo.dart';
import '../tokens_campo.dart';
import 'encabezado_de_marca.dart';
import 'icono_agrocom.dart';

/// Una capacidad de la app: un ícono y una frase corta.
class CapacidadApp {
  const CapacidadApp({required this.icono, required this.texto});

  /// Ícono del catálogo (`IconoAgrocomId`) o de Material.
  final Widget Function(Color color) icono;
  final String texto;
}

/// Lo que puede hacer cada rol en su app. Solo lo que la app hace de verdad
/// (`CLAUDE.md`, política de marketplace): no promete nada que no exista.
List<CapacidadApp> capacidadesDeRol(RolApp rol, AppLocalizations l10n) {
  Widget Function(Color) catalogo(IconoAgrocomId id) =>
      (color) => IconoAgrocom(
        id,
        tamano: TamanoIconoCampo.estandar,
        color: color,
        excluirSemantica: true,
      );
  Widget Function(Color) datos(IconData icono) =>
      (color) => Icon(icono, size: TamanoIconoCampo.estandar, color: color);
  return switch (rol) {
    RolApp.piloto => [
      CapacidadApp(
        icono: catalogo(IconoAgrocomId.lote),
        texto: l10n.capacidadesPilotoMapa,
      ),
      CapacidadApp(
        icono: catalogo(IconoAgrocomId.dronT30),
        texto: l10n.capacidadesPilotoOfertar,
      ),
      CapacidadApp(
        icono: datos(Icons.signal_wifi_off_rounded),
        texto: l10n.capacidadesPilotoSinSenal,
      ),
      CapacidadApp(
        icono: datos(Icons.photo_camera_outlined),
        texto: l10n.capacidadesPilotoRegistro,
      ),
      CapacidadApp(
        icono: datos(Icons.star_outline_rounded),
        texto: l10n.capacidadesPilotoCalificaciones,
      ),
    ],
    RolApp.cliente => [
      CapacidadApp(
        icono: catalogo(IconoAgrocomId.hectarea),
        texto: l10n.capacidadesClientePublicar,
      ),
      CapacidadApp(
        icono: datos(Icons.compare_arrows_rounded),
        texto: l10n.capacidadesClienteComparar,
      ),
      CapacidadApp(
        icono: datos(Icons.handshake_outlined),
        texto: l10n.capacidadesClienteElegir,
      ),
      CapacidadApp(
        icono: datos(Icons.photo_camera_outlined),
        texto: l10n.capacidadesClienteSeguir,
      ),
      CapacidadApp(
        icono: datos(Icons.star_outline_rounded),
        texto: l10n.capacidadesClienteCalificar,
      ),
    ],
  };
}

/// «Qué puedes hacer como piloto / cliente»: de tres a cinco renglones con
/// ícono y una frase. Una misma lista parametrizada por [rol] para las dos
/// portadas, de modo que se vea de un vistazo qué hace cada app.
///
/// Con [sobreFoto] usa texto blanco, para ir encima de una foto.
class ListaDeCapacidades extends StatelessWidget {
  const ListaDeCapacidades({
    required this.rol,
    this.sobreFoto = false,
    super.key,
  });

  final RolApp rol;
  final bool sobreFoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final colorTexto = sobreFoto ? SobreFotoCampo.texto : paleta.texto;
    final colorIcono = sobreFoto ? SobreFotoCampo.texto : paleta.acentoTexto;
    final titulo = switch (rol) {
      RolApp.piloto => l10n.capacidadesTituloPiloto,
      RolApp.cliente => l10n.capacidadesTituloCliente,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: texto.titleLarge?.copyWith(
              color: colorTexto,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        for (final capacidad in capacidadesDeRol(rol, l10n))
          Padding(
            padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: capacidad.icono(colorIcono)),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Text(
                    capacidad.texto,
                    style: texto.bodyLarge?.copyWith(color: colorTexto),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
