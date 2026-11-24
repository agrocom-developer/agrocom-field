import 'package:flutter/material.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Foto de una evidencia: aparece con un fundido corto y, si no carga,
/// muestra un ícono con texto en lugar de un hueco.
class ImagenEvidencia extends StatelessWidget {
  const ImagenEvidencia(
    this.evidencia, {
    this.ajuste = BoxFit.cover,
    super.key,
  });

  final EvidenciaServicio evidencia;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ColoredBox(
      color: paleta.borde,
      child: Image(
        image: imagenDeRef(evidencia.imagenRef),
        fit: ajuste,
        excludeFromSemantics: true,
        frameBuilder: (context, hijo, cuadro, sincrona) => sincrona
            ? hijo
            : AnimatedOpacity(
                opacity: cuadro == null ? 0 : 1,
                duration: MovimientoCampo.duracion(
                  context,
                  MovimientoCampo.media,
                ),
                curve: MovimientoCampo.entrada,
                child: hijo,
              ),
        errorBuilder: (context, _, _) => Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: paleta.textoSecundario,
            semanticLabel: 'La foto no cargó',
          ),
        ),
      ),
    );
  }
}

/// Evidencias del servicio en una grilla: foto arriba, tipo y hora debajo
/// (el texto nunca va encima de la foto). Un toque abre la foto completa.
class GaleriaEvidencias extends StatelessWidget {
  const GaleriaEvidencias({required this.evidencias, super.key});

  final List<EvidenciaServicio> evidencias;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final ampliado = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final columnas = ampliado
            ? 1
            : c.maxWidth >= 560
            ? 3
            : 2;
        const espacio = EspaciadoCampo.m;
        final ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: EspaciadoCampo.l,
          children: [
            for (var i = 0; i < evidencias.length; i++)
              SizedBox(
                width: ancho,
                child: _Celda(
                  evidencia: evidencias[i],
                  alTocar: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) =>
                          VisorEvidencias(evidencias: evidencias, inicial: i),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({required this.evidencia, required this.alTocar});

  final EvidenciaServicio evidencia;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final forma = BorderRadius.circular(EspaciadoCampo.m);
    return Semantics(
      button: true,
      label:
          'Evidencia: ${evidencia.tipo.etiqueta}, '
          '${FormatoMarketplace.hora(evidencia.tomadaEn)}. Ver foto',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('evidencia-${evidencia.id}'),
        onTap: alTocar,
        borderRadius: forma,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: forma,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ImagenEvidencia(evidencia),
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Text(evidencia.tipo.etiqueta, style: texto.titleSmall),
            Text(
              FormatoMarketplace.hora(evidencia.tomadaEn),
              style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto completa con su leyenda; se desliza entre evidencias.
class VisorEvidencias extends StatefulWidget {
  const VisorEvidencias({
    required this.evidencias,
    required this.inicial,
    super.key,
  });

  final List<EvidenciaServicio> evidencias;
  final int inicial;

  @override
  State<VisorEvidencias> createState() => _VisorEvidenciasState();
}

class _VisorEvidenciasState extends State<VisorEvidencias> {
  late final _paginas = PageController(initialPage: widget.inicial);
  late int _indice = widget.inicial;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final e = widget.evidencias[_indice];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('${_indice + 1} de ${widget.evidencias.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _paginas,
                itemCount: widget.evidencias.length,
                onPageChanged: (i) => setState(() => _indice = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 4,
                  child: ImagenEvidencia(
                    widget.evidencias[i],
                    ajuste: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(e.tipo.etiqueta, style: texto.titleMedium),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      '${FormatoMarketplace.fechaLarga(e.tomadaEn)}, '
                      '${FormatoMarketplace.hora(e.tomadaEn)}'
                      '${e.nota != null ? '\n${e.nota}' : ''}',
                      style: texto.bodyMedium?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
