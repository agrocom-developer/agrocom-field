// Recorrido del flavor cliente contra la API local (no la demo). Requiere la
// API en `API_BASE_URL` con los datos demo del marketplace:
//
//   flutter test integration_test/cliente_conectado_test.dart -d <simulador> \
//     --flavor cliente --dart-define-from-file=config/env.local.json
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

void main() {
  binding;
  ConfiguracionMapa.teselas = false;
  testWidgets('cliente conectado: ingreso, inicio y servicios reales', (
    t,
  ) async {
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
    await captura(t, 'conectado_01_login', ms: 3500);
    await t.enterText(find.bySemanticsLabel('Usuario'), 'agro.sanrafael');
    await t.enterText(find.bySemanticsLabel('Contraseña'), '0000');
    await esperar(t, 300);
    await tocar(t, find.byKey(const Key('login-ingresar')), ms: 3000);
    await captura(t, 'conectado_02_inicio');
    expect(find.textContaining('Rosario'), findsWidgets);
    expect(memoria.token, isNotNull);

    await tocar(t, find.text('Servicios').last, ms: 2500);
    await captura(t, 'conectado_03_servicios');
    expect(find.textContaining('Lote Norte'), findsWidgets);

    await tocar(t, find.text('Cuenta').last, ms: 2500);
    await captura(t, 'conectado_04_cuenta');
    expect(find.text('agro.sanrafael'), findsWidgets);
  });
}
