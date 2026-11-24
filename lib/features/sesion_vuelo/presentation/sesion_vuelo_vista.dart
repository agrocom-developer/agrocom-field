import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../estado_sync/presentation/indicador_sync.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../incidencias/presentation/incidencia_pantalla.dart';
import '../domain/auxiliar.dart';
import '../domain/reglas_apertura.dart';
import '../domain/reglas_condiciones.dart';
import '../domain/sesion.dart';
import 'sesion_bloc.dart';
import 'sesion_estado.dart';
import 'sesion_evento.dart';
import 'trabajo_cubit.dart';
import 'trabajo_estado.dart';

/// UI pura de la sesión de vuelo — muestra el ciclo de vida de una sesión de
/// vuelo (inicial, abriendo, activa, cerrando, cerrada, error). Asume que un
/// `SesionBloc` ya está provisto en el árbol (`SesionVueloPantalla`, o
/// `BlocProvider.value` en tests).
///
/// [crearIncidenciaCubit] arma el `IncidenciaCubit` de HU-08 — se invoca
/// recién al presionar "Reportar incidencia" con `sesion.uuidCliente` de la
/// sesión activa, nunca antes (mismo motivo que en `OrdenDetallePantalla`
/// con `crearTrabajoCubit`: construirlo eager en un flavor que no lo
/// soporta rompería ese flavor incluso con el botón oculto).
///
/// En modo campo (ADR 0008 y ADR 0011): `EncabezadoCampo` con el estado de
/// sincronización debajo, el contenido de cada estado en una tarjeta y las
/// acciones ancladas abajo en una `BarraAccionesCampo` — la principal
/// siempre al alcance del pulgar, sin scroll. Los formularios de apertura y
/// cierre son hojas a casi todo el ancho con `CampoTextoCampo` y
/// `SelectorDesplegableCampo`. Las condiciones fuera de rango se avisan con
/// un `BannerAlertaCampo` (ámbar) y la foto obligatoria del cierre de
/// trabajo, con el hueco en ámbar mientras falte. Cada confirmación lleva
/// háptica además del cambio visible. Eventos, estados y reglas
/// (`reglas_condiciones.dart`) son los del bloc.
///
/// Una pausa de vuelo es el cierre de la sesión con su motivo (clima, fin
/// de jornada, relevo, cambio de dron): la pantalla de sesión cerrada
/// ofrece abrir la siguiente sobre el mismo trabajo.
class SesionVueloVista extends StatefulWidget {
  const SesionVueloVista({required this.crearIncidenciaCubit, super.key});

  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  State<SesionVueloVista> createState() => _SesionVueloVistaState();
}

class _SesionVueloVistaState extends State<SesionVueloVista> {
  late GlobalKey<FormState> _formKey;
  late GlobalKey<FormState> _formAperturaKey;
  late GlobalKey<FormState> _formCierreTrabajoKey;
  late TextEditingController _hectareasController;
  late TextEditingController _litrosController;
  late TextEditingController _vientoController;
  late TextEditingController _temperaturaController;
  late TextEditingController _humedadController;
  late TextEditingController _observacionController;
  late TextEditingController _firmaController;
  late TextEditingController _dronIdController;
  late TextEditingController _hectareaInicialController;
  late TextEditingController _acumuladoFinalController;
  late TextEditingController _litrosSobranteController;
  String? _motivoSeleccionado;
  bool _condicionesFueraDeRango = false;
  int? _auxiliarSeleccionadoId;

  /// Límites efectivos del trabajo (tarea 24), cargados una vez al abrir el
  /// formulario: los mismos con los que el servidor va a validar el
  /// registro `condiciones`.
  LimitesCondiciones _limites = LimitesCondiciones.porDefecto();

  /// Si se puede abrir una sesión nueva (tarea 27), cargada junto con
  /// [_limites] al abrir el formulario: con un bloqueo, el formulario
  /// muestra el motivo y no deja confirmar.
  RestriccionApertura _restriccion = RestriccionApertura.ninguna;

  /// La misma restricción, leída al entrar a la pantalla (tarea 27) para
  /// mostrar arriba el motivo de retiro del trabajo como aviso; se
  /// actualiza cada vez que se abre el formulario. `null` mientras carga.
  RestriccionApertura? _restriccionPantalla;

  /// HU-07: se dispara una sola vez por apertura de diálogo, no en cada
  /// `build` del `StatefulBuilder` — evita repetir la consulta a `drift` en
  /// cada rebuild mientras el piloto completa el resto del formulario.
  Future<List<Auxiliar>>? _auxiliaresFuture;

