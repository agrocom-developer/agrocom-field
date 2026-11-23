import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/ofertas_repositorio.dart';

/// Bandeja de ofertas. Aceptar y rechazar exigen red: la respuesta va directo
/// a la API con una clave de idempotencia por oferta (ADR 0009).
class OfertasPantalla extends StatefulWidget {
  const OfertasPantalla({this.reloj = DateTime.now, super.key});

  final DateTime Function() reloj;

  @override
  State<OfertasPantalla> createState() => _OfertasPantallaState();
}

class _OfertasPantallaState extends State<OfertasPantalla> {
  Timer? _temporizador;
  final _claves = <String, String>{};
  final _respondiendo = <String>{};

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  String _clave(String ofertaId) =>
      _claves.putIfAbsent(ofertaId, () => const Uuid().v4());

  Future<void> _responder(Oferta oferta, {required bool aceptar}) async {
    if (!_respondiendo.add(oferta.id)) return;
    setState(() {});
    final repo = context.read<OfertasRepositorio>();
    final mensajero = ScaffoldMessenger.of(context);
    final clave = _clave(oferta.id);
    final r = aceptar
        ? await repo.aceptar(oferta.id, claveIdempotencia: clave)
        : await repo.rechazar(oferta.id, claveIdempotencia: clave);
    if (aceptar && r == ResultadoRespuestaOferta.aceptada) {
      HapticaCampo.confirmacion();
    } else if (r == ResultadoRespuestaOferta.perdida) {
      HapticaCampo.alerta();
    }
    _respondiendo.remove(oferta.id);
    if (!mounted) return;
    setState(() {});
    mensajero.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          ResultadoRespuestaOferta.aceptada =>
            'Servicio aceptado. Ya lo tenés en «Servicio».',
          ResultadoRespuestaOferta.perdida =>
            'Otro proveedor lo aceptó antes que vos.',
          ResultadoRespuestaOferta.expirada => 'La oferta venció.',
          ResultadoRespuestaOferta.rechazada => 'Oferta rechazada.',
          ResultadoRespuestaOferta.sinConexion =>
            'Sin conexión: aceptar y rechazar necesitan red.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final ahora = widget.reloj();
    return StreamEstable<List<Oferta>>(
      crear: () => context.read<OfertasRepositorio>().observar(),
      builder: (context, snap) {
        final ofertas = [
          for (final o in snap.data ?? const <Oferta>[])
            if (o.restante(ahora) > Duration.zero) o,
        ];
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text('Ofertas', style: texto.headlineMedium),
            const SizedBox(height: 4),
            Text(
              ofertas.isEmpty
                  ? 'Te avisamos cuando haya una nueva.'
                  : '${ofertas.length} ${ofertas.length == 1 ? 'oferta vigente' : 'ofertas vigentes'}',
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: 16),
            if (snap.data == null)
              const EsqueletoCampo(alto: 260)
            else if (ofertas.isEmpty)
              const EstadoVacioMarketplace(
                icono: Icons.notifications_none_rounded,
                titulo: 'Sin ofertas por ahora',
                detalle:
                    'Las ofertas llegan primero a la flota de Agrocom y luego '
                    'a proveedores de tu zona.',
              )
            else
              for (final o in ofertas) ...[
                if (o.esDeAgrocom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: paleta.acentoTexto,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Asignación prioritaria · flota de Agrocom',
                            style: texto.labelMedium?.copyWith(
                              color: paleta.acentoTexto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                IgnorePointer(
                  ignoring: _respondiendo.contains(o.id),
                  child: Opacity(
                    opacity: _respondiendo.contains(o.id) ? 0.5 : 1,
                    child: OfertaServicioCampo(
                      titulo: '${o.lote.nombre} · ${o.lote.zona}',
                      detalle:
                          '${FormatoMarketplace.hectareas(o.lote.hectareas)} · '
                          '${o.producto} · ${FormatoMarketplace.fechaCorta(o.fechaServicio)}',
                      distancia: FormatoMarketplace.kilometros(o.distanciaKm),
                      monto: FormatoMarketplace.bs(o.pago),
                      restante: o.restante(ahora),
                      total: o.ventana,
                      onAceptar: () => _responder(o, aceptar: true),
                      onRechazar: () => _responder(o, aceptar: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            const SizedBox(height: 8),
            const AvisoMarketplace(
              mensaje:
                  'Aceptar y rechazar necesitan conexión. Una vez aceptado, el '
                  'servicio se baja al dispositivo y se ejecuta sin red.',
            ),
          ],
        );
      },
    );
  }
}
