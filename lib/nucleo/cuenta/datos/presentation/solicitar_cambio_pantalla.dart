import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/dominio/falla.dart';
import '../../../marketplace/ui/campo_formulario_marketplace.dart';
import '../../../marketplace/ui/marketplace_ui.dart';
import '../../../ui/componentes/componentes_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/datos_personales_repositorio.dart';

/// «Solicitar un cambio»: el motivo escrito va a atención al cliente, donde un
/// administrador lo revisa. Se cierra con `true` si la solicitud se envió.
class SolicitarCambioPantalla extends StatefulWidget {
  const SolicitarCambioPantalla({required this.repositorio, super.key});

  final DatosPersonalesRepositorio repositorio;

  @override
  State<SolicitarCambioPantalla> createState() =>
      _SolicitarCambioPantallaState();
}

class _SolicitarCambioPantallaState extends State<SolicitarCambioPantalla> {
  static const _minimo = 10;

  final _clave = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  bool _enviando = false;
  bool _enviada = false;
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_clave.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.repositorio.solicitarCambio(_motivo.text.trim());
      if (mounted) setState(() => _enviada = true);
    } on SinConexion {
      if (mounted) _fallo(t.datosPersonalesErrorSinConexion);
    } on OperacionRechazada catch (e) {
      if (mounted) {
        _fallo(
          e.motivo == 'solicitud_abierta'
              ? t.datosPersonalesSolicitudAbierta
              : t.datosPersonalesErrorEnviar,
        );
      }
    } on Object {
      if (mounted) _fallo(t.datosPersonalesErrorEnviar);
    }
  }

  void _fallo(String mensaje) => setState(() {
    _enviando = false;
    _error = mensaje;
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.datosPersonalesSolicitar)),
      body: _enviada ? _Enviada(alTerminar: _cerrar) : _formulario(t),
    );
  }

  void _cerrar() => Navigator.of(context).pop(true);

  Widget _formulario(AppLocalizations t) {
    final texto = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _clave,
            child: ListView(
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: EntradaCampo.escalonar([
                Text(
                  t.datosPersonalesSolicitarIntro,
                  style: texto.bodyLarge?.copyWith(
                    color: context.paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                CampoFormularioMarketplace(
                  etiqueta: t.datosPersonalesMotivo,
                  controller: _motivo,
                  enabled: !_enviando,
                  ayuda: t.datosPersonalesMotivoAyuda,
                  minLines: 4,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v ?? '').trim().length < _minimo
                      ? t.datosPersonalesMotivoCorto
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: EspaciadoCampo.l),
                  AvisoMarketplace(
                    key: const Key('solicitar-cambio-error'),
                    mensaje: _error!,
                    tono: TonoAviso.error,
                  ),
                ],
              ]),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            child: SizedBox(
              width: double.infinity,
              child: BotonPrimarioCampo(
                key: const Key('solicitar-cambio-enviar'),
                texto: t.datosPersonalesEnviar,
                cargando: _enviando,
                onPressed: _enviar,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Éxito: confirma que la solicitud llegó y qué pasa ahora.
class _Enviada extends StatelessWidget {
  const _Enviada({required this.alTerminar});

  final VoidCallback alTerminar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Padding(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      child: Column(
        children: [
          const Spacer(),
          EntradaCampo(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: paleta.acentoContenedor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 44,
                    color: paleta.sobreAcentoContenedor,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                Text(
                  t.datosPersonalesEnviada,
                  textAlign: TextAlign.center,
                  style: texto.headlineSmall,
                ),
                const SizedBox(height: EspaciadoCampo.m),
                Text(
                  t.datosPersonalesEnviadaDetalle,
                  textAlign: TextAlign.center,
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: BotonPrimarioCampo(
                key: const Key('solicitar-cambio-listo'),
                texto: t.datosPersonalesListo,
                onPressed: alTerminar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
