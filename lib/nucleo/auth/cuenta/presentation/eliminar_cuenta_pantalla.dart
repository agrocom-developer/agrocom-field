import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/ui/aviso_marketplace.dart';
import '../../../marketplace/ui/boton_principal_marketplace.dart';
import '../../../marketplace/ui/campo_formulario_marketplace.dart';
import '../../../marketplace/ui/estado_error_marketplace.dart';
import '../../../marketplace/ui/formato_marketplace.dart';
import '../../../marketplace/ui/superficie_marketplace.dart';
import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/componentes/hoja_inferior_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../domain/cuenta_seguridad.dart';
import 'eliminar_cuenta_cubit.dart';
import 'flujo_codigo_cubit.dart';
import 'flujo_codigo_vista.dart';
import 'textos_cuenta_seguridad.dart';

/// «Eliminar mi cuenta» (ADR 0047). Primero explica qué se borra, qué se
/// conserva y qué lo impide; la confirmación va en una hoja inferior, con la
/// contraseña o con un código para quien la olvidó.
///
/// [alCerrarSesion] limpia la sesión local: el servidor ya revocó todos los
/// tokens al aceptar la solicitud.
class EliminarCuentaPantalla extends StatelessWidget {
  const EliminarCuentaPantalla({required this.alCerrarSesion, super.key});

  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EliminarCuentaCubit(
        context.read<CuentaSeguridadRepositorio>(),
        pendientes: _pendientesDe(context),
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).cuentaEliminarMiCuenta),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _Cuerpo(alCerrarSesion: alCerrarSesion),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solo el piloto provee lo pendiente de subir; en el cliente es `null`.
PendientesDeSincronizacion? _pendientesDe(BuildContext context) {
  try {
    return context.read<PendientesDeSincronizacion>();
  } on ProviderNotFoundException {
    return null;
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.alCerrarSesion});

  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EliminarCuentaCubit, EliminarCuentaEstado>(
      builder: (context, estado) {
        final cubit = context.read<EliminarCuentaCubit>();
        final l10n = AppLocalizations.of(context);
        switch (estado.etapa) {
          case EtapaEliminar.cargando:
            return const Padding(
              padding: EdgeInsets.all(EspaciadoCampo.l),
              child: EsqueletoCampo(alto: 220),
            );
          case EtapaEliminar.error:
            final sinRed = estado.falla is CuentaSinConexion;
            return EstadoErrorMarketplace(
              titulo: l10n.cuentaEnEliminacionErrorTitulo,
              detalle: TextosCuentaSeguridad.falla(
                l10n,
                estado.falla ?? const CuentaErrorDesconocido(),
              ),
              sinConexion: sinRed,
              onReintentar: cubit.cargar,
            );
          case EtapaEliminar.solicitada:
            return _Solicitada(
              eliminacion: estado.eliminacion,
              alEntendido: alCerrarSesion,
            );
          case EtapaEliminar.conservada:
            return VistaCuentaConservada(
              alListo: () => Navigator.of(context).pop(true),
            );
          case EtapaEliminar.listo:
          case EtapaEliminar.enviando:
            final consulta = estado.consulta;
            if (consulta != null && consulta.bloqueada) {
              return _Bloqueada(consulta.impedimentos);
            }
            return _Explicacion(estado: estado);
        }
      },
    );
  }
}

class _Bloqueada extends StatelessWidget {
  const _Bloqueada(this.impedimentos);

