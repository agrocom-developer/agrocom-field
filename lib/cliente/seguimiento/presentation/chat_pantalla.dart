import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../comun/presentation/estado_falla.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';
import 'chat_cubit.dart';

/// Chat de texto con el piloto adjudicado. Los mensajes llegan por sondeo
/// corto mientras la pantalla está abierta; el cliente escribe en línea y, si
/// el envío falla, el texto queda en el campo para reintentar.
class ChatPantalla extends StatelessWidget {
  const ChatPantalla({
    required this.solicitudId,
    this.intervalo = const Duration(seconds: 5),
    super.key,
  });

  final String solicitudId;

  /// Cada cuánto se leen los mensajes nuevos; `null` lo apaga.
  final Duration? intervalo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(
        repositorio: context.read<SeguimientoRepositorio>(),
        solicitudId: solicitudId,
        intervalo: intervalo,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat con el piloto')),
        body: const _Cuerpo(),
      ),
    );
  }
}

class _Cuerpo extends StatefulWidget {
  const _Cuerpo();

  @override
  State<_Cuerpo> createState() => _CuerpoState();
}

class _CuerpoState extends State<_Cuerpo> {
  final _campo = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _campo.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final cubit = context.read<ChatCubit>();
    final texto = _campo.text;
    final ok = await cubit.enviar(texto);
    // Solo se vacía el campo si el servidor lo confirmó.
    if (ok && mounted) _campo.clear();
  }

  void _alFinal() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
      curve: MovimientoCampo.movimiento,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatEstado>(
      listenWhen: (a, b) => a.mensajes.length != b.mensajes.length,
      listener: (context, _) =>
          WidgetsBinding.instance.addPostFrameCallback((_) => _alFinal()),
      builder: (context, estado) {
        final cubit = context.read<ChatCubit>();
        if (estado.fase == FaseChat.cargando) return const _Cargando();
        if (estado.fase == FaseChat.error) {
          return EstadoFalla(
            sinConexion: estado.sinConexion,
            queNoCargo: 'el chat',
            alReintentar: cubit.cargar,
          );
        }
        final margen = EspaciadoCampo.margenLateral(
          MediaQuery.sizeOf(context).width,
        );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (estado.sinConexion)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      margen,
                      EspaciadoCampo.s,
                      margen,
                      0,
                    ),
                    child: const AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.wifi_off_rounded,
                      mensaje:
                          'Sin conexión. Los mensajes nuevos llegan cuando '
                          'vuelva la señal.',
                    ),
                  ),
                Expanded(
                  child: estado.mensajes.isEmpty
                      ? const EstadoVacioMarketplace(
                          icono: Icons.chat_bubble_outline_rounded,
                          titulo: 'Todavía no hay mensajes',
                          detalle:
                              'Escríbele al piloto para coordinar el día de '
                              'la visita y los accesos al lote.',
                        )
                      : ListView.separated(
                          controller: _scroll,
                          padding: EdgeInsets.symmetric(
                            horizontal: margen,
                            vertical: EspaciadoCampo.l,
                          ),
                          itemCount: estado.mensajes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: EspaciadoCampo.s),
                          itemBuilder: (context, i) =>
                              _Burbuja(mensaje: estado.mensajes[i]),
                        ),
                ),
                _Redactor(
                  estado: estado,
                  campo: _campo,
                  alEnviar: _enviar,
                  margen: margen,
                ),
              ],
            ),
          ),
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
    final fondo = propio
        ? Color.alphaBlend(
            paleta.acento.withValues(alpha: 0.22),
            paleta.superficie,
          )
        : paleta.superficie;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Semantics(
          label:
              '${propio ? 'Tú' : 'Piloto'}, '
              '${FormatoMarketplace.hora(mensaje.creadoEn)}: ${mensaje.texto}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.m,
              vertical: EspaciadoCampo.s,
            ),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(RadioCampo.campo),
              border: Border.all(
                color: propio ? paleta.acentoTexto : paleta.borde,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mensaje.texto, style: texto.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${propio ? 'Tú' : 'Piloto'} · '
                  '${FormatoMarketplace.hora(mensaje.creadoEn)}',
                  style: texto.bodySmall?.copyWith(
                    color: paleta.textoSecundario,
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

class _Redactor extends StatelessWidget {
  const _Redactor({
    required this.estado,
    required this.campo,
    required this.alEnviar,
    required this.margen,
  });

  final ChatEstado estado;
  final TextEditingController campo;
  final VoidCallback alEnviar;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    if (estado.soloLectura) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(margen),
          child: const AvisoMarketplace(
            key: ValueKey('chat-solo-lectura'),
            icono: Icons.lock_outline_rounded,
            mensaje:
                'El chat se cerró. Puedes leer lo conversado, pero ya no '
                'escribir.',
          ),
        ),
      );
    }
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          margen,
          EspaciadoCampo.s,
          margen,
          EspaciadoCampo.s,
        ),
        decoration: BoxDecoration(
          color: paleta.fondo,
          border: Border(top: BorderSide(color: paleta.borde)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (estado.fallo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    switch (estado.fallo!) {
                      FalloMensaje.sinConexion =>
                        'Sin conexión. Tu mensaje sigue acá; envíalo cuando '
                            'vuelva la señal.',
                      FalloMensaje.cerrado =>
                        'El chat se cerró y no se envió tu mensaje.',
                      FalloMensaje.desconocido =>
                        'No pudimos enviarlo. Tu mensaje sigue acá; prueba '
                            'de nuevo.',
                    },
                    key: const ValueKey('chat-fallo'),
                    style: texto.bodySmall?.copyWith(color: paleta.error),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-campo'),
                    controller: campo,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: EspaciadoCampo.s),
                Semantics(
                  button: true,
                  label: estado.enviando ? 'Enviando' : 'Enviar mensaje',
                  excludeSemantics: true,
                  child: IconButton.filled(
                    key: const ValueKey('chat-enviar'),
                    tooltip: 'Enviar',
                    constraints: const BoxConstraints(
                      minWidth: ObjetivoTactilCampo.guantes,
                      minHeight: ObjetivoTactilCampo.guantes,
                    ),
                    onPressed: estado.enviando ? null : alEnviar,
                    icon: estado.enviando
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(EspaciadoCampo.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: 56, ancho: 240, radio: 16),
        SizedBox(height: EspaciadoCampo.s),
        Align(
          alignment: Alignment.centerRight,
          child: EsqueletoCampo(alto: 44, ancho: 200, radio: 16),
        ),
        SizedBox(height: EspaciadoCampo.s),
        EsqueletoCampo(alto: 56, ancho: 260, radio: 16),
      ],
    ),
  );
}