  static const _motivosCierre = [
    ('completado', 'Completado'),
    ('relevo_piloto', 'Relevo de piloto'),
    ('cambio_dron', 'Cambio de dron'),
    ('falla_equipo', 'Falla de equipo'),
    ('clima', 'Clima'),
    ('fin_jornada', 'Fin de jornada'),
    ('otro', 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _formAperturaKey = GlobalKey<FormState>();
    _formCierreTrabajoKey = GlobalKey<FormState>();
    _hectareasController = TextEditingController();
    _litrosController = TextEditingController();
    _vientoController = TextEditingController();
    _temperaturaController = TextEditingController();
    _humedadController = TextEditingController();
    _observacionController = TextEditingController();
    _firmaController = TextEditingController();
    _dronIdController = TextEditingController();
    _hectareaInicialController = TextEditingController();
    _acumuladoFinalController = TextEditingController();
    _litrosSobranteController = TextEditingController();
    _cargarRestriccionPantalla();
  }

  /// Solo informa: si la lectura falla, la pantalla sigue sin el aviso. Lo
  /// que bloquea no depende de esto — el formulario vuelve a leer la
  /// restricción antes de dejar confirmar.
  Future<void> _cargarRestriccionPantalla() async {
    final RestriccionApertura restriccion;
    try {
      restriccion = await context.read<SesionBloc>().restriccionApertura();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _restriccionPantalla = restriccion);
  }

  @override
  void dispose() {
    _hectareasController.dispose();
    _litrosController.dispose();
    _vientoController.dispose();
    _temperaturaController.dispose();
    _humedadController.dispose();
    _observacionController.dispose();
    _firmaController.dispose();
    _dronIdController.dispose();
    _hectareaInicialController.dispose();
    _acumuladoFinalController.dispose();
    _litrosSobranteController.dispose();
    super.dispose();
  }

  /// Recalcula si los valores ingresados están fuera de rango — mientras
  /// alguno de los tres campos no tenga un decimal válido todavía, no se
  /// muestra observación/firma (evita mostrarlas de entrada, con el campo
  /// vacío).
  bool _calcularFueraDeRango() {
    final viento = Decimal.tryParse(_vientoController.text);
    final temperatura = Decimal.tryParse(_temperaturaController.text);
    final humedad = Decimal.tryParse(_humedadController.text);
    if (viento == null || temperatura == null || humedad == null) {
      return false;
    }
    return condicionesFueraDeRango(
      vientoKmh: viento,
      temperaturaC: temperatura,
      humedadPct: humedad,
      limites: _limites,
    );
  }

  /// Texto de los límites que aplican, para que el piloto sepa antes de
  /// medir cuándo va a necesitar la firma del agrónomo. `Decimal.toString()`
  /// tal cual, nunca `double` (invariante 9 de CLAUDE.md).
  static String _textoLimites(LimitesCondiciones limites) {
    final minimo = limites.humedadMinPct;
    final humedad = minimo == null
        ? 'humedad ≤ ${limites.humedadMaxPct} %'
        : 'humedad entre $minimo y ${limites.humedadMaxPct} %';
    return 'Límites del trabajo: viento ≤ ${limites.vientoMaxKmh} km/h · '
        'temperatura ≤ ${limites.temperaturaMaxC} °C · $humedad';
  }

  /// Carga los límites del trabajo ANTES de mostrar el diálogo: decidir
  /// fuera de rango con un default mientras llegan podría dejar pasar una
  /// apertura que el servidor rechaza.
  Future<void> _mostrarFormularioApertura(BuildContext context) async {
    final bloc = context.read<SesionBloc>();
    final limites = await bloc.limitesCondiciones();
    final restriccion = await bloc.restriccionApertura();
    if (!context.mounted) return;
    _limites = limites;
    _restriccion = restriccion;
    setState(() => _restriccionPantalla = restriccion);

    _vientoController.clear();
    _temperaturaController.clear();
    _humedadController.clear();
    _observacionController.clear();
    _firmaController.clear();
    _dronIdController.clear();
    _hectareaInicialController.clear();
    _condicionesFueraDeRango = false;
    _auxiliarSeleccionadoId = null;
    _auxiliaresFuture = context.read<SesionBloc>().auxiliaresDisponibles();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        // El `context` de este builder es descendiente del propio diálogo
        // (otra rama del Overlay, no del árbol de `SesionVueloVista`) — se
        // ignora a propósito y se usa el `context` del método de arriba
        // (capturado por closure) para `context.read<SesionBloc>`, que sí es
        // descendiente del `BlocProvider<SesionBloc>`. El tema campo llega
        // igual: `showDialog` captura los temas del `context` que lo abre.
        builder: (_, setStateDialog) {
          void alCambiarMedicion(String _) {
            final fueraDeRango = _calcularFueraDeRango();
            if (fueraDeRango != _condicionesFueraDeRango) {
              setStateDialog(() => _condicionesFueraDeRango = fueraDeRango);
            }
          }

          return _DialogoCampo(
            titulo: 'Condiciones al abrir sesión',
            formKey: _formAperturaKey,
            onCancelar: () => Navigator.pop(dialogContext),
            botonConfirmar: BotonPrimarioCampo(
              key: const Key('boton_confirmar_apertura'),
              texto: 'Abrir sesión',
              onPressed: _restriccion.bloqueada
                  ? null
                  : () {
                      if (!_formAperturaKey.currentState!.validate()) return;

                      HapticaCampo.confirmacion();
                      context.read<SesionBloc>().add(
                        SesionAbrirSolicitada(
                          vientoKmh: Decimal.parse(_vientoController.text),
                          temperaturaC: Decimal.parse(
                            _temperaturaController.text,
                          ),
                          humedadPct: Decimal.parse(_humedadController.text),
                          observacionAgronomo: _condicionesFueraDeRango
                              ? _observacionController.text.trim()
                              : null,
                          firmaObservacion: _condicionesFueraDeRango
                              ? _firmaController.text.trim()
                              : null,
                          auxiliarId: _auxiliarSeleccionadoId,
                          dronId: _dronIdController.text.isEmpty
                              ? null
                              : int.parse(_dronIdController.text),
                          hectareaInicialAcumulada:
                              _hectareaInicialController.text.isEmpty
                              ? null
                              : Decimal.parse(_hectareaInicialController.text),
                        ),
                      );

                      Navigator.pop(dialogContext);
                    },
            ),
            children: [
              if (_restriccion.bloqueo case final bloqueo?) ...[
                BannerAlertaCampo(
                  key: const Key('apertura_bloqueada'),
                  texto: bloqueo,
                ),
                const SizedBox(height: 12),
              ],
              NotaInlineCampo(
                key: const Key('apertura_limites'),
                texto: _textoLimites(_limites),
              ),
              const SizedBox(height: 12),
              CampoTextoCampo(
                key: const Key('apertura_viento'),
                etiqueta: 'Viento (km/h) *',
                controller: _vientoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: alCambiarMedicion,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'El viento es obligatorio';
                  }
                  final decimal = Decimal.tryParse(valor);
                  if (decimal == null) return 'Ingresá un número válido';
                  if (decimal < Decimal.zero) {
                    return 'El viento no puede ser negativo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CampoTextoCampo(
                key: const Key('apertura_temperatura'),
                etiqueta: 'Temperatura (°C) *',
                controller: _temperaturaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                onChanged: alCambiarMedicion,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'La temperatura es obligatoria';
                  }
                  if (Decimal.tryParse(valor) == null) {
                    return 'Ingresá un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CampoTextoCampo(
                key: const Key('apertura_humedad'),
                etiqueta: 'Humedad (%) *',
                controller: _humedadController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: alCambiarMedicion,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'La humedad es obligatoria';
                  }
                  final decimal = Decimal.tryParse(valor);
                  if (decimal == null) return 'Ingresá un número válido';
                  if (decimal < Decimal.zero) {
                    return 'La humedad no puede ser negativa';
                  }
                  return null;
                },
              ),
              if (_condicionesFueraDeRango) ...[
                const SizedBox(height: 12),
                const BannerAlertaCampo(
                  key: Key('apertura_fuera_de_rango'),
                  texto:
                      'Condiciones fuera de rango: se necesita la '
                      'observación y firma del agrónomo.',
                ),
                const SizedBox(height: 12),
                CampoTextoCampo(
                  key: const Key('apertura_observacion'),
                  etiqueta: 'Observación del agrónomo *',
                  controller: _observacionController,
                  maxLines: 3,
                  validator: (valor) {
                    if (!_condicionesFueraDeRango) return null;
                    if (valor == null || valor.trim().isEmpty) {
                      return 'La observación es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CampoTextoCampo(
                  key: const Key('apertura_firma'),
                  etiqueta: 'Firma del agrónomo *',
                  controller: _firmaController,
                  validator: (valor) {
                    if (!_condicionesFueraDeRango) return null;
                    if (valor == null || valor.trim().isEmpty) {
                      return 'La firma es obligatoria';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              // Sin "(opcional)" acá: cada campo del grupo ya lo dice en su
              // propia etiqueta — repetirlo arriba solo apilaba el mismo
              // texto dos veces, pegado.
              const Text(
                'Relevo de piloto',
                style: TipografiaCampo.tituloTarjeta,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Auxiliar>>(
                future: _auxiliaresFuture,
                builder: (context, snapshot) {
                  final auxiliares = snapshot.data ?? const <Auxiliar>[];
                  return SelectorDesplegableCampo<int?>(
                    key: const Key('apertura_auxiliar'),
                    etiqueta: 'Auxiliar (opcional)',
                    valor: _auxiliarSeleccionadoId,
                    opciones: [
                      (null, 'Sin auxiliar'),
                      for (final auxiliar in auxiliares)
                        (auxiliar.id, auxiliar.nombre),
                    ],
                    onChanged: (valor) =>
                        setStateDialog(() => _auxiliarSeleccionadoId = valor),
                  );
                },
              ),
              const SizedBox(height: 12),
              CampoTextoCampo(
                key: const Key('apertura_dron_id'),
                etiqueta: 'Id de dron (opcional)',
                controller: _dronIdController,
                keyboardType: TextInputType.number,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) return null;
                  if (int.tryParse(valor) == null) {
                    return 'Ingresá un número entero válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CampoTextoCampo(
                key: const Key('apertura_hectarea_inicial_acumulada'),
                etiqueta: 'Hectárea inicial acumulada (opcional, si es relevo)',
                controller: _hectareaInicialController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) return null;
                  final decimal = Decimal.tryParse(valor);
                  if (decimal == null) return 'Ingresá un número válido';
                  if (decimal < Decimal.zero) {
                    return 'No puede ser negativa';
                  }
                  return null;
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarFormularioCierre(BuildContext context, Sesion sesion) {
    final hectareaInicialAcumulada = sesion.hectareaInicialAcumulada;
    _motivoSeleccionado = null;
    _hectareasController.clear();
    _litrosController.clear();
    _acumuladoFinalController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => _DialogoCampo(
        titulo: 'Cerrar sesión',
        apoyo:
            'Si es una pausa, elegí el motivo: al retomar se abre la '
            'sesión siguiente sobre el mismo trabajo.',
        formKey: _formKey,
        onCancelar: () => Navigator.pop(dialogContext),
        botonConfirmar: BotonPrimarioCampo(
          key: const Key('boton_confirmar_cierre'),
          texto: 'Cerrar sesión',
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            HapticaCampo.confirmacion();
            final litros = _litrosController.text.isEmpty
                ? null
                : Decimal.parse(_litrosController.text);

            context.read<SesionBloc>().add(
              SesionCerrarSolicitada(
                motivoCierre: _motivoSeleccionado!,
                hectareasDeclaradas: hectareaInicialAcumulada == null
                    ? Decimal.parse(_hectareasController.text)
                    : null,
                hectareaFinalAcumulada: hectareaInicialAcumulada == null
                    ? null
                    : Decimal.parse(_acumuladoFinalController.text),
                litrosConsumidos: litros,
              ),
            );

            Navigator.pop(dialogContext);
          },
        ),
        children: [
          if (hectareaInicialAcumulada == null)
            CampoTextoCampo(
              key: const Key('cierre_hectareas'),
              etiqueta: 'Hectáreas declaradas *',
              controller: _hectareasController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Las hectáreas son obligatorias';
                }
                try {
                  final decimal = Decimal.parse(valor);
                  if (decimal < Decimal.zero) {
                    return 'Las hectáreas no pueden ser negativas';
                  }
                } catch (e) {
                  return 'Ingresá un número válido';
                }
                return null;
              },
            )
          else ...[
            FilaDatoCampo(
              key: const Key('cierre_acumulado_inicial'),
              etiqueta: 'Acumulado inicial registrado',
              valor: '$hectareaInicialAcumulada',
            ),
            const SizedBox(height: 8),
            CampoTextoCampo(
              key: const Key('cierre_acumulado_final'),
              etiqueta: 'Acumulado final del RC *',
              controller: _acumuladoFinalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'El acumulado final es obligatorio';
                }
                final decimal = Decimal.tryParse(valor);
                if (decimal == null) return 'Ingresá un número válido';
                if (decimal < hectareaInicialAcumulada) {
                  return 'No puede ser menor al acumulado inicial '
                      '($hectareaInicialAcumulada)';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          SelectorDesplegableCampo<String>(
            key: const Key('cierre_motivo'),
            etiqueta: 'Motivo de cierre *',
            valor: _motivoSeleccionado,
            opciones: _motivosCierre,
            onChanged: (valor) {
              setState(() => _motivoSeleccionado = valor);
            },
            validator: (valor) => (valor == null || valor.isEmpty)
                ? 'Seleccioná un motivo de cierre'
                : null,
          ),
          const SizedBox(height: 12),
          CampoTextoCampo(
            key: const Key('cierre_litros'),
            etiqueta: 'Litros consumidos (opcional)',
            controller: _litrosController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (valor) {
              if (valor == null || valor.isEmpty) return null;
              try {
                final decimal = Decimal.parse(valor);
                if (decimal < Decimal.zero) {
                  return 'Los litros no pueden ser negativos';
                }
              } catch (e) {
                return 'Ingresá un número válido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Cierra el TRABAJO (HU-09), no la sesión — distinto de
  /// `_mostrarFormularioCierre`. Mismo motivo que en los diálogos de arriba
  /// para usar el `context` de este método (capturado por closure) en vez
  /// del `context` del `StatefulBuilder`: un diálogo es otra rama del
  /// `Overlay`, no descendiente de `SesionVueloVista` — `context.read` ahí
  /// no encontraría el `BlocProvider<TrabajoCubit>` real.
  ///
  /// La foto de campo es SIEMPRE obligatoria ("sin captura no cierra") — el
  /// botón de confirmar queda deshabilitado hasta que haya una, y mientras
  /// falte el hueco de la foto se ve en ámbar.
  void _mostrarFormularioCierreTrabajo(
    BuildContext context,
    String trabajoUuidCliente,
  ) {
    _litrosSobranteController.clear();
    Uint8List? bytesFoto;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setStateDialog) {
          Future<void> tomarFoto() async {
            final bytes = await context.read<TrabajoCubit>().tomarFotoCampo();
            if (bytes == null) return;
            HapticaCampo.seleccion();
            setStateDialog(() => bytesFoto = bytes);
          }

          final radio =
              Theme.of(
                dialogBuilderContext,
              ).extension<TemaCampo>()?.radioTarjetaChica ??
              18;

          return _DialogoCampo(
            titulo: 'Cerrar trabajo',
            apoyo: 'Cierra el trabajo completo, no solo esta sesión.',
            formKey: _formCierreTrabajoKey,
            onCancelar: () => Navigator.pop(dialogContext),
            botonConfirmar: BotonPrimarioCampo(
              key: const Key('boton_confirmar_cierre_trabajo'),
              texto: 'Cerrar trabajo',
              onPressed: bytesFoto == null
                  ? null
                  : () {
                      if (!_formCierreTrabajoKey.currentState!.validate()) {
                        return;
                      }

                      HapticaCampo.confirmacion();
                      final litrosTexto = _litrosSobranteController.text.trim();
                      context.read<TrabajoCubit>().cerrar(
                        trabajoUuidCliente: trabajoUuidCliente,
                        litrosSobrante: litrosTexto.isEmpty
                            ? null
                            : Decimal.parse(litrosTexto),
                        bytesFoto: bytesFoto!,
                      );
                      Navigator.pop(dialogContext);
                    },
            ),
            children: [
              CampoTextoCampo(
                key: const Key('cierre_trabajo_litros_sobrante'),
                etiqueta: 'Litros sobrantes (opcional)',
                controller: _litrosSobranteController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) return null;
                  try {
                    final decimal = Decimal.parse(valor);
                    if (decimal < Decimal.zero) {
                      return 'Los litros no pueden ser negativos';
                    }
                  } catch (e) {
                    return 'Ingresá un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (bytesFoto != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(radio),
                  child: Image.memory(
                    bytesFoto!,
                    key: const Key('preview_foto_campo'),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              BotonAgregarPunteadoCampo(
                key: const Key('boton_tomar_foto_campo'),
                texto: bytesFoto == null
                    ? 'Tomar foto del campo'
                    : 'Volver a tomar foto',
                alerta: bytesFoto == null,
                onPressed: tomarFoto,
              ),
              if (bytesFoto == null) ...[
                const SizedBox(height: 10),
                const NotaInlineCampo(
                  texto:
                      'La foto del campo es obligatoria — sin captura no '
                      'se puede cerrar el trabajo.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: BlocListener<TrabajoCubit, TrabajoEstado>(
        listener: (context, estado) {
          if (estado is TrabajoCerrado) {
            HapticaCampo.confirmacion();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Trabajo cerrado')));
          }
          if (estado is TrabajoError) {
            HapticaCampo.alerta();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        // El `Builder` deja leer la paleta del tema campo de arriba: el
        // `context` de `build` todavía es el del tema que envuelve a la
        // pantalla.
        child: Builder(
          builder: (context) {
            final margen = _margen(context);
            return Scaffold(
              backgroundColor: context.paleta.fondo,
              body: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        margen,
                        EspaciadoCampo.s,
                        margen,
                        0,
                      ),
                      child: const EncabezadoCampo(titulo: 'Sesión de vuelo'),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        margen,
                        EspaciadoCampo.s,
                        margen,
                        0,
                      ),
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IndicadorSync(),
                      ),
                    ),
                    // Trabajo retirado del catálogo (tarea 27): se avisa en
                    // toda la pantalla; lo abierto se sigue y se cierra
                    // igual.
                    if (_restriccionPantalla?.aviso case final aviso?)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          margen,
                          EspaciadoCampo.m,
                          margen,
                          0,
                        ),
                        child: NotaInlineCampo(
                          key: const Key('sesion_aviso_retiro'),
                          texto: aviso,
                        ),
                      ),
                    Expanded(
                      child: BlocConsumer<SesionBloc, SesionEstado>(
                        listener: (context, estado) {
                          if (estado is SesionActiva ||
                              estado is SesionCerrada) {
                            HapticaCampo.seleccion();
                          }
                          if (estado is SesionError) {
                            HapticaCampo.alerta();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(estado.mensaje),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        },
                        builder: (context, estado) => switch (estado) {
                          SesionInicial() => _sesionInicial(context),
                          SesionAbriendo() => const _Guardando(
                            texto: 'Abriendo la sesión en el dispositivo',
                          ),
                          SesionActiva(:final sesion) => _sesionActiva(
                            context,
                            sesion,
                          ),
                          SesionCerrando() => const _Guardando(
                            texto: 'Guardando el cierre en el dispositivo',
                          ),
                          SesionCerrada(:final sesion) => _sesionCerrada(
                            context,
                            sesion,
                          ),
                          SesionError(:final mensaje) => _sesionError(
                            context,
                            mensaje,
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _margen(BuildContext context) =>
      EspaciadoCampo.margenLateral(MediaQuery.sizeOf(context).width);

  static EdgeInsets _margenContenido(BuildContext context) {
    final margen = _margen(context);
    return EdgeInsets.fromLTRB(
      margen,
      EspaciadoCampo.l,
      margen,
      EspaciadoCampo.xl,
    );
  }

  /// Etiqueta mono sobre el dato protagonista de una tarjeta. 12 px: el
  /// modo campo no lleva texto por debajo de ese tamaño.
  static Widget _etiqueta(String texto, {Color? color, IconData? icono}) {
    final estilo = TipografiaCampo.etiquetaMono.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
    if (icono == null) return Text(texto.toUpperCase(), style: estilo);
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: EspaciadoCampo.s),
        Expanded(child: Text(texto.toUpperCase(), style: estilo)),
      ],
    );
  }

  /// El error con su salida: el mensaje del bloc y «Reintentar» anclado
  /// abajo, que vuelve a pedir las condiciones.
  Widget _sesionError(BuildContext context, String mensaje) {
    final paleta = context.paleta;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: _margenContenido(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: paleta.error,
                  ),
                  const SizedBox(height: EspaciadoCampo.m),
                  Text(
                    mensaje,
                    style: TipografiaCampo.cuerpo.copyWith(color: paleta.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        BarraAccionesCampo(
          principal: BotonSecundarioCampo(
            key: const Key('boton_reintentar'),
            texto: 'Reintentar',
            icono: Icons.refresh_rounded,
            onPressed: () => _mostrarFormularioApertura(context),
          ),
        ),
      ],
    );
  }

  /// Sin sesión abierta: abrir una nueva o, si el piloto volvió a un trabajo
  /// en curso (tarea 27), cerrar el trabajo sin pasar por una sesión. Con
  /// el trabajo ya cerrado no se abre otra sesión sobre él.
  Widget _sesionInicial(BuildContext context) {
    return BlocBuilder<TrabajoCubit, TrabajoEstado>(
      builder: (context, estadoTrabajo) {
        final cerrado = estadoTrabajo is TrabajoCerrado;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: _margenContenido(context),
                children: [
                  TarjetaCampo(
                    tamano: TamanoTarjetaCampo.grande,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta(
                          cerrado ? 'Trabajo finalizado' : 'Sin sesión abierta',
                          icono: cerrado
                              ? Icons.task_alt_rounded
                              : Icons.flight_takeoff_rounded,
                        ),
                        const SizedBox(height: EspaciadoCampo.m),
                        Text(
                          cerrado
                              ? 'No queda nada por registrar'
                              : 'Medí el lote antes de despegar',
                          style: TipografiaCampo.valorDestacado,
                        ),
                        const SizedBox(height: EspaciadoCampo.s),
                        Text(
                          cerrado
                              ? 'El cierre quedó guardado en este '
                                    'dispositivo y se envía solo cuando haya '
                                    'señal.'
                              : 'Al abrir la sesión se registran viento, '
                                    'temperatura y humedad. Si una medición '
                                    'queda fuera de los límites del trabajo, '
                                    'se pide la observación y la firma del '
                                    'agrónomo.',
                          style: TipografiaCampo.cuerpoSecundario,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BarraAccionesCampo(
              secundaria: _cierreTrabajo(
                context,
                estadoTrabajo,
                context.read<SesionBloc>().trabajoUuidCliente,
                primario: false,
              ),
              principal: BotonPrimarioCampo(
                key: const Key('boton_abrir_sesion'),
                texto: 'Abrir sesión',
                icono: Icons.flight_takeoff_rounded,
                onPressed: cerrado
                    ? null
                    : () => _mostrarFormularioApertura(context),
              ),
            ),
          ],
        );
      },
    );
  }

  /// «Cerrar trabajo» (HU-09) o su confirmación, según el `TrabajoCubit`.
  Widget _cierreTrabajo(
    BuildContext context,
    TrabajoEstado estadoTrabajo,
    String trabajoUuidCliente, {
    required bool primario,
  }) {
    if (estadoTrabajo is TrabajoCerrado) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.s),
        child: NotaInlineCampo(
          key: const Key('trabajo_cerrado'),
          texto: 'Trabajo cerrado',
          color: context.paleta.exito,
          centrada: true,
        ),
      );
    }
    void alCerrar() =>
        _mostrarFormularioCierreTrabajo(context, trabajoUuidCliente);
    if (!primario) {
      return BotonSecundarioCampo(
        key: const Key('boton_cerrar_trabajo'),
        texto: 'Cerrar trabajo',
        onPressed: estadoTrabajo is TrabajoCerrando ? null : alCerrar,
      );
    }
    return BotonPrimarioCampo(
      key: const Key('boton_cerrar_trabajo'),
      texto: 'Cerrar trabajo',
      icono: Icons.task_alt_rounded,
      cargando: estadoTrabajo is TrabajoCerrando,
      onPressed: alCerrar,
    );
  }

  /// Sesión abierta: los tres datos clave como `StatChipCampo`, la nota de
  /// guardado local y, ancladas abajo, las dos acciones — reportar una
  /// incidencia (secundaria) y cerrar la sesión (principal).
  Widget _sesionActiva(BuildContext context, Sesion sesion) {
    final paleta = context.paleta;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: _margenContenido(context),
            children: [
              TarjetaCampo(
                tamano: TamanoTarjetaCampo.grande,
                acento: paleta.acento,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _etiqueta(
                      'En vuelo',
                      color: paleta.acentoTexto,
                      icono: Icons.flight_rounded,
                    ),
                    const SizedBox(height: EspaciadoCampo.m),
                    Text(
                      'Sesión activa',
                      style: TipografiaCampo.valorDestacado.copyWith(
                        color: paleta.acentoTexto,
                      ),
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    GrupoStatsCampo(
                      children: [
                        StatChipCampo(
                          key: const Key('sesion_secuencia'),
                          etiqueta: 'Secuencia',
                          valor: '${sesion.secuencia}',
                        ),
                        StatChipCampo(
                          key: const Key('sesion_inicio'),
                          etiqueta: 'Inicio',
                          valor: _formatearHora(sesion.inicio),
                        ),
                        StatChipCampo(
                          key: const Key('sesion_hectareas'),
                          etiqueta: 'Hectáreas',
                          valor: sesion.hectareasDeclaradas.toString(),
                          unidad: 'ha',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              const NotaTecnicaCampo(
                key: Key('sesion_nota_guardado'),
                texto:
                    'La apertura ya está guardada en este dispositivo. Se '
                    'envía sola cuando haya señal: podés volar sin conexión.',
              ),
            ],
          ),
        ),
        BarraAccionesCampo(
          secundaria: BotonSecundarioCampo(
            key: const Key('boton_reportar_incidencia'),
            texto: 'Reportar incidencia',
            icono: Icons.report_problem_outlined,
            onPressed: () => _reportarIncidencia(context, sesion.uuidCliente),
          ),
          principal: BotonPrimarioCampo(
            key: const Key('boton_cerrar_sesion'),
            texto: 'Cerrar sesión',
            icono: Icons.flight_land_rounded,
            onPressed: () => _mostrarFormularioCierre(context, sesion),
          ),
        ),
      ],
    );
  }

  /// Sesión cerrada: el resumen del cierre como filas «etiqueta … valor» y,
  /// ancladas abajo, las acciones — cerrar el TRABAJO (HU-09) o su
  /// confirmación y, si el cierre fue una pausa (cualquier motivo distinto
  /// de «completado»), abrir la sesión siguiente sobre el mismo trabajo.
  Widget _sesionCerrada(BuildContext context, Sesion sesion) {
    final fuePausa = sesion.motivoCierre != 'completado';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: _margenContenido(context),
            children: [
              TarjetaCampo(
                tamano: TamanoTarjetaCampo.grande,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _etiqueta(
                      'Sesión N.º ${sesion.secuencia}',
                      icono: Icons.flight_land_rounded,
                    ),
                    const SizedBox(height: EspaciadoCampo.m),
                    const Text(
                      'Sesión cerrada',
                      style: TipografiaCampo.valorDestacado,
                    ),
                    const SizedBox(height: EspaciadoCampo.m),
                    FilaDatoCampo(
                      key: const Key('sesion_motivo'),
                      etiqueta: 'Motivo',
                      valor: _etiquetaMotivo(sesion.motivoCierre ?? ''),
                    ),
                    FilaDatoCampo(
                      key: const Key('sesion_hectareas_cierre'),
                      etiqueta: 'Hectáreas declaradas (cierre)',
                      valor:
                          sesion.hectareasDeclaradasCierre?.toString() ?? '—',
                    ),
                    if (sesion.litrosConsumidos != null)
                      FilaDatoCampo(
                        key: const Key('sesion_litros_consumidos'),
                        etiqueta: 'Litros consumidos',
                        valor: sesion.litrosConsumidos!.toString(),
                      ),
                    FilaDatoCampo(
                      key: const Key('sesion_fin'),
                      etiqueta: 'Fin',
                      valor: _formatearHora(sesion.fin ?? DateTime.now()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              const NotaTecnicaCampo(
                key: Key('sesion_nota_guardado'),
                texto:
                    'El cierre ya está guardado en este dispositivo. Se '
                    'envía solo cuando haya señal.',
              ),
            ],
          ),
        ),
        BlocBuilder<TrabajoCubit, TrabajoEstado>(
          builder: (context, estadoTrabajo) => BarraAccionesCampo(
            secundaria: fuePausa && estadoTrabajo is! TrabajoCerrado
                ? BotonSecundarioCampo(
                    key: const Key('boton_abrir_otra_sesion'),
                    texto: 'Abrir otra sesión',
                    icono: Icons.flight_takeoff_rounded,
                    onPressed: estadoTrabajo is TrabajoCerrando
                        ? null
                        : () => _mostrarFormularioApertura(context),
                  )
                : null,
            principal: _cierreTrabajo(
              context,
              estadoTrabajo,
              sesion.trabajoUuidCliente,
              primario: true,
            ),
          ),
        ),
      ],
    );
  }

  void _reportarIncidencia(BuildContext context, String sesionUuidCliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidenciaPantalla(
          crearCubit: () => widget.crearIncidenciaCubit(sesionUuidCliente),
        ),
      ),
    );
  }

  String _formatearHora(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _etiquetaMotivo(String motivo) {
    for (final tuple in _motivosCierre) {
      if (tuple.$1 == motivo) return tuple.$2;
    }
    return motivo;
  }
}

/// Lo que se ve mientras el repositorio escribe en `drift`: dura un
/// instante, sin esqueleto (sistema visual, §1.4).
class _Guardando extends StatelessWidget {
  const _Guardando({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspaciadoCampo.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: context.paleta.acento),
            const SizedBox(height: EspaciadoCampo.l),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TipografiaCampo.cuerpoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja de formulario del modo campo: título, apoyo, campos con scroll y
/// las dos acciones fuera del scroll (cancelar como secundaria, confirmar
/// como primaria). Ocupa casi todo el ancho para que los campos midan lo
/// que un dedo con guante necesita. Solo arma el aspecto — cada formulario
/// trae sus campos, su `Form` y su botón de confirmar con su `Key`.
class _DialogoCampo extends StatelessWidget {
  const _DialogoCampo({
    required this.titulo,
    required this.formKey,
    required this.onCancelar,
    required this.botonConfirmar,
    required this.children,
    this.apoyo,
  });

  final String titulo;
  final String? apoyo;
  final GlobalKey<FormState> formKey;
  final VoidCallback onCancelar;
  final Widget botonConfirmar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final radio =
        Theme.of(context).extension<TemaCampo>()?.radioTarjetaGrande ??
        const TemaCampo().radioTarjetaGrande;
    final cancelar = BotonSecundarioCampo(
      texto: 'Cancelar',
      onPressed: onCancelar,
    );
    // Con el texto escalado, dos botones lado a lado cortan la etiqueta:
    // se apilan, con la acción principal arriba.
    final apilar = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Dialog(
      backgroundColor: paleta.superficieElevada,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: EspaciadoCampo.m,
        vertical: EspaciadoCampo.l,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radio),
        side: BorderSide(color: paleta.borde),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EspaciadoCampo.l,
            EspaciadoCampo.xl,
            EspaciadoCampo.l,
            EspaciadoCampo.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(titulo, style: TipografiaCampo.tituloSeccion),
              ),
              if (apoyo != null) ...[
                const SizedBox(height: EspaciadoCampo.xs),
                Text(apoyo!, style: TipografiaCampo.cuerpoSecundario),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
              if (apilar) ...[
                botonConfirmar,
                const SizedBox(height: EspaciadoCampo.m),
                cancelar,
              ] else
                Row(
                  children: [
                    Expanded(child: cancelar),
                    const SizedBox(width: EspaciadoCampo.m),
                    Expanded(child: botonConfirmar),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
