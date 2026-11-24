import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../foto_preparador.dart';
import '../../ui/aviso_marketplace.dart';
import '../fotos_terreno_repositorio.dart';
import 'casilla_agregar_foto.dart';
import 'fotos_terreno_cubit.dart';
import 'miniatura_foto_terreno.dart';
import 'visor_fotos_terreno.dart';

/// Galería editable de las fotos del terreno (hasta 8): agregar desde la
/// cámara o la galería, ver el avance de cada subida, reintentar una que
/// falló y quitar. Necesita un [FotosTerrenoCubit] en el contexto.
class GaleriaFotosTerreno extends StatelessWidget {
  const GaleriaFotosTerreno({this.alAbrir, super.key});

  /// Abre una foto a pantalla completa; por defecto usa el visor común.
  final void Function(BuildContext, List<FotoDeTerreno>, int)? alAbrir;

  static void _visor(BuildContext context, List<FotoDeTerreno> fotos, int i) =>
      abrirVisorFotos(context, [
        for (final f in fotos) (bytes: f.bytes, url: f.url),
      ], i);

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return BlocBuilder<FotosTerrenoCubit, FotosTerrenoEstado>(
      builder: (context, estado) {
        final cubit = context.read<FotosTerrenoCubit>();
        final nuevo = estado.terrenoId == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Fotos del terreno', style: texto.titleMedium),
                  ),
                ),
                Semantics(
                  label:
                      '${estado.fotos.length} de '
                      '${FotosTerrenoRepositorio.maximo} fotos',
                  child: ExcludeSemantics(
                    child: Text(
                      '${estado.fotos.length}/${FotosTerrenoRepositorio.maximo}',
                      style: texto.labelLarge?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              estado.fotos.isEmpty
                  ? 'Agrega fotos del estado del terreno: el piloto las ve '
                        'antes de ofertar y ajusta mejor su precio.'
                  : nuevo
                  ? 'Se suben cuando publiques la solicitud.'
                  : 'El piloto las ve antes de ofertar.',
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Wrap(
              spacing: EspaciadoCampo.s,
              runSpacing: EspaciadoCampo.s,
              children: [
                for (var i = 0; i < estado.fotos.length; i++)
                  MiniaturaFotoTerreno(
                    foto: estado.fotos[i],
                    numero: i + 1,
                    alAbrir: () =>
                        (alAbrir ?? _visor)(context, estado.fotos, i),
                    alQuitar: () => cubit.quitar(estado.fotos[i].clave),
                    alReintentar: () => cubit.reintentar(estado.fotos[i].clave),
                  ),
                if (!estado.lleno)
                  CasillaAgregarFoto(
                    alToque: () => _elegirOrigen(context, cubit),
                  ),
              ],
            ),
            if (estado.mensaje != null) ...[
              const SizedBox(height: EspaciadoCampo.m),
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  key: const Key('fotos-terreno-aviso'),
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
            ],
          ],
        );
      },
    );
  }

  Future<void> _elegirOrigen(BuildContext context, FotosTerrenoCubit cubit) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('fotos-terreno-camara'),
              minTileHeight: ObjetivoTactilCampo.guantes,
              leading: Icon(
                Icons.photo_camera_outlined,
                color: context.paleta.acentoTexto,
              ),
              title: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(hoja);
                cubit.agregar(OrigenFoto.camara);
              },
            ),
            ListTile(
              key: const Key('fotos-terreno-galeria'),
              minTileHeight: ObjetivoTactilCampo.guantes,
              leading: Icon(
                Icons.photo_library_outlined,
                color: context.paleta.acentoTexto,
              ),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(hoja);
                cubit.agregar(OrigenFoto.galeria);
              },
            ),
            const SizedBox(height: EspaciadoCampo.s),
          ],
        ),
      ),
    );
  }
}
