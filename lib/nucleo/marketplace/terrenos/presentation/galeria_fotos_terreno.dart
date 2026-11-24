import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../foto_preparador.dart';
import '../../ui/aviso_marketplace.dart';
import '../fotos_terreno_repositorio.dart';
import 'fotos_terreno_cubit.dart';
import 'imagen_terreno.dart';
import 'visor_fotos_terreno.dart';

/// Lado de una miniatura: cabe tres por fila en un teléfono chico.
const double _lado = 96;

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
                  _Miniatura(
                    foto: estado.fotos[i],
                    numero: i + 1,
                    alAbrir: () =>
                        (alAbrir ?? _visor)(context, estado.fotos, i),
                    alQuitar: () => cubit.quitar(estado.fotos[i].clave),
                    alReintentar: () => cubit.reintentar(estado.fotos[i].clave),
                  ),
                if (!estado.lleno)
                  _Agregar(alToque: () => _elegirOrigen(context, cubit)),
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

class _Agregar extends StatelessWidget {
  const _Agregar({required this.alToque});

  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: 'Agregar una foto del terreno',
      excludeSemantics: true,
      child: Material(
        color: paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: paleta.bordeFuerte),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('fotos-terreno-agregar'),
          onTap: alToque,
          child: SizedBox.square(
            dimension: _lado,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: paleta.acentoTexto),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      'Agregar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: paleta.acentoTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.foto,
    required this.numero,
    required this.alQuitar,
    required this.alReintentar,
    this.alAbrir,
  });

  final FotoDeTerreno foto;
  final int numero;
  final VoidCallback? alAbrir;
  final VoidCallback alQuitar;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final fallida = foto.situacion == SituacionFoto.fallida;
    final subiendo = foto.situacion == SituacionFoto.subiendo;
    final estado = switch (foto.situacion) {
      SituacionFoto.guardada => 'guardada',
      SituacionFoto.subiendo => 'subiendo',
      SituacionFoto.pendiente => 'se sube al publicar',
      SituacionFoto.fallida => 'no se pudo subir',
    };
    return SizedBox.square(
      dimension: _lado,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              image: true,
              button: alAbrir != null,
              label: 'Foto $numero del terreno, $estado',
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: fallida ? alReintentar : alAbrir,
                  child: ImagenTerreno(bytes: foto.bytes, url: foto.url),
                ),
              ),
            ),
          ),
          if (subiendo || fallida)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !fallida,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: paleta.fondo.withValues(alpha: 0.7),
                    border: fallida
                        ? Border.all(color: paleta.error, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: subiendo
                        ? SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: paleta.acentoTexto,
                            ),
                          )
                        : InkWell(
                            key: Key('fotos-terreno-reintentar-$numero'),
                            onTap: alReintentar,
                            child: Padding(
                              padding: const EdgeInsets.all(EspaciadoCampo.s),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: paleta.error,
                                  ),
                                  Text(
                                    'Reintentar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: paleta.texto),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          if (!subiendo)
            Positioned(
              top: -EspaciadoCampo.s,
              right: -EspaciadoCampo.s,
              child: Semantics(
                button: true,
                label: 'Quitar la foto $numero',
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: ObjetivoTactilCampo.minimo,
                  child: Center(
                    child: Material(
                      color: paleta.superficie,
                      shape: CircleBorder(
                        side: BorderSide(color: paleta.bordeFuerte),
                      ),
                      child: InkWell(
                        key: Key('fotos-terreno-quitar-$numero'),
                        customBorder: const CircleBorder(),
                        onTap: alQuitar,
                        child: Padding(
                          padding: const EdgeInsets.all(EspaciadoCampo.xs + 2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: paleta.texto,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
