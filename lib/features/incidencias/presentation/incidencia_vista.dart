import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../domain/tipo_incidencia.dart';
import 'incidencia_cubit.dart';
import 'incidencia_estado.dart';

/// Etiquetas legibles para el selector — mismo criterio que
/// `_motivosCierre` de `sesion_vuelo_vista.dart`: el catálogo de valores lo
/// valida el servidor ([TipoIncidencia]), esta lista solo decide cómo se
/// muestran acá.
const _tiposIncidencia = [
  (TipoIncidencia.caldo, 'Caldo / mezcla'),
  (TipoIncidencia.esc, 'ESC'),
  (TipoIncidencia.bateria, 'Batería'),
  (TipoIncidencia.mecanica, 'Mecánica'),
  (TipoIncidencia.clima, 'Clima'),
  (TipoIncidencia.otro, 'Otro'),
];

/// UI pura de "reportar incidencia" (HU-08) — asume que un
/// `IncidenciaCubit` ya está provisto más arriba en el árbol
/// (`IncidenciaPantalla`, o `BlocProvider.value` en tests).
///
/// La foto es SIEMPRE obligatoria (mismo espíritu que "sin captura no
/// cierra" de HU-09): el botón de envío queda deshabilitado hasta que haya
/// una, y no hay forma de enviar sin ella.
///
/// En modo campo (ADR 0008, decisión del 1/10/2026): `EncabezadoCampo` en
/// vez de la barra de Material, el tipo con un `SelectorSegmentadoCampo`
/// desplazable, la descripción con `CampoTextoCampo` y la foto con el hueco
/// en ámbar mientras falte — el mismo patrón que el cierre de trabajo de
/// `SesionVueloVista`. Solo cambia el aspecto.
class IncidenciaVista extends StatefulWidget {
  const IncidenciaVista({super.key});

  @override
  State<IncidenciaVista> createState() => _IncidenciaVistaState();
}

class _IncidenciaVistaState extends State<IncidenciaVista> {
  late TextEditingController _descripcionController;
  TipoIncidencia? _tipoSeleccionado;
  Uint8List? _bytesFoto;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto(BuildContext context) async {
    final cubit = context.read<IncidenciaCubit>();
    final bytes = await cubit.tomarFoto();
    if (!mounted || bytes == null) return;
    setState(() => _bytesFoto = bytes);
  }

  void _guardar(BuildContext context) {
    final tipo = _tipoSeleccionado;
    final bytesFoto = _bytesFoto;
    if (tipo == null || bytesFoto == null) return;

    final descripcion = _descripcionController.text.trim();
    context.read<IncidenciaCubit>().registrar(
      tipo: tipo,
      descripcion: descripcion.isEmpty ? null : descripcion,
      bytesFoto: bytesFoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: SafeArea(
          child: BlocConsumer<IncidenciaCubit, IncidenciaEstado>(
            listener: (context, estado) {
              if (estado is IncidenciaExitosa) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incidencia registrada')),
                );
                Navigator.of(context).pop();
              }
              if (estado is IncidenciaError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estado.mensaje),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            builder: (context, estado) {
              final enviando = estado is IncidenciaEnviando;
              final puedeGuardar =
                  !enviando && _tipoSeleccionado != null && _bytesFoto != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: EncabezadoCampo(titulo: 'Reportar incidencia'),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      children: [
                        Text(
                          'Tipo de incidencia'.toUpperCase(),
                          style: TipografiaCampo.etiquetaMono,
                        ),
                        const SizedBox(height: 8),
                        // Seis tipos no entran a lo ancho en un celular: la
                        // variante desplazable los deja a su ancho natural.
                        SelectorSegmentadoCampo<TipoIncidencia?>(
                          key: const Key('selector_tipo_incidencia'),
                          desplazable: true,
                          opciones: _tiposIncidencia,
                          seleccionado: _tipoSeleccionado,
                          onSeleccionar: (valor) {
                            if (enviando) return;
                            setState(() => _tipoSeleccionado = valor);
                          },
                        ),
                        const SizedBox(height: 16),
                        CampoTextoCampo(
                          key: const Key('campo_descripcion'),
                          etiqueta: 'Descripción (opcional)',
                          controller: _descripcionController,
                          enabled: !enviando,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        if (_bytesFoto != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Theme.of(
                                    context,
                                  ).extension<TemaCampo>()?.radioTarjetaChica ??
                                  18,
                            ),
                            child: Image.memory(
                              _bytesFoto!,
                              key: const Key('preview_foto'),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        BotonAgregarPunteadoCampo(
                          key: const Key('boton_tomar_foto'),
                          texto: _bytesFoto == null
                              ? 'Tomar foto'
                              : 'Volver a tomar foto',
                          alerta: _bytesFoto == null,
                          onPressed: enviando
                              ? null
                              : () => _tomarFoto(context),
                        ),
                        if (_bytesFoto == null) ...[
                          const SizedBox(height: 10),
                          const NotaInlineCampo(
                            texto:
                                'La foto es obligatoria — sin foto no se '
                                'puede registrar la incidencia.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    child: BotonPrimarioCampo(
                      key: const Key('boton_guardar_incidencia'),
                      texto: 'Guardar incidencia',
                      cargando: enviando,
                      onPressed: puedeGuardar ? () => _guardar(context) : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
