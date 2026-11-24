// Recorrido visual del flavor piloto contra la API real (no la demo): mapa de
// solicitudes abiertas, detalle, contraoferta, aceptación del cliente,
// ejecución, foto de avance y finalización.
//
// La contraparte (el cliente que publica y elige) actúa por la API con
// `Contraparte`. La cámara se reemplaza por una foto de los recursos, porque
// el simulador no tiene cámara. No corre en `bin/verify` ni en CI: necesita la
// API local con los datos demo y un simulador. Ver
// docs/gestion/recorrido-visual.md.
//
//   tool/recorrido_visual.sh piloto <simulador>
import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/di/composicion_proveedor.dart';
import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/app_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';
import 'contraparte_api.dart';

/// Cámara del recorrido: entrega siempre la misma foto de los recursos.
class _CamaraDeRecorrido implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async => (await rootBundle.load(
    'assets/imagenes/fondo_dron_pulverizando_vertical.jpg',
  )).buffer.asUint8List();
}

void main() {
  binding;
  ConfiguracionMapa.teselas = false;
  testWidgets('piloto conectado: del mapa a la finalización', (t) async {
    final marca = 120 + DateTime.now().millisecondsSinceEpoch % 40;
    final cliente = await Contraparte.ingresar('agro.sanrafael');
    final solicitudId = await cliente.publicarSolicitud(
      precioHa: '$marca',
      hectareas: '45',
      observaciones: 'Recorrido visual piloto $marca',
    );

    final c = await componerProveedor(
      Flavor.piloto,
      selectorFoto: _CamaraDeRecorrido(),
    );
    await t.pumpWidget(
      AppProveedor(
        proveedor: c.proveedor,
        acceso: c.acceso,
        selectorImagen: c.selectorImagen,
        construirShell: (context, alSalir) => ShellPiloto(alSalir: alSalir),
      ),
    );

    await paso('acceso', () async {
      await captura(t, 'piloto_01_acceso', ms: 3500);
      if (find.text('Entrar').evaluate().isNotEmpty) {
        await escribir(t, find.bySemanticsLabel('Usuario'), 'rodrigo.suarez');
        await escribir(t, find.bySemanticsLabel('Contraseña'), '0000');
        await esperar(t, 300);
        await tocar(t, find.text('Entrar').last, ms: 4000);
      }
      await captura(t, 'piloto_02_mapa', ms: 2500);
    });

    await paso('mapa y solicitud abierta', () async {
      await bajar(t, 400);
      await captura(t, 'piloto_03_mapa_lista');
      final tarjeta = find.bySemanticsLabel(RegExp('Bs $marca'));
      await tocar(t, tarjeta, ms: 2500);
      await captura(t, 'piloto_04_solicitud_detalle', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'piloto_05_solicitud_detalle_abajo');
      await bajar(t, -500);
    });

    await paso('contraofertar', () async {
      await tocar(t, find.text('Contraofertar mi precio'), ms: 1500);
      await captura(t, 'piloto_06_contraoferta_hoja');
      await escribir(
        t,
        find.bySemanticsLabel('Tu precio por hectárea (Bs)'),
        '${marca + 8}',
      );
      await esperar(t, 300);
      await captura(t, 'piloto_07_contraoferta_precio');
      await tocar(t, find.text('Enviar contraoferta'), ms: 3000);
      await captura(t, 'piloto_08_contraoferta_enviada');
    });

    int? ofertaId;
    await paso('el cliente elige', () async {
      final r = await cliente.obtener('/api/solicitudes/$solicitudId/ofertas');
      ofertaId = ((r['ofertas'] as List).first as Map)['id'] as int;
      await cliente.aceptarOferta(ofertaId!);
    });

    await paso('mis ofertas', () async {
      await atras(t);
      await tocar(t, find.text('Ofertas').last, ms: 2500);
      await captura(t, 'piloto_09_mis_ofertas');
    });

    await paso('servicio adjudicado', () async {
      await tocar(t, find.text('Servicio').last, ms: 2500);
      await captura(t, 'piloto_10_servicios', ms: 1500);
      await tocar(t, find.bySemanticsLabel(RegExp('45')), ms: 2500);
      await captura(t, 'piloto_11_servicio_adjudicado');
      await bajar(t, 500);
      await captura(t, 'piloto_12_servicio_adjudicado_abajo');
      await bajar(t, -500);
    });

    await paso('marcar en ejecución', () async {
      await tocar(t, find.text('Marcar en ejecución'), ms: 3000);
      await captura(t, 'piloto_13_servicio_en_ejecucion');
    });

    await paso('foto de avance', () async {
      await tocar(t, find.text('Subir foto de avance'), ms: 3500);
      await captura(t, 'piloto_14_foto_de_avance', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'piloto_15_foto_de_avance_abajo');
      await bajar(t, -500);
    });

    await paso('marcar avance', () async {
      await tocar(t, find.text('Marcar avance').last, ms: 1500);
      await captura(t, 'piloto_16_marcar_avance_hoja');
      await escribir(t, find.byType(TextField).first, '22');
      await esperar(t, 300);
      await captura(t, 'piloto_17_marcar_avance_escrito');
      await tocar(t, find.text('Guardar avance'), ms: 2500);
      await captura(t, 'piloto_18_avance_guardado');
    });

    await paso('finalizar', () async {
      await tocar(t, find.text('Finalizar servicio'), ms: 1500);
      await captura(t, 'piloto_19_finalizar_hoja');
      await escribir(t, find.byType(TextField).first, '44');
      await esperar(t, 300);
      await tocar(t, find.text('Finalizar').last, ms: 4000);
      await captura(t, 'piloto_20_servicio_finalizado', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'piloto_21_servicio_finalizado_abajo');
    });

    // Una solicitud finalizada sin calificar sigue ocupando el equipo del
    // piloto: el cliente la califica para dejar la base lista para otra corrida.
    await paso('el cliente califica', () async {
      await cliente.calificar(solicitudId);
    });

    await paso('perfil', () async {
      await atras(t);
      await tocar(t, find.text('Perfil').last, ms: 2500);
      await captura(t, 'piloto_22_perfil');
    });

    expect(pasosFallidos, isEmpty, reason: pasosFallidos.join('\n'));
  });
}
