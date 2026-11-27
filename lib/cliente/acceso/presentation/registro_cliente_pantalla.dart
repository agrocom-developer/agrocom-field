import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import '../../../nucleo/auth/cuenta/presentation/cuenta_ya_registrada_pantalla.dart';
import '../../../nucleo/auth/cuenta/presentation/recuperar_acceso_pantalla.dart';
import '../../../nucleo/auth/cuenta/presentation/verificar_telefono_hoja.dart';
import '../../../nucleo/marketplace/ui/aviso_marketplace.dart';
import '../../../nucleo/marketplace/ui/boton_principal_marketplace.dart';
import '../../../nucleo/marketplace/ui/campo_formulario_marketplace.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/acceso_repositorio.dart';
import '../domain/reglas_acceso.dart';
import 'formulario_acceso_estado.dart';
import 'lienzo_acceso.dart';
import 'registro_cliente_cubit.dart';

/// Registro del cliente en dos bloques: quién eres y cómo entras. Los
/// errores que devuelve el servidor se muestran junto a su campo; sin red,
/// el formulario conserva lo escrito.
class RegistroClientePantalla extends StatelessWidget {
  const RegistroClientePantalla({
    required this.alEntrar,
    required this.alVolver,
    super.key,
  });

  final ValueChanged<SesionCliente> alEntrar;
  final VoidCallback alVolver;

