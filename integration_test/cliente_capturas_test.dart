import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/di/dependencias_cliente.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';

void main() {
  binding;
  ConfiguracionMapa.teselas = false;
  testWidgets('cliente: recorrido de capturas', (t) async {
    await t.pumpWidget(
      AppCliente(dependencias: DependenciasCliente.demo(primerUso: true)),
    );
    await captura(t, 'cliente_01_splash', ms: 300);
    await paso('onboarding', () async {
      await captura(t, 'cliente_02_onboarding_1', ms: 3000);
      await tocar(t, find.byKey(const Key('onboarding-continuar')));
      await captura(t, 'cliente_03_onboarding_2');
      await tocar(t, find.byKey(const Key('onboarding-continuar')));
      await captura(t, 'cliente_04_onboarding_3');
      await tocar(t, find.byKey(const Key('onboarding-continuar')));
    });
    await paso('login y registro', () async {
      await captura(t, 'cliente_05_login');
      await tocar(t, find.byKey(const Key('login-crear-cuenta')));
      await captura(t, 'cliente_06_registro');
      await tocar(t, find.byKey(const Key('registro-volver')));
      await t.enterText(find.bySemanticsLabel('Usuario'), 'ana.finca');
      await t.enterText(find.bySemanticsLabel('Contraseña'), 'segura123');
      await esperar(t, 300);
      await tocar(t, find.byKey(const Key('login-ingresar')), ms: 1800);
    });
    await paso('inicio', () async {
      await captura(t, 'cliente_07_inicio');
      await bajar(t, 500);
      await captura(t, 'cliente_08_inicio_abajo');
    });
    await paso('solicitar', () async {
      await tocar(t, find.text('Solicitar').last, ms: 1500);
      await captura(t, 'cliente_09_solicitar_lote', ms: 2500);
    });
    await paso('solicitudes', () async {
      await tocar(t, find.text('Solicitudes').last, ms: 1500);
      await captura(t, 'cliente_10_solicitudes_lista', ms: 1500);
    });
    await paso('detalle de solicitud', () async {
      await tocar(t, porPrefijo('solicitud-'), ms: 2000);
      await captura(t, 'cliente_11_solicitud_detalle', ms: 1500);
      await bajar(t, 500);
      await captura(t, 'cliente_12_solicitud_detalle_abajo');
      await atras(t);
    });
    await paso('cuenta', () async {
      await tocar(t, find.text('Cuenta').last, ms: 1500);
      await captura(t, 'cliente_13_cuenta');
      await bajar(t, 500);
      await captura(t, 'cliente_14_cuenta_abajo');
    });
  });
}
