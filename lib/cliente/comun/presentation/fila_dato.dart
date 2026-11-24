import 'package:flutter/material.dart';

import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// «Etiqueta … valor». Con el texto ampliado pasa a dos renglones para que
/// ninguno de los dos se corte.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final ampliado = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final nombre = Text(
      etiqueta,
      style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
    );
    final dato = Text(
      valor,
      textAlign: ampliado ? TextAlign.start : TextAlign.end,
      style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    return MergeSemantics(
      child: ampliado
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [nombre, dato],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nombre,
                const SizedBox(width: EspaciadoCampo.l),
                Expanded(child: dato),
              ],
            ),
    );
  }
}

/// Lista de [FilaDato] separadas por el mismo espacio.
class ListaDatos extends StatelessWidget {
  const ListaDatos(this.filas, {super.key});

  final List<FilaDato> filas;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < filas.length; i++) ...[
        if (i > 0) const SizedBox(height: EspaciadoCampo.m),
        filas[i],
      ],
    ],
  );
}

/// Título de una sección dentro de una pantalla.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: EspaciadoCampo.xxl,
      bottom: EspaciadoCampo.m,
    ),
    child: Semantics(
      header: true,
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