  /// `409 cuenta_ya_registrada`: explica que ya existe una cuenta y ofrece
  /// iniciar sesión (vuelve al ingreso) o recuperar el acceso.
  static void _avisarCuentaExistente(
    BuildContext context,
    String? tipoCuenta,
    VoidCallback irAlIngreso,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (rutaContext) => CuentaYaRegistradaPantalla(
          app: AppCuenta.cliente,
          tipoCuenta: tipoCuenta,
          alIniciarSesion: () {
            Navigator.of(rutaContext).pop();
            irAlIngreso();
          },
          alRecuperarAcceso: () async {
            await abrirRecuperarAcceso(rutaContext, app: AppCuenta.cliente);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RegistroClienteCubit(context.read<AccesoRepositorio>()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<RegistroClienteCubit, FormularioAccesoEstado>(
            listenWhen: (antes, ahora) => ahora.sesion != null,
            listener: (context, estado) async {
              HapticaCampo.confirmacion();
              // La cuenta ya está creada y con sesión: se ofrece verificar el
              // teléfono con un código, sin obligar («Más tarde»).
              await ofrecerVerificarTelefono(context);
              if (context.mounted) alEntrar(estado.sesion!);
            },
          ),
          BlocListener<RegistroClienteCubit, FormularioAccesoEstado>(
            listenWhen: (antes, ahora) =>
                ahora.fallo == MotivoFalloAcceso.cuentaYaRegistrada &&
                antes.fallo != ahora.fallo,
            listener: (context, estado) =>
                _avisarCuentaExistente(context, estado.tipoCuenta, alVolver),
          ),
        ],
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (salio, _) {
            if (!salio) alVolver();
          },
          child: LienzoAcceso(child: _Formulario(alVolver: alVolver)),
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.alVolver});

  final VoidCallback alVolver;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _razonSocial = TextEditingController();
  final _documentoFiscal = TextEditingController();
  final _cargo = TextEditingController();

  /// «Asociar a una empresa»: el registro es siempre de una persona; con el
  /// interruptor, además crea la empresa y deja a quien se registra como su
  /// contacto principal.
  bool _conEmpresa = false;
  bool _intentado = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _usuario.dispose();
    _contrasena.dispose();
    _razonSocial.dispose();
    _documentoFiscal.dispose();
    _cargo.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _intentado = true);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<RegistroClienteCubit>().enviar(
      DatosRegistroCliente(
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        usuario: _usuario.text.trim(),
        contrasena: _contrasena.text,
        tipo: _conEmpresa ? TipoCliente.empresa : TipoCliente.persona,
        razonSocial: _conEmpresa ? _razonSocial.text : null,
        documentoFiscal: _conEmpresa ? _documentoFiscal.text : null,
        cargo: _conEmpresa && _cargo.text.trim().isNotEmpty
            ? _cargo.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final cubit = context.read<RegistroClienteCubit>();
    final t = AppLocalizations.of(context);
    return BlocBuilder<RegistroClienteCubit, FormularioAccesoEstado>(
      builder: (context, estado) {
        final mensaje = estado.mensajeFallo(t);
        Widget bloque(String titulo) => Padding(
          padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
          child: Semantics(
            header: true,
            child: Text(
              titulo.toUpperCase(),
              style: texto.labelSmall?.copyWith(color: paleta.textoSecundario),
            ),
          ),
        );
        return Form(
          key: _formulario,
          autovalidateMode: _intentado
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // El botón sobresale del margen para que la flecha quede
                // alineada con el texto y conserve su objetivo de 48 px.
                Transform.translate(
                  offset: const Offset(-EspaciadoCampo.m, 0),
                  child: IconButton(
                    key: const Key('registro-volver'),
                    tooltip: l10n.accesoVolverIngreso,
                    onPressed: estado.enviando ? null : widget.alVolver,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: paleta.texto,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.s),
                Text(l10n.accesoCreaCuenta, style: texto.headlineMedium),
                const SizedBox(height: EspaciadoCampo.s),
                Text(
                  l10n.accesoTomaMenosMinuto,
                  style: texto.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                AnimatedSwitcher(
                  duration: MovimientoCampo.duracion(
                    context,
                    MovimientoCampo.media,
                  ),
                  switchInCurve: MovimientoCampo.entrada,
                  switchOutCurve: MovimientoCampo.salida,
                  child: mensaje == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          key: ValueKey(mensaje),
                          padding: const EdgeInsets.only(
                            bottom: EspaciadoCampo.l,
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: AvisoMarketplace(
                              mensaje: mensaje,
                              tono: estado.sinConexion
                                  ? TonoAviso.alerta
                                  : TonoAviso.error,
                              icono: estado.sinConexion
                                  ? Icons.wifi_off_rounded
                                  : null,
                            ),
                          ),
                        ),
                ),
                bloque(l10n.accesoTusDatos),
                CampoFormularioMarketplace(
                  key: const Key('registro-nombre'),
                  etiqueta: l10n.accesoNombreCompleto,
                  controller: _nombre,
                  enabled: !estado.enviando,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: ReglasAcceso.nombre,
                  errorServidor: estado.porCampo[CampoAcceso.nombre],
                  onChanged: (_) => cubit.campoEditado(CampoAcceso.nombre),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                CampoFormularioMarketplace(
                  key: const Key('registro-telefono'),
                  etiqueta: l10n.accesoTelefono,
                  controller: _telefono,
                  enabled: !estado.enviando,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  validator: ReglasAcceso.telefono,
                  errorServidor: estado.porCampo[CampoAcceso.telefono],
                  onChanged: (_) => cubit.campoEditado(CampoAcceso.telefono),
                ),
                SwitchListTile(
                  key: const Key('registro-empresa'),
                  contentPadding: EdgeInsets.zero,
                  value: _conEmpresa,
                  onChanged: estado.enviando
                      ? null
                      : (v) => setState(() => _conEmpresa = v),
                  title: Text(t.registroEmpresaInterruptor),
                  subtitle: Text(t.registroEmpresaAyuda),
                ),
                if (_conEmpresa) ...[
                  const SizedBox(height: EspaciadoCampo.m),
                  CampoFormularioMarketplace(
                    key: const Key('registro-razon-social'),
                    etiqueta: t.registroEmpresaRazon,
                    controller: _razonSocial,
                    enabled: !estado.enviando,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: ReglasAcceso.razonSocial,
                    errorServidor: estado.porCampo[CampoAcceso.razonSocial],
                    onChanged: (_) =>
                        cubit.campoEditado(CampoAcceso.razonSocial),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  CampoFormularioMarketplace(
                    key: const Key('registro-documento-fiscal'),
                    etiqueta: t.registroEmpresaDocumento,
                    controller: _documentoFiscal,
                    enabled: !estado.enviando,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: ReglasAcceso.documentoFiscal,
                    errorServidor: estado.porCampo[CampoAcceso.documentoFiscal],
                    onChanged: (_) =>
                        cubit.campoEditado(CampoAcceso.documentoFiscal),
                  ),
                  const SizedBox(height: EspaciadoCampo.l),
                  CampoFormularioMarketplace(
                    key: const Key('registro-cargo'),
                    etiqueta: t.registroEmpresaCargo,
                    controller: _cargo,
                    enabled: !estado.enviando,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                  AvisoMarketplace(mensaje: t.registroEmpresaContactoNota),
                ],
                const SizedBox(height: EspaciadoCampo.xl),
                bloque(l10n.accesoAcceso),
                CampoFormularioMarketplace(
                  key: const Key('registro-usuario'),
                  etiqueta: l10n.accesoUsuario,
                  controller: _usuario,
                  enabled: !estado.enviando,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  ayuda: l10n.accesoConQueVasEntrar,
                  validator: ReglasAcceso.usuario,
                  errorServidor: estado.porCampo[CampoAcceso.usuario],
                  onChanged: (_) => cubit.campoEditado(CampoAcceso.usuario),
                ),
                const SizedBox(height: EspaciadoCampo.l),
                CampoFormularioMarketplace(
                  key: const Key('registro-contrasena'),
                  etiqueta: l10n.accesoContrasena,
                  controller: _contrasena,
                  enabled: !estado.enviando,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  ayuda:
                      'Mínimo ${ReglasAcceso.largoMinimoContrasena} caracteres.',
                  validator: ReglasAcceso.contrasenaNueva,
                  errorServidor: estado.porCampo[CampoAcceso.contrasena],
                  onChanged: (_) => cubit.campoEditado(CampoAcceso.contrasena),
                  onFieldSubmitted: (_) => _enviar(),
                ),
                const SizedBox(height: EspaciadoCampo.xl),
                BotonPrincipalMarketplace(
                  key: const Key('registro-crear'),
                  texto: l10n.accesoCrearCuenta,
                  cargando: estado.enviando,
                  onPressed: _enviar,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
