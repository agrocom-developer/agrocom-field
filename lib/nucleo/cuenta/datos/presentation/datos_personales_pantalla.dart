import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/marketplace_ui.dart';
import '../../../ui/componentes/componentes_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../../marketplace/ui/campo_formulario_marketplace.dart';
import '../domain/datos_personales.dart';
import '../domain/datos_personales_repositorio.dart';
import 'datos_personales_cubit.dart';
import 'solicitar_cambio_pantalla.dart';

/// Datos personales de la cuenta. Mientras la persona no use su única edición
/// se muestra un formulario; después queda de solo lectura y ofrece
/// «Solicitar un cambio» a atención al cliente.
class DatosPersonalesPantalla extends StatelessWidget {
  const DatosPersonalesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DatosPersonalesCubit(context.read<DatosPersonalesRepositorio>())
            ..cargar(),
      child: const _Vista(),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BlocConsumer<DatosPersonalesCubit, DatosPersonalesEstado>(
      listenWhen: (a, b) => a.resultado != b.resultado && b.resultado != null,
      listener: (context, estado) {
        final mensaje = switch (estado.resultado!) {
          ResultadoDatosPersonales.guardado => t.datosPersonalesGuardado,
          ResultadoDatosPersonales.edicionAgotada =>
            t.datosPersonalesEdicionAgotada,
          ResultadoDatosPersonales.falloGuardar =>
            estado.sinConexion
                ? t.datosPersonalesErrorSinConexion
                : t.datosPersonalesErrorGuardar,
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensaje)));
      },
      builder: (context, estado) {
        final datos = estado.datos;
        return Scaffold(
          appBar: AppBar(title: Text(t.datosPersonalesTitulo)),
          body: switch (estado.fase) {
            FaseDatosPersonales.cargando => const Padding(
              padding: EdgeInsets.all(EspaciadoCampo.l),
              child: EsqueletoCampo(alto: 220),
            ),
            FaseDatosPersonales.error => EstadoErrorMarketplace(
              titulo: t.datosPersonalesErrorTitulo,
              detalle: t.datosPersonalesErrorDetalle,
              sinConexion: estado.sinConexion,
              onReintentar: context.read<DatosPersonalesCubit>().cargar,
            ),
            _ when datos == null => const SizedBox.shrink(),
            _ when datos.puedeEditar => _Formulario(
              key: const Key('datos-formulario'),
              datos: datos.datos,
              guardando: estado.fase == FaseDatosPersonales.guardando,
            ),
            _ => _SoloLectura(estado: datos),
          },
        );
      },
    );
  }
}

/// Formulario de la única edición: aviso arriba, un campo por fila y el botón
/// ámbar al pie, siempre a la vista.
class _Formulario extends StatefulWidget {
  const _Formulario({required this.datos, required this.guardando, super.key});

