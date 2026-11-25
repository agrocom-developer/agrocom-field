import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'chat_cubit.dart';
import '../../../../../l10n/app_localizations.dart';

/// Chat de mensajes con el cliente de una solicitud adjudicada.
class ChatPantalla extends StatelessWidget {
  const ChatPantalla({
    required this.solicitudId,
    this.titulo = 'Chat con el cliente',
    super.key,
  });

  final int solicitudId;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatCubit(context.read<MensajesRepositorio>(), solicitudId)
            ..iniciar(),
      child: Scaffold(
        appBar: AppBar(title: Text(titulo)),
        body: const ChatVista(),
      ),
    );
  }
}

class ChatVista extends StatefulWidget {
  const ChatVista({super.key});

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final ok = await context.read<ChatCubit>().enviar(_texto.text);
    if (ok && mounted) _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ChatCubit, ChatEstado>(
      builder: (context, estado) {
        return Column(
          children: [
            if (estado.sinRed)
              Padding(
                padding: EdgeInsets.all(EspaciadoCampo.m),
                child: AvisoMarketplace(
                  mensaje: l10n.proveedorNegociacionSinConexionVesLos,
                  tono: TonoAviso.alerta,
                  icono: Icons.wifi_off_rounded,
                ),
              ),
            Expanded(
              child: estado.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : estado.mensajes.isEmpty
                  ? EstadoVacioMarketplace(
                      icono: Icons.chat_bubble_outline_rounded,
                      titulo: l10n.proveedorNegociacionTodaviaHayMensajes,
                      detalle: l10n
                          .proveedorNegociacionEscribeleClienteParaCoordinar,
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(EspaciadoCampo.l),
                      itemCount: estado.mensajes.length,
                      itemBuilder: (context, i) {
                        final m =
                            estado.mensajes[estado.mensajes.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: EspaciadoCampo.s,
                          ),
                          child: _Burbuja(mensaje: m),
                        );
                      },
                    ),
            ),
            if (estado.aviso != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspaciadoCampo.l,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: AvisoMarketplace(
                    mensaje: estado.aviso!,
                    tono: TonoAviso.alerta,
                  ),
                ),
              ),
            if (estado.soloLectura)
              Padding(
                padding: EdgeInsets.all(EspaciadoCampo.l),
                child: AvisoMarketplace(
                  mensaje: l10n.proveedorNegociacionServicioCerroPuedesLeer,
                ),
              )
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(EspaciadoCampo.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _texto,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: l10n.proveedorNegociacionEscribeMensaje,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: EspaciadoCampo.s),
                      IconButton.filled(
                        tooltip: l10n.proveedorNegociacionEnviarMensaje,
                        constraints: const BoxConstraints.tightFor(
                          width: ObjetivoTactilCampo.guantes,
                          height: ObjetivoTactilCampo.guantes,
                        ),
                        onPressed: estado.enviando ? null : _enviar,
                        icon: estado.enviando
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final propio = mensaje.propio;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Semantics(
          container: true,
          label:
              '${propio ? 'Tú' : 'El cliente'}, '
              '${FormatoMarketplace.hora(mensaje.creadoEn)}: ${mensaje.texto}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.m,
              vertical: EspaciadoCampo.s,
            ),
            decoration: BoxDecoration(
              color: propio ? paleta.acento : paleta.superficie,
              borderRadius: BorderRadius.circular(RadioCampo.campo),
              border: Border.all(color: propio ? paleta.acento : paleta.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje.texto,
                  style: texto.bodyLarge?.copyWith(
                    color: propio ? paleta.sobreAcento : paleta.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  FormatoMarketplace.hora(mensaje.creadoEn),
                  style: texto.bodySmall?.copyWith(
                    color: propio ? paleta.sobreAcento : paleta.textoSecundario,
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
