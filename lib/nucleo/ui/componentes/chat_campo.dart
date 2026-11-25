import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';

/// Burbuja de texto del chat, sobre `BubbleNormal` de `chat_bubbles` (MIT)
/// estilada con la paleta: lo propio a la derecha en `acento` y lo de la otra
/// parte a la izquierda en `superficie`. Se lee en los tres modos visuales.
///
/// El paquete no dibuja el borde de la burbuja ajena; la separación del fondo
/// la da la `superficie` y la cola. [hora] va en mono dentro de la burbuja.
class BurbujaTextoChatCampo extends StatelessWidget {
  const BurbujaTextoChatCampo({
    required this.texto,
    required this.propio,
    required this.hora,
    required this.etiquetaSemantica,
    super.key,
  });

  final String texto;
  final bool propio;

  /// «10:32», ya formateada.
  final String hora;

  /// Lo que anuncia el lector de pantalla: «Tú, 10:32: …».
  final String etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final color = propio ? paleta.sobreAcento : paleta.texto;
    return Semantics(
      container: true,
      label: etiquetaSemantica,
      excludeSemantics: true,
      child: BubbleNormal(
        text: texto,
        isSender: propio,
        color: propio ? paleta.acento : paleta.superficie,
        tail: true,
        bubbleRadius: RadioCampo.tarjetaCompacta,
        timestamp: hora,
        textStyle: TipografiaCampo.cuerpo.copyWith(color: color),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
      ),
    );
  }
}

/// Burbuja con foto, de [ancho] fijo (200). `chat_bubbles` limita su burbuja
/// de imagen a la mitad de la pantalla, que en un teléfono chico baja de 200;
/// por eso este componente la completa: mismo borde y cola que la burbuja de
/// texto, la foto recortada y la hora sobre un velo grafito.
class BurbujaFotoChatCampo extends StatelessWidget {
  const BurbujaFotoChatCampo({
    required this.foto,
    required this.propio,
    required this.hora,
    required this.etiquetaSemantica,
    this.pie,
    this.alAbrir,
    super.key,
  });

  /// La foto ya resuelta (descargada con la sesión, o un recurso).
  final Widget foto;
  final bool propio;
  final String hora;
  final String etiquetaSemantica;

  /// Texto opcional que acompaña la foto (hasta 280 caracteres).
  final String? pie;
  final VoidCallback? alAbrir;

  /// Ancho de la burbuja con foto (sistema visual, pantalla 11).
  static const double ancho = 200;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    const radio = Radius.circular(RadioCampo.tarjetaCompacta);
    const esquina = Radius.circular(RadioCampo.xs);
    final color = propio ? paleta.sobreAcento : paleta.texto;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        container: true,
        image: true,
        button: alAbrir != null,
        label: etiquetaSemantica,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: alAbrir,
          child: Container(
            width: ancho,
            padding: const EdgeInsets.all(EspaciadoCampo.xs),
            decoration: BoxDecoration(
              color: propio ? paleta.acento : paleta.superficie,
              border: propio ? null : Border.all(color: paleta.borde),
              borderRadius: BorderRadius.only(
                topLeft: radio,
                topRight: radio,
                bottomLeft: propio ? radio : esquina,
                bottomRight: propio ? esquina : radio,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(RadioCampo.chip),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: ancho * 0.75,
                        child: foto,
                      ),
                      Positioned(
                        right: EspaciadoCampo.s,
                        bottom: EspaciadoCampo.s,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: paleta.grafito.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(RadioCampo.xs),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EspaciadoCampo.xs + 2,
                              vertical: 2,
                            ),
                            child: Text(
                              hora,
                              style: TipografiaCampo.datoMono.copyWith(
                                color: paleta.sobreGrafito,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pie != null && pie!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      EspaciadoCampo.xs,
                      EspaciadoCampo.s,
                      EspaciadoCampo.xs,
                      EspaciadoCampo.xs,
                    ),
                    child: Text(
                      pie!,
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Evento del sistema entre los mensajes («La solicitud quedó adjudicada»),
/// en una píldora `acentoContenedor` centrada. No es de ninguna de las dos
/// partes: no lleva cola ni hora y se anuncia como estado.
class EventoSistemaChatCampo extends StatelessWidget {
  const EventoSistemaChatCampo({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: texto,
        excludeSemantics: true,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: EspaciadoCampo.m,
            vertical: EspaciadoCampo.s,
          ),
          decoration: BoxDecoration(
            color: paleta.acentoContenedor,
            borderRadius: BorderRadius.circular(RadioCampo.capsula),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TipografiaCampo.etiqueta.copyWith(
              color: paleta.sobreAcentoContenedor,
            ),
          ),
        ),
      ),
    );
  }
}
