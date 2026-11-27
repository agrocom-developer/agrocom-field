import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/aviso_marketplace.dart';
import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../marketplace/ui/campo_formulario_marketplace.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'flujo_codigo_cubit.dart';
import 'textos_cuenta_seguridad.dart';

IconData iconoDeCanal(CanalCodigo c) => switch (c) {
  CanalCodigo.whatsapp => Icons.chat_outlined,
  CanalCodigo.sms => Icons.sms_outlined,
  CanalCodigo.correo => Icons.mail_outline_rounded,
};

/// Aviso de una falla de cuenta, con región viva para el lector de pantalla.
/// Una falla de red o de canal es una alerta; el resto, un error.
class AvisoFallaCuenta extends StatelessWidget {
  const AvisoFallaCuenta({
    required this.falla,
    this.alternativas = const [],
    super.key,
  });

  final CuentaFalla falla;
  final List<CanalCodigo> alternativas;

  @override
  Widget build(BuildContext context) {
    final alerta =
        falla is CuentaSinConexion ||
        falla is CuentaCanalNoDisponible ||
        falla is CuentaLimiteExcedido;
    return Semantics(
      liveRegion: true,
      child: AvisoMarketplace(
        mensaje: TextosCuentaSeguridad.falla(
          AppLocalizations.of(context),
          falla,
          alternativas: alternativas,
        ),
        tono: alerta ? TonoAviso.alerta : TonoAviso.error,
        icono: falla is CuentaSinConexion ? Icons.wifi_off_rounded : null,
      ),
    );
  }
}

/// Las opciones de canal: un toque en una envía el código (una sola acción).
/// Un canal que el servidor no tiene configurado queda apagado y explicado.
class SelectorCanalCodigo extends StatelessWidget {
  const SelectorCanalCodigo({
    required this.canales,
    required this.alElegir,
    this.caidos = const {},
    this.enviandoCanal,
    this.bloqueado = false,
    super.key,
  });

  final List<CanalCodigo> canales;
  final Set<CanalCodigo> caidos;
  final CanalCodigo? enviandoCanal;

  /// Sin interacción (enviando, o esperando tras un límite).
  final bool bloqueado;
  final ValueChanged<CanalCodigo> alElegir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final canal in canales)
          Padding(
            padding: const EdgeInsets.only(bottom: EspaciadoCampo.s),
            child: _OpcionCanal(
              key: Key('canal-${canal.codigo}'),
              canal: canal,
              caido: caidos.contains(canal),
              enviando: enviandoCanal == canal,
              deshabilitado: bloqueado,
              alToque: () => alElegir(canal),
              estiloTitulo: texto.titleMedium,
              estiloDetalle: texto.bodyMedium?.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
          ),
      ],
    );
  }
}

class _OpcionCanal extends StatelessWidget {
  const _OpcionCanal({
    required this.canal,
    required this.caido,
    required this.enviando,
    required this.deshabilitado,
    required this.alToque,
    required this.estiloTitulo,
    required this.estiloDetalle,
    super.key,
  });

  final CanalCodigo canal;
  final bool caido;
  final bool enviando;
  final bool deshabilitado;
  final VoidCallback alToque;
  final TextStyle? estiloTitulo;
  final TextStyle? estiloDetalle;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final apagado = caido || deshabilitado;
    final l10n = AppLocalizations.of(context);
    final nombre = TextosCuentaSeguridad.canal(l10n, canal);
    final detalle = caido
        ? l10n.cuentaCanalNoDisponible
        : TextosCuentaSeguridad.detalleCanal(l10n, canal);
    return Semantics(
      button: true,
      enabled: !apagado,
      label: '$nombre. $detalle',
      excludeSemantics: true,
      child: Material(
        color: paleta.superficie,
        borderRadius: BorderRadius.circular(RadioCampo.media),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadioCampo.media),
          onTap: apagado
              ? null
              : () {
                  HapticaCampo.seleccion();
                  alToque();
                },
          child: Container(
            constraints: const BoxConstraints(
              minHeight: ObjetivoTactilCampo.guantes,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.l,
              vertical: EspaciadoCampo.m,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: paleta.bordeFuerte),
              borderRadius: BorderRadius.circular(RadioCampo.media),
            ),
            child: Row(
              children: [
                Icon(
                  iconoDeCanal(canal),
                  color: apagado ? paleta.textoSecundario : paleta.acentoTexto,
                ),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: estiloTitulo?.copyWith(
                          color: apagado ? paleta.textoSecundario : null,
                        ),
                      ),
                      Text(detalle, style: estiloDetalle),
                    ],
                  ),
                ),
                if (enviando)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else if (!apagado)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: paleta.textoSecundario,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El recorrido completo de un flujo de código: elegir canal y escribir el
