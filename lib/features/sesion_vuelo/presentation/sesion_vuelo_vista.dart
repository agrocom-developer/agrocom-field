import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../incidencias/presentation/incidencia_pantalla.dart';
import '../domain/auxiliar.dart';
import '../domain/reglas_condiciones.dart';
import '../domain/sesion.dart';
import 'sesion_bloc.dart';
import 'sesion_estado.dart';
import 'sesion_evento.dart';

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
class SesionVueloVista extends StatefulWidget {
  const SesionVueloVista({required this.crearIncidenciaCubit, super.key});

  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  State<SesionVueloVista> createState() => _SesionVueloVistaState();
}

class _SesionVueloVistaState extends State<SesionVueloVista> {
  late GlobalKey<FormState> _formKey;
  late GlobalKey<FormState> _formAperturaKey;
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
  String? _motivoSeleccionado;
  bool _condicionesFueraDeRango = false;
  int? _auxiliarSeleccionadoId;

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
    );
  }

  void _mostrarFormularioApertura(BuildContext context) {
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
        // (capturado por closure) para `Theme.of`/`context.read<SesionBloc>`,
        // que sí es descendiente del `BlocProvider<SesionBloc>`.
        builder: (_, setStateDialog) {
          void alCambiarMedicion(String _) {
            final fueraDeRango = _calcularFueraDeRango();
            if (fueraDeRango != _condicionesFueraDeRango) {
              setStateDialog(() => _condicionesFueraDeRango = fueraDeRango);
            }
          }

          return AlertDialog(
            title: const Text('Condiciones al abrir sesión'),
            content: SingleChildScrollView(
              child: Form(
                key: _formAperturaKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('apertura_viento'),
                      controller: _vientoController,
                      decoration: const InputDecoration(
                        labelText: 'Viento (km/h) *',
                      ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('apertura_temperatura'),
                      controller: _temperaturaController,
                      decoration: const InputDecoration(
                        labelText: 'Temperatura (°C) *',
                      ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('apertura_humedad'),
                      controller: _humedadController,
                      decoration: const InputDecoration(
                        labelText: 'Humedad (%) *',
                      ),
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
                      const SizedBox(height: 16),
                      Text(
                        'Condiciones fuera de rango: se necesita la '
                        'observación y firma del agrónomo.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('apertura_observacion'),
                        controller: _observacionController,
                        decoration: const InputDecoration(
                          labelText: 'Observación del agrónomo *',
                        ),
                        maxLines: 3,
                        validator: (valor) {
                          if (!_condicionesFueraDeRango) return null;
                          if (valor == null || valor.trim().isEmpty) {
                            return 'La observación es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('apertura_firma'),
                        controller: _firmaController,
                        decoration: const InputDecoration(
                          labelText: 'Firma del agrónomo *',
                        ),
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
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Relevo de piloto (opcional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Auxiliar>>(
                      future: _auxiliaresFuture,
                      builder: (context, snapshot) {
                        final auxiliares = snapshot.data ?? const <Auxiliar>[];
                        return DropdownButtonFormField<int?>(
                          key: const Key('apertura_auxiliar'),
                          initialValue: _auxiliarSeleccionadoId,
                          decoration: const InputDecoration(
                            labelText: 'Auxiliar (opcional)',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              child: Text('Sin auxiliar'),
                            ),
                            ...auxiliares.map(
                              (auxiliar) => DropdownMenuItem<int?>(
                                value: auxiliar.id,
                                child: Text(auxiliar.nombre),
                              ),
                            ),
                          ],
                          onChanged: (valor) => setStateDialog(
                            () => _auxiliarSeleccionadoId = valor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('apertura_dron_id'),
                      controller: _dronIdController,
                      decoration: const InputDecoration(
                        labelText: 'Id de dron (opcional)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) return null;
                        if (int.tryParse(valor) == null) {
                          return 'Ingresá un número entero válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('apertura_hectarea_inicial_acumulada'),
                      controller: _hectareaInicialController,
                      decoration: const InputDecoration(
                        labelText:
                            'Hectárea inicial acumulada (opcional, si es '
                            'relevo)',
                      ),
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
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('boton_confirmar_apertura'),
                onPressed: () {
                  if (!_formAperturaKey.currentState!.validate()) return;

                  context.read<SesionBloc>().add(
                    SesionAbrirSolicitada(
                      vientoKmh: Decimal.parse(_vientoController.text),
                      temperaturaC: Decimal.parse(_temperaturaController.text),
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
                child: const Text('Abrir sesión'),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hectareaInicialAcumulada == null)
                  TextFormField(
                    key: const Key('cierre_hectareas'),
                    controller: _hectareasController,
                    decoration: const InputDecoration(
                      labelText: 'Hectáreas declaradas *',
                    ),
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
                else
                  TextFormField(
                    key: const Key('cierre_acumulado_final'),
                    controller: _acumuladoFinalController,
                    decoration: InputDecoration(
                      labelText: 'Acumulado final del RC *',
                      helperText:
                          'Acumulado inicial registrado: '
                          '$hectareaInicialAcumulada',
                    ),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('cierre_motivo'),
                  initialValue: _motivoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de cierre *',
                  ),
                  items: _motivosCierre
                      .map(
                        (tuple) => DropdownMenuItem(
                          value: tuple.$1,
                          child: Text(tuple.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    setState(() => _motivoSeleccionado = valor);
                  },
                  validator: (valor) => (valor == null || valor.isEmpty)
                      ? 'Seleccioná un motivo de cierre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('cierre_litros'),
                  controller: _litrosController,
                  decoration: const InputDecoration(
                    labelText: 'Litros consumidos (opcional)',
                  ),
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_confirmar_cierre'),
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;

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
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión de vuelo')),
      body: BlocConsumer<SesionBloc, SesionEstado>(
        listener: (context, estado) {
          if (estado is SesionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, estado) => switch (estado) {
          SesionInicial() => Center(
            child: FilledButton(
              key: const Key('boton_abrir_sesion'),
              onPressed: () => _mostrarFormularioApertura(context),
              child: const Text('Abrir sesión'),
            ),
          ),
          SesionAbriendo() => const Center(child: CircularProgressIndicator()),
          SesionActiva(:final sesion) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sesión activa',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(label: 'Secuencia', value: '${sesion.secuencia}'),
                  _InfoRow(
                    label: 'Inicio',
                    value: _formatearHora(sesion.inicio),
                  ),
                  _InfoRow(
                    label: 'Hectáreas declaradas',
                    value: sesion.hectareasDeclaradas.toString(),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('boton_reportar_incidencia'),
                    onPressed: () =>
                        _reportarIncidencia(context, sesion.uuidCliente),
                    child: const Text('Reportar incidencia'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('boton_cerrar_sesion'),
                    onPressed: () => _mostrarFormularioCierre(context, sesion),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
          SesionCerrando() => const Center(child: CircularProgressIndicator()),
          SesionCerrada(:final sesion) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sesión cerrada',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(
                    label: 'Motivo',
                    value: _etiquetaMotivo(sesion.motivoCierre ?? ''),
                  ),
                  _InfoRow(
                    label: 'Hectáreas declaradas (cierre)',
                    value: sesion.hectareasDeclaradasCierre?.toString() ?? '—',
                  ),
                  if (sesion.litrosConsumidos != null)
                    _InfoRow(
                      label: 'Litros consumidos',
                      value: sesion.litrosConsumidos!.toString(),
                    ),
                  _InfoRow(
                    label: 'Fin',
                    value: _formatearHora(sesion.fin ?? DateTime.now()),
                  ),
                ],
              ),
            ),
          ),
          SesionError(:final mensaje) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    mensaje,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('boton_reintentar'),
                    onPressed: () => _mostrarFormularioApertura(context),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        },
      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