  final List<ImpedimentoEliminacion> impedimentos;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.cuentaEliminarBloqueadaTitulo,
            style: texto.headlineSmall,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.s),
        Text(
          l10n.cuentaEliminarBloqueadaDetalle,
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        for (final i in impedimentos)
          Padding(
            padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
            child: SuperficieMarketplace(
              key: Key('impedimento-${i.codigo}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.block_rounded, color: paleta.alerta),
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TextosCuentaSeguridad.impedimento(l10n, i).titulo,
                          style: texto.titleMedium,
                        ),
                        const SizedBox(height: EspaciadoCampo.xs),
                        Text(
                          TextosCuentaSeguridad.impedimento(l10n, i).salida,
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Explicacion extends StatelessWidget {
  const _Explicacion({required this.estado});

  final EliminarCuentaEstado estado;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final cubit = context.read<EliminarCuentaCubit>();
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.cuentaEliminarAntesTitulo,
            style: texto.headlineSmall,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        _Lista(
          titulo: l10n.cuentaEliminarQueSeBorra,
          icono: Icons.delete_outline_rounded,
          lineas: TextosCuentaSeguridad.seBorra(l10n),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        _Lista(
          titulo: l10n.cuentaEliminarQueSeConserva,
          icono: Icons.inventory_2_outlined,
          lineas: TextosCuentaSeguridad.seConserva(l10n),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        AvisoMarketplace(
          mensaje: TextosCuentaSeguridad.efectosInmediatos(l10n),
          tono: TonoAviso.alerta,
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Text(
          TextosCuentaSeguridad.graciaDias(l10n),
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
        // Las fallas de la confirmación las muestra la propia hoja.
        const SizedBox(height: EspaciadoCampo.xl),
        if (estado.pendientesPorSubir > 0) ...[
          // Un registro que llegara después de la eliminación se rechazaría y
          // se perdería: primero se sube lo del lote.
          AvisoMarketplace(
            key: const Key('eliminar-pendientes'),
            mensaje: l10n.cuentaEliminarPendientes(estado.pendientesPorSubir),
            tono: TonoAviso.alerta,
          ),
          const SizedBox(height: EspaciadoCampo.m),
          BotonPrincipalMarketplace(
            key: const Key('eliminar-sincronizar'),
            texto: l10n.cuentaEliminarSincronizarAhora,
            icono: Icons.sync_rounded,
            alto: ObjetivoTactilCampo.guantes,
            cargando: estado.sincronizando,
            onPressed: cubit.sincronizar,
          ),
        ] else
          BotonDestructivoCuenta(
            key: const Key('eliminar-continuar'),
            texto: l10n.cuentaContinuar,
            cargando: estado.etapa == EtapaEliminar.enviando,
            onPressed: () => _confirmar(context, cubit),
          ),
      ],
    );
  }

  Future<void> _confirmar(BuildContext context, EliminarCuentaCubit cubit) {
    final repositorio = context.read<CuentaSeguridadRepositorio>();
    return mostrarHojaInferiorCampo<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: HojaConfirmarEliminacion(repositorio: repositorio),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.titulo,
    required this.icono,
    required this.lineas,
  });

  final String titulo;
  final IconData icono;
  final List<String> lineas;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(icono, color: paleta.acentoTexto)),
              const SizedBox(width: EspaciadoCampo.s),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(titulo, style: texto.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.s),
          for (final l in lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: EspaciadoCampo.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: texto.bodyMedium),
                  Expanded(child: Text(l, style: texto.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón de acción irreversible: tonal de error, nunca el verde de acento.
class BotonDestructivoCuenta extends StatelessWidget {
  const BotonDestructivoCuenta({
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    super.key,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: cargando
          ? AppLocalizations.of(context).cuentaBotonEnCurso(texto)
          : null,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: cargando ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, ObjetivoTactilCampo.guantes),
            backgroundColor: paleta.errorContenedor,
            foregroundColor: paleta.sobreErrorContenedor,
            disabledBackgroundColor: paleta.errorContenedor,
            disabledForegroundColor: paleta.sobreErrorContenedor,
          ),
          child: cargando
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: paleta.sobreErrorContenedor,
                  ),
                )
              : Text(texto),
        ),
      ),
    );
  }
}

enum _Metodo { contrasena, codigo }

/// Hoja de confirmación: contraseña (lo normal) o código por WhatsApp, SMS o
/// correo (para quien la olvidó). Al aceptar el servidor, la hoja se cierra y
/// la pantalla muestra el plazo para arrepentirse.
class HojaConfirmarEliminacion extends StatefulWidget {
  const HojaConfirmarEliminacion({required this.repositorio, super.key});

  final CuentaSeguridadRepositorio repositorio;

  @override
  State<HojaConfirmarEliminacion> createState() =>
      _HojaConfirmarEliminacionState();
}

class _HojaConfirmarEliminacionState extends State<HojaConfirmarEliminacion> {
  final _formulario = GlobalKey<FormState>();
  final _contrasena = TextEditingController();
  _Metodo _metodo = _Metodo.contrasena;
  late final FlujoCodigoCubit _flujo = FlujoCodigoCubit(
    pedir: widget.repositorio.pedirCodigoEliminacion,
    confirmar: (codigo, _) => widget.repositorio.eliminarCuenta(codigo: codigo),
  );

  @override
  void dispose() {
    _contrasena.dispose();
    _flujo.close();
    super.dispose();
  }

