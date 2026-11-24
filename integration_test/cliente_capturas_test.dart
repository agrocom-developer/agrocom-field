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
      await tocar(t, find.text('Maíz La Curva'));
      await captura(t, 'cliente_10_solicitar_lote_elegido');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await captura(t, 'cliente_11_solicitar_aplicacion');
      await tocar(t, find.text('Insecticida piretroide'));
      await bajar(t, 300);
      await captura(t, 'cliente_12_solicitar_producto');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await tocar(t, find.byKey(const ValueKey('fecha-2')));
      await tocar(t, find.byKey(const ValueKey('ventana-amanecer')));
      await captura(t, 'cliente_13_solicitar_cuando');
      await tocar(t, find.byKey(const ValueKey('solicitar-continuar')));
      await captura(t, 'cliente_14_solicitar_resumen', ms: 1500);
      await tocar(
        t,
        find.byKey(const ValueKey('solicitar-continuar')),
        ms: 1500,
      );
      await captura(t, 'cliente_15_buscando_proveedor', ms: 1500);
    });
    await paso('servicios', () async {
      await tocar(t, find.byKey(const ValueKey('buscando-ver-servicio')));
      await captura(t, 'cliente_16_servicio_buscando');
      await atras(t);
      await tocar(t, find.text('Servicios').last, ms: 1500);
      await captura(t, 'cliente_17_servicios_lista');
      await tocar(t, find.byKey(const ValueKey('servicio-srv-1042')));
      await captura(t, 'cliente_18_servicio_en_curso');
      await bajar(t, 500);
      await captura(t, 'cliente_19_servicio_en_curso_abajo');
      await bajar(t, -500);
      await tocar(t, find.text('Seguir en vivo'), ms: 1500);
      await captura(t, 'cliente_20_seguimiento', ms: 2000);
      await bajar(t, 500);
      await captura(t, 'cliente_21_seguimiento_abajo');
      await atras(t);
      await atras(t);
    });
    await paso('conformidad y calificación', () async {
      await tocar(t, find.byKey(const ValueKey('servicio-srv-1036')));
      await captura(t, 'cliente_22_servicio_por_conformar');
      await tocar(t, find.text('Revisar y dar conformidad'), ms: 1500);
      await captura(t, 'cliente_23_acta');
      await bajar(t, 600);
      await captura(t, 'cliente_24_acta_abajo');
      await tocar(t, find.byKey(const ValueKey('dar-conformidad')));
      await captura(t, 'cliente_25_confirmar_conformidad');
      await tocar(
        t,
        find.byKey(const ValueKey('confirmar-conformidad')),
        ms: 1500,
      );
      await tocar(t, find.text('Calificar al proveedor'));
      await captura(t, 'cliente_26_calificar');
      await tocar(t, find.bySemanticsLabel('4 estrellas'));
      await captura(t, 'cliente_27_calificar_estrellas');
      await tocar(
        t,
        find.byKey(const ValueKey('enviar-calificacion')),
        ms: 1500,
      );
      await captura(t, 'cliente_28_calificado');
      await atras(t);
    });
    await paso('servicio calificado y problema', () async {
      await tocar(t, find.byKey(const ValueKey('servicio-srv-1039')));
      await captura(t, 'cliente_29_servicio_calificado');
      await atras(t);
    });
    await paso('cuenta', () async {
      await tocar(t, find.text('Cuenta').last, ms: 1500);
      await captura(t, 'cliente_30_cuenta');
      await bajar(t, 500);
      await captura(t, 'cliente_31_cuenta_abajo');
    });
  });
}
