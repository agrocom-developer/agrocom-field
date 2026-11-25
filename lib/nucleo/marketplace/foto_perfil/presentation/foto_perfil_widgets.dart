import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../foto_preparador.dart';
import '../../ui/avatar_foto.dart';
import '../../ui/aviso_marketplace.dart';
import '../foto_perfil_repositorio.dart';
import 'foto_perfil_cubit.dart';
import '../../../../l10n/app_localizations.dart';

/// Provee el [FotoPerfilCubit] a [child] (el avatar y las acciones de la
/// foto de perfil). Lee [FotoPerfilRepositorio] y [PreparadorFoto] del
/// contexto. Con [urlInicial] no vuelve a pedir la foto a la red.
class FotoPerfilProveedor extends StatelessWidget {
  const FotoPerfilProveedor({required this.child, this.urlInicial, super.key});

  final Widget child;
  final String? urlInicial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) {
        final cubit = FotoPerfilCubit(
          context.read<FotoPerfilRepositorio>(),
          context.read<PreparadorFoto>(),
          l10n,
          urlInicial: urlInicial,
        );
        if (urlInicial == null) cubit.cargar();
        return cubit;
      },
      child: child,
    );
  }
}

/// El retrato de la cuenta: foto o iniciales. Un toque abre las opciones.
class AvatarFotoPerfil extends StatelessWidget {
  const AvatarFotoPerfil({
    required this.iniciales,
    required this.nombre,
    this.tamano = 64,
    super.key,
  });

  final String iniciales;
  final String nombre;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return BlocBuilder<FotoPerfilCubit, FotoPerfilEstado>(
      builder: (context, estado) {
        return Semantics(
          button: true,
          label: estado.tieneFoto
              ? l10n.fotoPerfilFotoPerfilTocaPara(nombre)
              : l10n.fotoPerfilSinFotoPerfilToca,
          excludeSemantics: true,
          child: InkResponse(
            key: const Key('foto-perfil-avatar'),
            onTap: estado.trabajando
                ? null
                : () => mostrarOpcionesFotoPerfil(context),
            radius: tamano / 2 + 8,
            child: SizedBox(
              width: tamano,
              height: tamano,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarFoto(
                    iniciales: iniciales,
                    etiqueta: nombre,
                    url: estado.url,
                    bytes: estado.bytes,
                    tamano: tamano,
                  ),
                  if (estado.trabajando)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: paleta.fondo.withValues(alpha: 0.6),
                        ),
                        child: Center(
                          child: SizedBox.square(
                            dimension: tamano * 0.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: paleta.acentoTexto,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(EspaciadoCampo.xs),
                      decoration: BoxDecoration(
                        color: paleta.superficie,
                        shape: BoxShape.circle,
                        border: Border.all(color: paleta.bordeFuerte),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: paleta.acentoTexto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botones de la foto de perfil (agregar o cambiar, quitar) y el resultado
/// de la última acción: éxito, error o sin red, con salida clara.
class AccionesFotoPerfil extends StatelessWidget {
  const AccionesFotoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<FotoPerfilCubit, FotoPerfilEstado>(
      builder: (context, estado) {
        final cubit = context.read<FotoPerfilCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: EspaciadoCampo.s,
              children: [
                TextButton.icon(
                  key: const Key('foto-perfil-cambiar'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      ObjetivoTactilCampo.minimo,
                      ObjetivoTactilCampo.guantes,
                    ),
                  ),
                  onPressed: estado.trabajando
                      ? null
                      : () => mostrarOpcionesFotoPerfil(context),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    estado.trabajando
                        ? l10n.fotoPerfilSubiendoFoto
                        : estado.tieneFoto
                        ? l10n.fotoPerfilCambiarFoto
                        : l10n.fotoPerfilAgregarFoto,
                  ),
                ),
                if (estado.tieneFoto && !estado.trabajando)
                  TextButton.icon(
                    key: const Key('foto-perfil-quitar'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        ObjetivoTactilCampo.minimo,
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: cubit.quitar,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.fotoPerfilQuitar),
                  ),
              ],
            ),
            if (!estado.tieneFoto && estado.mensaje == null)
              Text(
                l10n.fotoPerfilConUnaFotoCliente,
                style: texto.bodySmall?.copyWith(
                  color: context.paleta.textoSecundario,
                ),
              ),
            if (estado.mensaje != null) ...[
              const SizedBox(height: EspaciadoCampo.s),
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  key: const Key('foto-perfil-aviso'),
                  mensaje: estado.mensaje!,
                  tono: !estado.esError
                      ? TonoAviso.info
                      : estado.sinRed
                      ? TonoAviso.alerta
                      : TonoAviso.error,
                  icono: !estado.esError
                      ? Icons.check_circle_rounded
                      : estado.sinRed
                      ? Icons.wifi_off_rounded
                      : null,
                ),
              ),
              if (estado.puedeReintentar)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('foto-perfil-reintentar'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        ObjetivoTactilCampo.minimo,
                        ObjetivoTactilCampo.guantes,
                      ),
                    ),
                    onPressed: cubit.reintentar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.fotoPerfilReintentar),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Hoja con las opciones: tomar una foto, elegir de la galería o quitarla.
Future<void> mostrarOpcionesFotoPerfil(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<FotoPerfilCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (hoja) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OpcionHoja(
            clave: const Key('foto-perfil-camara'),
            icono: Icons.photo_camera_outlined,
            texto: l10n.fotoPerfilTomarUnaFoto,
            alToque: () {
              Navigator.pop(hoja);
              cubit.elegir(OrigenFoto.camara);
            },
          ),
          _OpcionHoja(
            clave: const Key('foto-perfil-galeria'),
            icono: Icons.photo_library_outlined,
            texto: l10n.fotoPerfilElegirGaleria,
            alToque: () {
              Navigator.pop(hoja);
              cubit.elegir(OrigenFoto.galeria);
            },
          ),
          if (cubit.state.tieneFoto)
            _OpcionHoja(
              clave: const Key('foto-perfil-quitar-hoja'),
              icono: Icons.delete_outline_rounded,
              texto: l10n.fotoPerfilQuitarFoto,
              alToque: () {
                Navigator.pop(hoja);
                cubit.quitar();
              },
            ),
          const SizedBox(height: EspaciadoCampo.s),
        ],
      ),
    ),
  );
}

class _OpcionHoja extends StatelessWidget {
  const _OpcionHoja({
    required this.clave,
    required this.icono,
    required this.texto,
    required this.alToque,
  });

  final Key clave;
  final IconData icono;
  final String texto;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) => ListTile(
    key: clave,
    minTileHeight: ObjetivoTactilCampo.guantes,
    leading: Icon(icono, color: context.paleta.acentoTexto),
    title: Text(texto),
    onTap: alToque,
  );
}
