import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart'
    show OperacionRechazada;
import '../../../nucleo/marketplace/foto_preparador.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../comun/presentation/foto_remota.dart';
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
import '../../../nucleo/permisos/permiso_app.dart';
import '../../../nucleo/permisos/presentation/asegurar_permiso.dart';

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
        AppLocalizations.of(context).chatTitulo,
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
          etiqueta: AppLocalizations.of(context).chatFotoDe(nombre),
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
                AppLocalizations.of(
                  context,
                ).chatCabecera(s.lote.nombre, s.estado.etiqueta.toLowerCase()),
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

  /// Elige cámara o galería, comprime a menos de 300 KB y envía la foto.
  Future<void> _adjuntar() async {
    final t = AppLocalizations.of(context);
    final origen = await showModalBottomSheet<OrigenFoto>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('chat-foto-camara'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.chatFotoCamara),
              onTap: () => Navigator.of(ctx).pop(OrigenFoto.camara),
            ),
            ListTile(
              key: const ValueKey('chat-foto-galeria'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.chatFotoGaleria),
              onTap: () => Navigator.of(ctx).pop(OrigenFoto.galeria),
            ),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;
    if (origen == OrigenFoto.camara &&
        !await asegurarPermiso(context, PermisoApp.camara)) {
      return;
    }
    if (!mounted) return;
    final cubit = context.read<ChatCubit>();
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final bytes = await context.read<PreparadorFoto>().preparar(origen);
      if (bytes == null) return;
      final ok = await cubit.enviarFoto(bytes);
      if (!ok && mounted && cubit.state.fallo == null) {
        mensajes.showSnackBar(SnackBar(content: Text(t.chatFalloFoto)));
      }
    } on OperacionRechazada catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
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
    final l10n = AppLocalizations.of(context);
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
            queNoCargo: l10n.seguimientoChat2,
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
                    child: AvisoMarketplace(
                      tono: TonoAviso.alerta,
                      icono: Icons.wifi_off_rounded,
                      mensaje: AppLocalizations.of(
                        context,
                      ).chatSinConexionAviso,
                    ),
                  ),
                Expanded(
                  child: estado.mensajes.isEmpty
                      ? EstadoVacioMarketplace(
                          icono: Icons.chat_bubble_outline_rounded,
                          titulo: AppLocalizations.of(context).chatVacioTitulo,
                          detalle: AppLocalizations.of(
                            context,
                          ).chatVacioDetalle,
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
                                _Mensaje(mensaje: m),
                              ],
                            );
                          },
                        ),
                ),
                _Redactor(
                  estado: estado,
                  campo: _campo,
                  alEnviar: _enviar,
                  alAdjuntar: _adjuntar,
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
        ? AppLocalizations.of(context).chatHoy
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

/// Un mensaje según su tipo: texto, foto o evento del sistema.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hora = FormatoMarketplace.hora(mensaje.creadoEn);
    final autor = mensaje.propio ? t.chatAutorTu : t.chatAutorPiloto;
    switch (mensaje.tipo) {
      case TipoMensajeChat.sistema:
        return EventoSistemaChatCampo(texto: mensaje.texto);
      case TipoMensajeChat.foto:
        final ruta = mensaje.ruta;
        return BurbujaFotoChatCampo(
          propio: mensaje.propio,
          hora: hora,
          pie: mensaje.texto,
          etiquetaSemantica: t.chatFotoSemantica(autor, hora, mensaje.texto),
          foto: ruta == null
              ? const SizedBox.shrink()
              : FotoRemota(
                  ruta: ruta,
                  ancho: BurbujaFotoChatCampo.ancho,
                  alto: BurbujaFotoChatCampo.ancho * 0.75,
                  etiqueta: t.chatFotoSemantica(autor, hora, mensaje.texto),
                ),
        );
      case TipoMensajeChat.texto:
        return BurbujaTextoChatCampo(
          texto: mensaje.texto,
          propio: mensaje.propio,
          hora: hora,
          etiquetaSemantica: t.chatMensajeSemantica(autor, hora, mensaje.texto),
        );
    }
  }
}

class _Redactor extends StatelessWidget {
  const _Redactor({
    required this.estado,
    required this.campo,
    required this.alEnviar,
    required this.alAdjuntar,
    required this.margen,
  });

  final ChatEstado estado;
  final TextEditingController campo;
  final VoidCallback alEnviar;
  final VoidCallback alAdjuntar;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    if (estado.soloLectura) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(margen),
          child: AvisoMarketplace(
            key: const ValueKey('chat-solo-lectura'),
            icono: Icons.lock_outline_rounded,
            mensaje: AppLocalizations.of(context).chatCerradoAviso,
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
                      FalloMensaje.sinConexion => AppLocalizations.of(
                        context,
                      ).chatFalloSinConexion,
                      FalloMensaje.cerrado => AppLocalizations.of(
                        context,
                      ).chatFalloCerrado,
                      FalloMensaje.desconocido => AppLocalizations.of(
                        context,
                      ).chatFalloDesconocido,
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
                IconButton(
                  key: const ValueKey('chat-adjuntar'),
                  tooltip: AppLocalizations.of(context).chatAdjuntar,
                  constraints: const BoxConstraints(
                    minWidth: ObjetivoTactilCampo.guantes,
                    minHeight: ObjetivoTactilCampo.guantes,
                  ),
                  onPressed: estado.enviando ? null : alAdjuntar,
                  icon: const Icon(Icons.add_a_photo_outlined),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-campo'),
                    controller: campo,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).chatEscribe,
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
                  label: estado.enviando
                      ? AppLocalizations.of(context).chatEnviando
                      : AppLocalizations.of(context).chatEnviarSemantica,
                  excludeSemantics: true,
                  child: IconButton.filled(
                    key: const ValueKey('chat-enviar'),
                    tooltip: AppLocalizations.of(context).chatEnviar,
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
