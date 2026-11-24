// Recorrido visual del flavor cliente contra la API real (no la demo):
// acceso, publicar una solicitud, comparar ofertas, elegir piloto, seguir el
// servicio (fotos, chat, ubicación), precio final y calificación.
//
// La contraparte (los pilotos que ofertan y ejecutan) actúa por la API con
// `Contraparte`. No corre en `bin/verify` ni en CI: necesita la API local con
// los datos demo y un simulador. Ver docs/gestion/recorrido-visual.md.
//
//   tool/recorrido_visual.sh cliente <simulador>
import 'package:agrocom_field/cliente/acceso/data/acceso_red.dart';
import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/auth/dispositivo_store.dart';
import 'package:agrocom_field/nucleo/auth/token_store.dart';
import 'package:agrocom_field/nucleo/entorno/api_base_url.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';
import 'contraparte_api.dart';

class _Memoria implements TokenStore, OnboardingStore {
  String? token;
  @override
  Future<String?> leerToken() async => token;
  @override
  Future<void> guardarToken(String t) async => token = t;
  @override
  Future<void> borrarToken() async => token = null;
  @override
  Future<bool> visto() async => true;
  @override
  Future<void> marcar() async {}
}

/// Vuelve atrás hasta ver la barra de pestañas del cliente.
Future<void> alInicio(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    if (find.text('Solicitudes').evaluate().isNotEmpty) return;
    await atras(t);
  }
}

/// Abre el detalle de la solicitud [id] desde la pestaña Solicitudes.
Future<void> abrirSolicitud(WidgetTester t, int id) async {
  await alInicio(t);
  await tocar(t, find.text('Solicitudes').last, ms: 2500);
  await tocar(t, find.byKey(ValueKey('solicitud-$id')), ms: 2500);
}