  void _enviar(EliminarCuentaCubit cubit) {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    cubit.eliminarConContrasena(_contrasena.text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EliminarCuentaCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<EliminarCuentaCubit, EliminarCuentaEstado>(
          listenWhen: (a, b) => a.etapa != b.etapa || a.falla != b.falla,
          listener: (context, e) {
            // Solicitada: la pantalla de atrás muestra el plazo. Bloqueada:
            // la pantalla de atrás ya explica los motivos nuevos.
            if (e.etapa == EtapaEliminar.solicitada ||
                e.falla is CuentaEliminacionBloqueada) {
              Navigator.of(context).pop();
            }
          },
        ),
        BlocListener<FlujoCodigoCubit, FlujoCodigoEstado>(
          bloc: _flujo,
          listenWhen: (a, b) => a.etapa != b.etapa || a.falla != b.falla,
          listener: (context, e) {
            if (e.etapa == EtapaCodigo.listo &&
                e.resultado is EliminacionCuenta) {
              cubit.registrarSolicitud(e.resultado! as EliminacionCuenta);
            } else if (e.falla is CuentaEliminacionBloqueada) {
              cubit.cargar();
              Navigator.of(context).pop();
            }
          },
        ),
      ],
      child: BlocProvider.value(
        value: _flujo,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: AnimatedSwitcher(
              duration: MovimientoCampo.duracion(
                context,
                MovimientoCampo.media,
              ),
              switchInCurve: MovimientoCampo.entrada,
              switchOutCurve: MovimientoCampo.salida,
              child: KeyedSubtree(
                key: ValueKey(_metodo),
                child: _metodo == _Metodo.contrasena
                    ? _conContrasena(context, cubit)
                    : _conCodigo(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conContrasena(BuildContext context, EliminarCuentaCubit cubit) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<EliminarCuentaCubit, EliminarCuentaEstado>(
      builder: (context, estado) {
        final enviando = estado.etapa == EtapaEliminar.enviando;
        final falla = estado.falla;
        return Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.cuentaEliminarConfirmaContrasenaTitulo,
                  style: texto.titleLarge,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              Text(
                l10n.cuentaEliminarConfirmaContrasenaDetalle,
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              if (falla != null) ...[
                AvisoFallaCuenta(falla: falla),
                const SizedBox(height: EspaciadoCampo.l),
              ],
              CampoFormularioMarketplace(
                key: const Key('eliminar-contrasena'),
                etiqueta: l10n.cuentaContrasenaEtiqueta,
                controller: _contrasena,
                enabled: !enviando,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: ReglasContrasena.validarIngreso,
                onChanged: (_) => cubit.limpiarFalla(),
                onFieldSubmitted: (_) => _enviar(cubit),
              ),
              const SizedBox(height: EspaciadoCampo.xl),
              BotonDestructivoCuenta(
                key: const Key('eliminar-confirmar'),
                texto: l10n.cuentaEliminarMiCuenta,
                cargando: enviando,
                onPressed: () => _enviar(cubit),
              ),
              const SizedBox(height: EspaciadoCampo.s),
              TextButton(
                key: const Key('eliminar-usar-codigo'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    ObjetivoTactilCampo.guantes,
                  ),
                ),
                onPressed: enviando
                    ? null
                    : () => setState(() => _metodo = _Metodo.codigo),
                child: Text(l10n.cuentaEliminarUsarCodigo),
              ),
              TextButton(
                key: const Key('eliminar-cancelar'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    ObjetivoTactilCampo.minimo,
                  ),
                ),
                onPressed: enviando ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cuentaConservarMiCuenta),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _conCodigo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlujoCodigoVista(
          tituloElegir: l10n.cuentaEliminarConfirmaCodigoTitulo,
          detalleElegir: l10n.cuentaEliminarConfirmaCodigoDetalle,
          textoConfirmar: l10n.cuentaEliminarMiCuenta,
        ),
        TextButton(
          key: const Key('eliminar-usar-contrasena'),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.minimo),
          ),
          onPressed: () => setState(() => _metodo = _Metodo.contrasena),
          child: Text(l10n.cuentaEliminarUsarContrasena),
        ),
      ],
    );
  }
}

class _Solicitada extends StatelessWidget {
  const _Solicitada({required this.eliminacion, required this.alEntendido});

  final EliminacionCuenta? eliminacion;
  final VoidCallback alEntendido;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    final hasta = eliminacion?.ejecutarDesde.toLocal();
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.schedule_rounded,
            size: 56,
            color: paleta.acentoTexto,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            l10n.cuentaEliminarSolicitadaTitulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Text(
          hasta == null
              ? l10n.cuentaEliminarSolicitadaSinFecha
              : l10n.cuentaEliminarSolicitadaConFecha(
                  FormatoMarketplace.fechaLarga(hasta),
                ),
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('eliminar-entendido'),
          texto: l10n.cuentaEntendido,
          alto: ObjetivoTactilCampo.guantes,
          onPressed: () {
            // La sesión ya no vale: se cierra y se vuelve al ingreso.
            Navigator.of(context).popUntil((r) => r.isFirst);
            alEntendido();
          },
        ),
      ],
    );
  }
}

/// «Conservamos tu cuenta»: la eliminación en gracia se canceló.
class VistaCuentaConservada extends StatelessWidget {
  const VistaCuentaConservada({required this.alListo, super.key});

  final VoidCallback alListo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: paleta.exito,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            l10n.cuentaConservadaTitulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: EspaciadoCampo.m),
        Text(
          l10n.cuentaConservadaDetalle,
          style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EspaciadoCampo.xl),
        BotonPrincipalMarketplace(
          key: const Key('conservada-listo'),
          texto: l10n.cuentaListo,
          alto: ObjetivoTactilCampo.guantes,
          onPressed: alListo,
        ),
      ],
    );
  }
}
