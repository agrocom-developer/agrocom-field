import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/calificacion_repositorio.dart';

/// El cliente califica al proveedor: estrellas, comentario opcional y un
/// botón. Al terminar, confirmación inmediata y salida (sistema visual, §9).
class CalificarPantalla extends StatefulWidget {
  const CalificarPantalla({required this.servicio, super.key});

  final Servicio servicio;

  @override
  State<CalificarPantalla> createState() => _CalificarPantallaState();
}

class _CalificarPantallaState extends State<CalificarPantalla> {
  int _puntaje = 0;
  final _comentario = TextEditingController();
  bool _enviando = false;

  static const _etiquetas = [
    '',
    'Mala',
    'Regular',
    'Buena',
    'Muy buena',
    'Excelente',
  ];

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final repo = context.read<CalificacionRepositorio>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    await repo.calificarProveedor(
      servicioId: widget.servicio.id,
      puntaje: _puntaje,
      comentario: _comentario.text.trim().isEmpty
          ? null
          : _comentario.text.trim(),
    );
    HapticaCampo.confirmacion();
    navegador.pop(true);
    mensajero.showSnackBar(
      const SnackBar(content: Text('Gracias por calificar el servicio')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.servicio.proveedor;
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar servicio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            if (p != null) ...[
              Center(child: AvatarProveedor(p, tamano: 72)),
              const SizedBox(height: 12),
              Text(
                p.nombre,
                style: texto.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                '${widget.servicio.lote.nombre} · '
                '${FormatoMarketplace.hectareas(widget.servicio.hectareasDeclaradas)}',
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              '¿Cómo fue el servicio?',
              style: texto.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: CalificacionCampo(
                valor: _puntaje,
                tamano: 44,
                onCambio: (v) => setState(() => _puntaje = v),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Text(
                _etiquetas[_puntaje],
                style: texto.titleMedium?.copyWith(color: paleta.acentoTexto),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comentario,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(EspaciadoCampo.l),
        child: BotonPrimarioCampo(
          texto: 'Enviar calificación',
          cargando: _enviando,
          onPressed: _puntaje == 0 || _enviando ? null : _enviar,
        ),
      ),
    );
  }
}