void main() {
  binding;
  ConfiguracionMapa.teselas = false;
  testWidgets('cliente conectado: del pedido a la calificación', (t) async {
    final marca = DateTime.now().millisecondsSinceEpoch % 100000;
    final rodrigo = await Contraparte.ingresar('rodrigo.suarez');
    final carlos = await Contraparte.ingresar(
      'carlos.mamani',
      rol: 'proveedor',
    );
    final cliente = await Contraparte.ingresar('agro.sanrafael');
    int? solicitudId;

    final memoria = _Memoria();
    final api = ApiClient(baseUrl: apiBaseUrl, tokenStore: memoria);
    await t.pumpWidget(
      AppCliente(
        dependencias: DependenciasCliente.red(
          api: api,
          tokenStore: memoria,
          dispositivoStore: DispositivoStoreSeguro(),
          onboarding: memoria,
        ),
      ),
    );

    await paso('acceso', () async {
      await captura(t, 'cliente_01_acceso', ms: 3500);
      await escribir(
        t,
        find.byKey(const Key('login-usuario')),
        'agro.sanrafael',
      );
      await escribir(t, find.byKey(const Key('login-contrasena')), '0000');
      await esperar(t, 300);
      await tocar(t, find.byKey(const Key('login-ingresar')), ms: 3500);
      await captura(t, 'cliente_02_inicio');
      expect(memoria.token, isNotNull);
    });

    await paso('publicar solicitud', () async {
      await tocar(t, find.text('Solicitar').last, ms: 2500);
      await captura(t, 'cliente_03_publicar_lote', ms: 2000);
      await tocar(t, find.text('Lote Norte'));
      await captura(t, 'cliente_04_publicar_lote_elegido');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await escribir(
        t,
        find.byKey(const ValueKey('solicitar-hectareas')),
        '60',
      );
      await tocar(t, find.text('Insecticida piretroide'));
      await captura(t, 'cliente_05_publicar_aplicacion');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await tocar(t, find.byKey(const ValueKey('fecha-2')));
      await escribir(
        t,
        find.byKey(const ValueKey('solicitar-observaciones')),
        'Recorrido visual $marca',
      );
      await captura(t, 'cliente_06_publicar_cuando');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await escribir(t, find.byKey(const ValueKey('solicitar-precio')), '118');
      await captura(t, 'cliente_07_publicar_precio');
      await tocar(
        t,
        find.byKey(const ValueKey('solicitar-continuar')),
        ms: 3500,
      );
      await captura(t, 'cliente_08_publicada');
    });

    await paso('ofertas de los pilotos', () async {
      final lista = await cliente.obtener('/api/solicitudes');
      solicitudId = (lista['solicitudes'] as List)
          .cast<Map>()
          .where((s) => '${s['observaciones']}'.contains('$marca'))
          .map((s) => s['id'] as int)
          .first;
      await rodrigo.ofertar(
        solicitudId!,
        precioHa: '125',
        nota: 'Dron T50, puedo ir esa mañana.',
      );
      await carlos.ofertar(solicitudId!);
    });

    await paso('ver y comparar ofertas', () async {
      await atras(t);
      await captura(t, 'cliente_09_inicio_con_ofertas', ms: 800);
      await abrirSolicitud(t, solicitudId!);
      await captura(t, 'cliente_10_solicitud_con_ofertas');
      await tocar(t, find.byKey(const ValueKey('ver-ofertas')), ms: 2500);
      await captura(t, 'cliente_11_ofertas', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'cliente_12_ofertas_abajo');
      await bajar(t, -500);
    });

    int? ofertaElegida;
    await paso('contraofertar', () async {
      final ofertas =
          (await cliente.obtener(
                '/api/solicitudes/$solicitudId/ofertas',
              ))['ofertas']
              as List;
      // La de Rodrigo es la contraoferta de 125; la elegida es la suya.
      ofertaElegida =
          ofertas.cast<Map>().firstWhere(
                (o) => '${o['precio_ha']}'.startsWith('125'),
              )['id']
              as int;
      await tocar(t, find.byKey(ValueKey('contraofertar-$ofertaElegida')));
      await captura(t, 'cliente_13_contraofertar');
      await atras(t);
    });

    await paso('elegir piloto', () async {
      await tocar(t, find.byKey(ValueKey('aceptar-$ofertaElegida')));
      await captura(t, 'cliente_14_confirmar_eleccion');
      await tocar(t, find.byKey(const ValueKey('confirmar-aceptar')), ms: 3000);
      await captura(t, 'cliente_15_piloto_elegido');
    });

    await paso('el piloto ejecuta', () async {
      await rodrigo.iniciarServicio(solicitudId!);
      await rodrigo.marcarAvance(solicitudId!, '40');
      await rodrigo.subirFoto(solicitudId!);
      await rodrigo.subirFoto(
        solicitudId!,
        recurso: 'assets/imagenes/fondo_dron_agras_t50.jpg',
      );
      await rodrigo.enviarUbicacion(solicitudId!, -17.5341, -63.1968);
      await rodrigo.escribir(solicitudId!, 'Ya empecé el primer tramo.');
    });

    await paso('seguimiento', () async {
      await abrirSolicitud(t, solicitudId!);
      await captura(t, 'cliente_16_solicitud_en_ejecucion');
      await tocar(t, find.byKey(const ValueKey('ver-seguimiento')), ms: 3000);
      await captura(t, 'cliente_17_seguimiento', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'cliente_18_seguimiento_fotos');
      await bajar(t, -500);
    });

    await paso('chat', () async {
      await tocar(t, find.byKey(const ValueKey('abrir-chat')), ms: 2500);
      await captura(t, 'cliente_19_chat');
      await escribir(
        t,
        find.byKey(const ValueKey('chat-campo')),
        'Perfecto, gracias. Avísame al terminar.',
      );
      await tocar(t, find.byKey(const ValueKey('chat-enviar')), ms: 2000);
      await captura(t, 'cliente_20_chat_enviado');
      await atras(t);
    });

    await paso('el piloto finaliza', () async {
      await rodrigo.marcarAvance(solicitudId!, '95');
      await rodrigo.subirFoto(solicitudId!, tipo: 'foto_final');
      await rodrigo.cerrarServicio(solicitudId!, '58');
    });

    await paso('precio final', () async {
      await abrirSolicitud(t, solicitudId!);
      await captura(t, 'cliente_21_servicio_finalizado', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'cliente_22_precio_final');
      await bajar(t, -500);
    });

    await paso('calificar', () async {
      await tocar(t, find.byKey(const ValueKey('calificar')), ms: 2000);
      await captura(t, 'cliente_23_calificar');
      await tocar(t, find.bySemanticsLabel('5 estrellas'));
      await captura(t, 'cliente_24_calificar_estrellas');
      await tocar(
        t,
        find.byKey(const ValueKey('enviar-calificacion')),
        ms: 3000,
      );
      await captura(t, 'cliente_25_calificado');
    });

    await paso('cuenta', () async {
      await atras(t);
      await tocar(t, find.text('Cuenta').last, ms: 2000);
      await captura(t, 'cliente_26_cuenta');
    });

    expect(pasosFallidos, isEmpty, reason: pasosFallidos.join('\n'));
  });
}