  final DatosPersonales datos;
  final bool guardando;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _clave = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.datos.nombre);
  late final _correo = TextEditingController(text: widget.datos.correo);
  late final _telefono = TextEditingController(text: widget.datos.telefono);
  late final _empresa = TextEditingController(text: widget.datos.empresa);
  late final _documento = TextEditingController(text: widget.datos.documento);

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _empresa.dispose();
    _documento.dispose();
    super.dispose();
  }

  static final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  Future<void> _guardar() async {
    if (!(_clave.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context);
    final cubit = context.read<DatosPersonalesCubit>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.datosPersonalesConfirmarTitulo),
        content: Text(t.datosPersonalesConfirmarAviso),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.datosPersonalesRevisar),
          ),
          TextButton(
            key: const Key('datos-confirmar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.datosPersonalesConfirmarSi),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await cubit.guardar(
      DatosPersonales(
        nombre: _nombre.text.trim(),
        correo: _correo.text.trim(),
        telefono: _telefono.text.trim(),
        empresa: widget.datos.empresa == null ? null : _empresa.text.trim(),
        documento: widget.datos.documento == null
            ? null
            : _documento.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const separacion = SizedBox(height: EspaciadoCampo.l);
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _clave,
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.all(EspaciadoCampo.l),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: EntradaCampo.escalonar([
                  AvisoMarketplace(
                    key: const Key('datos-aviso-una-vez'),
                    mensaje: t.datosPersonalesAvisoUnaVez,
                  ),
                  separacion,
                  CampoFormularioMarketplace(
                    etiqueta: t.datosPersonalesNombre,
                    controller: _nombre,
                    enabled: !widget.guardando,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? t.datosPersonalesNombreObligatorio
                        : null,
                  ),
                  separacion,
                  CampoFormularioMarketplace(
                    etiqueta: t.datosPersonalesCorreo,
                    controller: _correo,
                    enabled: !widget.guardando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => _formatoCorreo.hasMatch((v ?? '').trim())
                        ? null
                        : t.datosPersonalesCorreoInvalido,
                  ),
                  separacion,
                  CampoFormularioMarketplace(
                    etiqueta: t.datosPersonalesTelefono,
                    controller: _telefono,
                    enabled: !widget.guardando,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (v) =>
                        (v ?? '').replaceAll(RegExp(r'\D'), '').length >= 8
                        ? null
                        : t.datosPersonalesTelefonoInvalido,
                  ),
                  if (widget.datos.empresa != null) ...[
                    separacion,
                    CampoFormularioMarketplace(
                      etiqueta: t.datosPersonalesEmpresa,
                      controller: _empresa,
                      enabled: !widget.guardando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.organizationName],
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? t.datosPersonalesEmpresaObligatoria
                          : null,
                    ),
                  ],
                  if (widget.datos.documento != null) ...[
                    separacion,
                    CampoFormularioMarketplace(
                      etiqueta: t.datosPersonalesDocumento,
                      controller: _documento,
                      enabled: !widget.guardando,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
        _BarraAccion(
          child: BotonPrimarioCampo(
            key: const Key('datos-guardar'),
            texto: t.datosPersonalesGuardar,
            cargando: widget.guardando,
            onPressed: _guardar,
          ),
        ),
      ],
    );
  }
}

/// Después de la única edición: los datos de solo lectura y la salida clara
/// (pedir el cambio a atención al cliente).
class _SoloLectura extends StatelessWidget {
  const _SoloLectura({required this.estado});

  final EstadoDatosPersonales estado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = estado.datos;
    final abierta = estado.solicitudAbierta;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            children: EntradaCampo.escalonar([
              AvisoMarketplace(
                key: const Key('datos-aviso-ya-editado'),
                mensaje: abierta
                    ? t.datosPersonalesSolicitudEnRevision
                    : t.datosPersonalesYaEditado,
                icono: abierta ? Icons.hourglass_top_rounded : null,
              ),
              const SizedBox(height: EspaciadoCampo.l),
              SuperficieMarketplace(
                child: Column(
                  children: [
                    _FilaDato(t.datosPersonalesNombre, d.nombre),
                    _FilaDato(t.datosPersonalesCorreo, d.correo),
                    _FilaDato(t.datosPersonalesTelefono, d.telefono),
                    if (d.empresa != null)
                      _FilaDato(t.datosPersonalesEmpresa, d.empresa!),
                    if (d.documento != null)
                      _FilaDato(t.datosPersonalesDocumento, d.documento!),
                  ],
                ),
              ),
            ]),
          ),
        ),
        _BarraAccion(
          child: BotonPrimarioCampo(
            key: const Key('datos-solicitar-cambio'),
            texto: t.datosPersonalesSolicitar,
            onPressed: abierta
                ? null
                : () async {
                    final cubit = context.read<DatosPersonalesCubit>();
                    final enviada = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => SolicitarCambioPantalla(
                          repositorio: context
                              .read<DatosPersonalesRepositorio>(),
                        ),
                      ),
                    );
                    if (enviada ?? false) await cubit.recargar();
                  },
          ),
        ),
      ],
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                etiqueta,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              flex: 3,
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: texto.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie con el botón principal en la zona del pulgar, sobre el área segura.
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