/// código (más la contraseña nueva si [pideContrasenaNueva]). Lo que ocurre
/// al confirmar lo decide quien lo aloja, escuchando la etapa `listo`.
class FlujoCodigoVista extends StatefulWidget {
  const FlujoCodigoVista({
    required this.tituloElegir,
    required this.detalleElegir,
    required this.textoConfirmar,
    this.pideContrasenaNueva = false,
    this.antesDelSelector,
    this.validarAntesDeEnviar,
    this.envioCondicional = false,
    super.key,
  });

  final String tituloElegir;
  final String detalleElegir;
  final String textoConfirmar;
  final bool pideContrasenaNueva;

  /// Contenido propio sobre el selector de canal (el identificador de la
  /// recuperación, por ejemplo).
  final Widget? antesDelSelector;

  /// Se consulta antes de pedir el código; con `false` no se envía nada.
  final bool Function()? validarAntesDeEnviar;

  /// El servidor no confirma si la cuenta existe (recuperación del acceso):
  /// el texto dice «si existe una cuenta».
  final bool envioCondicional;

  @override
  State<FlujoCodigoVista> createState() => _FlujoCodigoVistaState();
}

class _FlujoCodigoVistaState extends State<FlujoCodigoVista> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _confirmar(FlujoCodigoCubit cubit) {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    cubit.confirmarCodigo(
      _codigo.text,
      contrasenaNueva: widget.pideContrasenaNueva ? _contrasena.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FlujoCodigoCubit>();
    return BlocBuilder<FlujoCodigoCubit, FlujoCodigoEstado>(
      builder: (context, estado) {
        return AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          switchOutCurve: MovimientoCampo.salida,
          child: KeyedSubtree(
            key: ValueKey(estado.etapa == EtapaCodigo.elegirCanal),
            child: estado.etapa == EtapaCodigo.elegirCanal
                ? _elegir(context, cubit, estado)
                : _escribir(context, cubit, estado),
          ),
        );
      },
    );
  }

  Widget _elegir(
    BuildContext context,
    FlujoCodigoCubit cubit,
    FlujoCodigoEstado estado,
  ) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final enEspera = estado.limitado && estado.reenvioEn > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(widget.tituloElegir, style: texto.titleLarge),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          widget.detalleElegir,
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
        if (widget.antesDelSelector != null) ...[
          const SizedBox(height: EspaciadoCampo.l),
          widget.antesDelSelector!,
        ],
        const SizedBox(height: EspaciadoCampo.l),
        if (estado.falla != null) ...[
          AvisoFallaCuenta(
            falla: estado.falla!,
            // El canal caído ya no está entre los disponibles.
            alternativas: cubit.disponibles,
          ),
          const SizedBox(height: EspaciadoCampo.l),
        ],
        SelectorCanalCodigo(
          canales: cubit.canales,
          caidos: estado.canalesCaidos,
          enviandoCanal: estado.enviando ? estado.canal : null,
          bloqueado: estado.enviando || enEspera,
          alElegir: (canal) {
            if (widget.validarAntesDeEnviar?.call() ?? true) {
              cubit.enviar(canal);
            }
          },
        ),
        if (enEspera)
          Padding(
            padding: const EdgeInsets.only(top: EspaciadoCampo.s),
            child: Text(
              AppLocalizations.of(context).cuentaCodigoPodrasPedirEn(
                TextosCuentaSeguridad.espera(estado.reenvioEn),
              ),
              key: const Key('espera-limite'),
              textAlign: TextAlign.center,
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
          ),
      ],
    );
  }

  Widget _escribir(
    BuildContext context,
    FlujoCodigoCubit cubit,
    FlujoCodigoEstado estado,
  ) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final canal = estado.canal;
    final l10n = AppLocalizations.of(context);
    final destino = estado.destino;
    final condicional = widget.envioCondicional;
    final envio = destino != null
        ? (condicional
              ? l10n.cuentaCodigoEnvioCondicionalA(destino)
              : l10n.cuentaCodigoEnvioA(destino))
        : canal != null
        ? (condicional
              ? l10n.cuentaCodigoEnvioCondicionalPor(
                  TextosCuentaSeguridad.canal(l10n, canal),
                )
              : l10n.cuentaCodigoEnvioPor(
                  TextosCuentaSeguridad.canal(l10n, canal),
                ))
        : (condicional
              ? l10n.cuentaCodigoEnvioCondicional
              : l10n.cuentaCodigoEnvio);
    return Form(
      key: _formulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.cuentaCodigoEscribe, style: texto.titleLarge),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            l10n.cuentaCodigoVence(envio),
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.l),
          if (estado.falla != null) ...[
            AvisoFallaCuenta(falla: estado.falla!),
            const SizedBox(height: EspaciadoCampo.l),
          ],
          CampoFormularioMarketplace(
            key: const Key('campo-codigo'),
            etiqueta: l10n.cuentaCodigoEtiqueta,
            controller: _codigo,
            enabled: !estado.ocupado,
            keyboardType: TextInputType.number,
            textInputAction: widget.pideContrasenaNueva
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(ReglasCodigo.largo),
            ],
            validator: (valor) => switch (ReglasCodigo.validar(valor)) {
              null => null,
              MotivoCodigoInvalido.vacio => l10n.cuentaCodigoEscribeSeisDigitos,
              MotivoCodigoInvalido.formato => l10n.cuentaCodigoTieneSeisDigitos,
            },
            onChanged: (_) => cubit.limpiarFalla(),
            onFieldSubmitted: widget.pideContrasenaNueva
                ? null
                : (_) => _confirmar(cubit),
          ),
          if (widget.pideContrasenaNueva) ...[
            const SizedBox(height: EspaciadoCampo.l),
            CampoFormularioMarketplace(
              key: const Key('campo-contrasena-nueva'),
              etiqueta: l10n.cuentaContrasenaNuevaEtiqueta,
              controller: _contrasena,
              enabled: !estado.ocupado,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              ayuda: l10n.cuentaContrasenaMinimo(ReglasContrasena.largoMinimo),
              validator: ReglasContrasena.validarNueva,
              errorServidor: estado.falla is CuentaDatosInvalidos
                  ? (estado.falla! as CuentaDatosInvalidos)
                        .porCampo['password_nueva']
                  : null,
              onChanged: (_) => cubit.limpiarFalla(),
              onFieldSubmitted: (_) => _confirmar(cubit),
            ),
          ],
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrincipalMarketplace(
            key: const Key('confirmar-codigo'),
            texto: widget.textoConfirmar,
            alto: ObjetivoTactilCampo.guantes,
            cargando: estado.confirmando,
            onPressed: () => _confirmar(cubit),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          _Reenvio(cubit: cubit, estado: estado),
        ],
      ),
    );
  }
}

class _Reenvio extends StatelessWidget {
  const _Reenvio({required this.cubit, required this.estado});

  final FlujoCodigoCubit cubit;
  final FlujoCodigoEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    final espera = estado.reenvioEn > 0;
    return Column(
      children: [
        TextButton(
          key: const Key('reenviar-codigo'),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
          ),
          onPressed: estado.puedeReenviar ? cubit.reenviar : null,
          child: Text(
            espera
                ? l10n.cuentaCodigoReenviarEn(
                    TextosCuentaSeguridad.espera(estado.reenvioEn),
                  )
                : l10n.cuentaCodigoReenviar,
          ),
        ),
        TextButton(
          key: const Key('cambiar-canal'),
          style: TextButton.styleFrom(
            foregroundColor: paleta.acentoTexto,
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.minimo),
          ),
          onPressed: estado.ocupado ? null : cubit.cambiarCanal,
          child: Text(l10n.cuentaCodigoOtroMedio),
        ),
      ],
    );
  }
}
