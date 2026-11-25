import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../comun/presentation/estado_falla.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../../solicitudes/domain/solicitudes_repositorio.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';
import 'chat_cubit.dart';

/// Chat de texto con el piloto adjudicado. Los mensajes llegan por sondeo
/// corto mientras la pantalla está abierta; el cliente escribe en línea y, si
/// el envío falla, el texto queda en el campo para reintentar.
class ChatPantalla extends StatefulWidget {
  const ChatPantalla({
    required this.solicitudId,
    this.intervalo = const Duration(seconds: 5),
    super.key,
  });

  final String solicitudId;

  /// Cada cuánto se leen los mensajes nuevos; `null` lo apaga.
  final Duration? intervalo;

  @override
  State<ChatPantalla> createState() => _ChatPantallaState();
}

class _ChatPantallaState extends State<ChatPantalla> {
  /// El servicio, para la cabecera (piloto y lote). Si no carga, la
  /// cabecera queda genérica: el chat funciona igual.
  Solicitud? _solicitud;

  @override
  void initState() {
    super.initState();
    _cargarSolicitud();
  }

  Future<void> _cargarSolicitud() async {
    try {
      final s = await context.read<SolicitudesRepositorio>().porId(
        widget.solicitudId,
      );
      if (mounted) setState(() => _solicitud = s);
    } on Object {
      // La cabecera genérica basta.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(
        repositorio: context.read<SeguimientoRepositorio>(),
        solicitudId: widget.solicitudId,
        intervalo: widget.intervalo,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(
          title: _Cabecera(solicitud: _solicitud),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: context.paleta.borde),
          ),
        ),
        body: const _Cuerpo(),
      ),
    );
  }
}

/// Avatar con iniciales, nombre del piloto y «lote · estado».
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.solicitud});

  final Solicitud? solicitud;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final s = solicitud;
    final nombre = s?.nombreProveedor;
    if (s == null || nombre == null) {
      return Text(
        'Chat con el piloto',
        style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
      );
    }
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Row(
      children: [
        AvatarFoto(
          iniciales: iniciales,
          etiqueta: 'Foto de $nombre',
          tamano: ObjetivoTactilCampo.minimo - EspaciadoCampo.s,
        ),
        const SizedBox(width: EspaciadoCampo.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                overflow: TextOverflow.ellipsis,
                style: TipografiaCampo.tituloSeccion.copyWith(
                  color: paleta.texto,
                ),
              ),
              Text(
                '${s.lote.nombre} · ${s.estado.etiqueta.toLowerCase()}',
                overflow: TextOverflow.ellipsis,
                style: TipografiaCampo.cuerpoSecundario.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
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
                          itemBuilder: (context, i) {
                            final m = estado.mensajes[i];
                            final nuevoDia =
                                i == 0 ||
                                !_mismoDia(
                                  estado.mensajes[i - 1].creadoEn,
                                  m.creadoEn,
                                );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (nuevoDia) _SeparadorDia(dia: m.creadoEn),
                                _Burbuja(mensaje: m),
                              ],
                            );
                          },
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

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// «HOY» o la fecha, en mono, centrada entre los mensajes de cada día.
class _SeparadorDia extends StatelessWidget {
  const _SeparadorDia({required this.dia});

  final DateTime dia;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final texto = _mismoDia(dia, hoy)
        ? 'HOY'
        : FormatoMarketplace.fechaCorta(dia).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
      child: Center(
        child: Text(
          texto,
          style: TipografiaCampo.etiquetaMono.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ),
    );
  }
}

/// Mensaje propio en verde a la derecha; del piloto en superficie con borde
/// a la izquierda. La hora va en mono debajo del texto.
class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final propio = mensaje.propio;
    final color = propio ? paleta.sobreAcento : paleta.texto;
    const radio = Radius.circular(RadioCampo.tarjetaCompacta);
    const esquina = Radius.circular(RadioCampo.xs);
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
              horizontal: EspaciadoCampo.l,
              vertical: EspaciadoCampo.m,
            ),
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
              children: [
                Text(
                  mensaje.texto,
                  style: TipografiaCampo.cuerpo.copyWith(color: color),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  '${propio ? 'Tú' : 'Piloto'} · '
                  '${FormatoMarketplace.hora(mensaje.creadoEn)}',
                  style: TipografiaCampo.datoMono.copyWith(color: color),
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
                    style: TipografiaCampo.cuerpoSecundario.copyWith(
                      color: paleta.error,
                    ),
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
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                      filled: true,
                      fillColor: paleta.superficie,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadioCampo.capsula),
                        borderSide: BorderSide(color: paleta.bordeFuerte),
                      ),
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
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: paleta.sobreAcento,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
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
        EsqueletoCampo(alto: 56, ancho: 240, radio: RadioCampo.campo),
        SizedBox(height: EspaciadoCampo.s),
        Align(
          alignment: Alignment.centerRight,
          child: EsqueletoCampo(alto: 44, ancho: 200, radio: RadioCampo.campo),
        ),
        SizedBox(height: EspaciadoCampo.s),
        EsqueletoCampo(alto: 56, ancho: 260, radio: RadioCampo.campo),
      ],
    ),
  );
}
