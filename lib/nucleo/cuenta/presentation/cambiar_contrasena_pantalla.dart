import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../marketplace/ui/aviso_marketplace.dart';
import '../../marketplace/ui/campo_formulario_marketplace.dart';
import '../../ui/componentes/boton_primario_campo.dart';
import '../../ui/componentes/entrada_campo.dart';
import '../../ui/componentes/icono_burbuja_campo.dart';
import '../../ui/paleta_campo.dart';
import '../../ui/tokens_campo.dart';
import '../domain/contrasena_repositorio.dart';
import 'cambiar_contrasena_cubit.dart';

/// Cambiar la contraseña con un código: elegir dónde recibirlo, escribirlo
/// con la contraseña nueva y ver la confirmación. Un solo formulario de una
/// columna por paso, con la acción principal al pie. Lee el
/// [ContrasenaRepositorio] del contexto.
class CambiarContrasenaPantalla extends StatelessWidget {
  const CambiarContrasenaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => CambiarContrasenaCubit(
        context.read<ContrasenaRepositorio>(),
        textoSinRed: t.contrasenaErrorSinRed,
        textoCanalNoDisponible: t.contrasenaErrorCanalNoDisponible,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(t.contrasenaTitulo)),
        body: SafeArea(
          child: BlocBuilder<CambiarContrasenaCubit, CambiarContrasenaEstado>(
            buildWhen: (a, b) => a.paso != b.paso,
            builder: (context, estado) => AnimatedSwitcher(
              duration: MovimientoCampo.duracion(
                context,
                MovimientoCampo.media,
              ),
              switchInCurve: MovimientoCampo.entrada,
              switchOutCurve: MovimientoCampo.salida,
              child: switch (estado.paso) {
                PasoContrasena.canal => const _PasoCanal(
                  key: ValueKey('paso-canal'),
                ),
                PasoContrasena.codigo => const _PasoCodigo(
                  key: ValueKey('paso-codigo'),
                ),
                PasoContrasena.listo => const _PasoListo(
                  key: ValueKey('paso-listo'),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenido que se desplaza y, fijo abajo (zona del pulgar), la acción.
class _Pagina extends StatelessWidget {
  const _Pagina({required this.hijos, required this.accion});

  final List<Widget> hijos;
  final Widget accion;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              EspaciadoCampo.l,
              EspaciadoCampo.l,
              EspaciadoCampo.l,
              EspaciadoCampo.xl,
            ),
            children: EntradaCampo.escalonar(hijos),
          ),
        ),
        Padding(padding: const EdgeInsets.all(EspaciadoCampo.l), child: accion),
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CambiarContrasenaCubit, CambiarContrasenaEstado>(
      buildWhen: (a, b) =>
          a.mensaje != b.mensaje || a.sinConexion != b.sinConexion,
      builder: (context, estado) {
        final mensaje = estado.mensaje;
        if (mensaje == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: EspaciadoCampo.l),
          child: Semantics(
            liveRegion: true,
            child: AvisoMarketplace(
              key: const Key('contrasena-aviso'),
              mensaje: mensaje,
              tono: estado.sinConexion ? TonoAviso.alerta : TonoAviso.error,
              icono: estado.sinConexion ? Icons.wifi_off_rounded : null,
            ),
          ),
        );
      },
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.titulo, this.detalle);

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(titulo, style: texto.headlineSmall),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          detalle,
          style: texto.bodyLarge?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _PasoCanal extends StatelessWidget {
  const _PasoCanal({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<CambiarContrasenaCubit>();
    return BlocBuilder<CambiarContrasenaCubit, CambiarContrasenaEstado>(
      builder: (context, estado) {
        final opciones = [
          (CanalCodigo.whatsapp, t.contrasenaCanalWhatsapp, Icons.chat_rounded),
          (CanalCodigo.sms, t.contrasenaCanalSms, Icons.sms_rounded),
          (CanalCodigo.correo, t.contrasenaCanalCorreo, Icons.mail_rounded),
        ];
        return _Pagina(
          hijos: [
            _Titulo(t.contrasenaCanalTitulo, t.contrasenaCanalDetalle),
            const SizedBox(height: EspaciadoCampo.xl),
            const _AvisoError(),
            for (final (canal, etiqueta, icono) in opciones) ...[
              _OpcionCanal(
                clave: Key('contrasena-canal-${canal.name}'),
                icono: icono,
                etiqueta: etiqueta,
                elegida: estado.canal == canal,
                alToque: estado.enviando
                    ? null
                    : () => cubit.elegirCanal(canal),
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
          ],
          accion: BotonPrimarioCampo(
            key: const Key('contrasena-enviar-codigo'),
            texto: t.contrasenaEnviarCodigo,
            cargando: estado.enviando,
            onPressed: cubit.pedirCodigo,
          ),
        );
      },
    );
  }
}

class _OpcionCanal extends StatelessWidget {
  const _OpcionCanal({
    required this.clave,
    required this.icono,
    required this.etiqueta,
    required this.elegida,
    required this.alToque,
  });

  final Key clave;
  final IconData icono;
  final String etiqueta;
  final bool elegida;
  final VoidCallback? alToque;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: elegida,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alToque,
      child: GestureDetector(
        key: clave,
        onTap: alToque,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.rapida),
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.minimo + EspaciadoCampo.l,
          ),
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          decoration: BoxDecoration(
            color: paleta.superficie,
            borderRadius: BorderRadius.circular(RadioCampo.media),
            border: Border.all(
              color: elegida ? paleta.acentoTexto : paleta.borde,
              width: elegida ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              IconoBurbujaCampo(icono),
              const SizedBox(width: EspaciadoCampo.l),
              Expanded(
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                elegida
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: elegida ? paleta.acentoTexto : paleta.bordeFuerte,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasoCodigo extends StatefulWidget {
  const _PasoCodigo({super.key});

  @override
  State<_PasoCodigo> createState() => _PasoCodigoState();
}

class _PasoCodigoState extends State<_PasoCodigo> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _intentado = false;

  @override
  void dispose() {
    _codigo.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _intentado = true);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<CambiarContrasenaCubit>().cambiar(
      codigo: _codigo.text,
      passwordNueva: _nueva.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<CambiarContrasenaCubit>();
    return BlocBuilder<CambiarContrasenaCubit, CambiarContrasenaEstado>(
      builder: (context, estado) {
        final bloqueado = estado.enviando;
        return Form(
          key: _formulario,
          autovalidateMode: _intentado
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: _Pagina(
            hijos: [
              _Titulo(
                t.contrasenaCodigoTitulo,
                t.contrasenaCodigoEnviadoA(estado.destino ?? ''),
              ),
              const SizedBox(height: EspaciadoCampo.xl),
              const _AvisoError(),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CampoFormularioMarketplace(
                      key: const Key('contrasena-codigo'),
                      etiqueta: t.contrasenaCampoCodigo,
                      controller: _codigo,
                      enabled: !bloqueado,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          ReglasContrasena.largoCodigo,
                        ),
                      ],
                      validator: ReglasContrasena.codigo,
                      errorServidor: estado.codigoInvalido
                          ? estado.mensaje
                          : null,
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    CampoFormularioMarketplace(
                      key: const Key('contrasena-nueva'),
                      etiqueta: t.contrasenaCampoNueva,
                      ayuda: t.contrasenaCampoNuevaAyuda,
                      controller: _nueva,
                      enabled: !bloqueado,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: ReglasContrasena.nueva,
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    CampoFormularioMarketplace(
                      key: const Key('contrasena-repetir'),
                      etiqueta: t.contrasenaCampoRepetir,
                      controller: _repetir,
                      enabled: !bloqueado,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) =>
                          ReglasContrasena.confirmacion(v, _nueva.text),
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('contrasena-pedir-otro'),
                  onPressed: bloqueado ? null : cubit.pedirOtro,
                  child: Text(t.contrasenaPedirOtro),
                ),
              ),
            ],
            accion: BotonPrimarioCampo(
              key: const Key('contrasena-guardar'),
              texto: t.contrasenaGuardar,
              cargando: bloqueado,
              onPressed: _enviar,
            ),
          ),
        );
      },
    );
  }
}

class _PasoListo extends StatelessWidget {
  const _PasoListo({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return _Pagina(
      hijos: [
        const SizedBox(height: EspaciadoCampo.xxl),
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: paleta.acentoContenedor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 64,
              color: paleta.sobreAcentoContenedor,
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            t.contrasenaListoTitulo,
            textAlign: TextAlign.center,
            style: texto.headlineSmall,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          t.contrasenaListoDetalle,
          textAlign: TextAlign.center,
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
        ),
      ],
      accion: BotonPrimarioCampo(
        key: const Key('contrasena-volver'),
        texto: t.contrasenaVolverAjustes,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
