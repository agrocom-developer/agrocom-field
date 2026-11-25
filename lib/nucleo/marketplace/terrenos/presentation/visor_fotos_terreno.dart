import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../dominio/dominio.dart';
import 'imagen_terreno.dart';
import '../../../../l10n/app_localizations.dart';

/// Una foto para mostrar: la elegida en el celular o la del servidor.
typedef ImagenParaVer = ({Uint8List? bytes, String? url});

/// Las fotos del terreno que el cliente subió, en una tira horizontal, para
/// que el piloto vea el estado antes de ofertar. Sin fotos lo dice, en vez
/// de dejar un hueco. Un toque abre la foto a pantalla completa.
class VisorFotosTerreno extends StatelessWidget {
  const VisorFotosTerreno({required this.fotos, super.key});

  final List<FotoTerreno> fotos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.terrenosFotosDelTerreno, style: texto.titleMedium),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        if (fotos.isEmpty)
          Text(
            l10n.terrenosClienteSubioFotosDel,
            key: const Key('fotos-terreno-vacio'),
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: EspaciadoCampo.s),
              itemBuilder: (context, i) => Semantics(
                image: true,
                button: true,
                label:
                    'Foto ${i + 1} de ${fotos.length} del terreno'
                    '${fotos[i].descripcion == null ? '' : ': ${fotos[i].descripcion}'}',
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RadioCampo.media),
                  child: InkWell(
                    key: Key('visor-foto-$i'),
                    onTap: () => abrirVisorFotos(context, [
                      for (final f in fotos) (bytes: null, url: f.url),
                    ], i),
                    child: SizedBox(
                      width: 160,
                      height: 120,
                      child: ImagenTerreno(url: fotos[i].url),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Abre las fotos a pantalla completa, con zoom y desplazamiento entre
/// ellas.
void abrirVisorFotos(
  BuildContext context,
  List<ImagenParaVer> fotos,
  int inicial,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _PantallaVisor(fotos: fotos, inicial: inicial),
    ),
  );
}

class _PantallaVisor extends StatefulWidget {
  const _PantallaVisor({required this.fotos, required this.inicial});

  final List<ImagenParaVer> fotos;
  final int inicial;

  @override
  State<_PantallaVisor> createState() => _PantallaVisorState();
}

class _PantallaVisorState extends State<_PantallaVisor> {
  late final _controlador = PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.terrenosFoto(_actual + 1, widget.fotos.length)),
        leading: IconButton(
          tooltip: l10n.terrenosCerrar,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _controlador,
        itemCount: widget.fotos.length,
        onPageChanged: (i) => setState(() => _actual = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: ImagenTerreno(
              bytes: widget.fotos[i].bytes,
              url: widget.fotos[i].url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
