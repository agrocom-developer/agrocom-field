import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_demo.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_cubit.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/componentes/chat_campo.dart';

import '../../ui/ui_negociacion_cliente/ayudas.dart';

void main() {
  testWidgets('un servicio adjudicado abre el chat con su evento de sistema', (
    tester,
  ) async {
    final almacen = almacenDePrueba();
    await montar(
      tester,
      pantalla: const ChatPantalla(solicitudId: '4102', intervalo: null),
      dependencias: dependenciasDePrueba(almacen),
    );
    await asentar(tester);
    expect(find.byType(BurbujaTextoChatCampo), findsWidgets);
    expect(find.byType(BurbujaFotoChatCampo), findsNothing);
  });

  testWidgets(
    'los mensajes de foto y de sistema se dibujan con su componente',
    (tester) async {
      final almacen = almacenDePrueba();
      final ahora = almacen.ahora;
      almacen
        ..agregarMensaje(
          '4102',
          MensajeChat(
            id: 'm-sis',
            texto: 'El servicio empezó.',
            creadoEn: ahora,
            propio: false,
            tipo: TipoMensajeChat.sistema,
            evento: 'servicio_iniciado',
          ),
        )
        ..agregarMensaje(
          '4102',
          MensajeChat(
            id: 'm-foto',
            texto: 'Así queda el punto de carga.',
            creadoEn: ahora,
            propio: false,
            tipo: TipoMensajeChat.foto,
            ruta: 'assets/imagenes/fondo_dron_pulverizando.jpg',
          ),
        );
      await montar(
        tester,
        pantalla: const ChatPantalla(solicitudId: '4102', intervalo: null),
        dependencias: dependenciasDePrueba(almacen),
      );
      await asentar(tester);
      expect(find.byType(EventoSistemaChatCampo), findsOneWidget);
      expect(find.text('El servicio empezó.'), findsOneWidget);
      expect(find.byType(BurbujaFotoChatCampo), findsOneWidget);
      expect(find.text('Así queda el punto de carga.'), findsOneWidget);
    },
  );

  test('enviar la misma foto dos veces reutiliza la clave', () async {
    final almacen = almacenDePrueba();
    final repo = SeguimientoDemo(almacen, latencia: Duration.zero);
    final bytes = Uint8List.fromList([1, 2, 3]);
    final a = await repo.enviarFoto('4102', bytes: bytes, claveCliente: 'k1');
    final b = await repo.enviarFoto('4102', bytes: bytes, claveCliente: 'k1');
    expect(a.id, b.id);
    expect(a.tipo, TipoMensajeChat.foto);
  });

  test(
    'el cubit agrega la foto enviada y no duplica en el reintento',
    () async {
      final almacen = almacenDePrueba();
      final cubit = ChatCubit(
        repositorio: SeguimientoDemo(almacen, latencia: Duration.zero),
        solicitudId: '4102',
        intervalo: null,
      );
      await cubit.cargar();
      final antes = cubit.state.mensajes.length;
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(await cubit.enviarFoto(bytes, pie: 'hola'), isTrue);
      expect(cubit.state.mensajes.length, antes + 1);
      expect(cubit.state.mensajes.last.tipo, TipoMensajeChat.foto);
      await cubit.close();
    },
  );

  testWidgets('el redactor ofrece adjuntar una foto', (tester) async {
    await montar(
      tester,
      pantalla: const ChatPantalla(solicitudId: '4102', intervalo: null),
      dependencias: dependenciasDePrueba(almacenDePrueba()),
    );
    await asentar(tester);
    await tester.tap(find.byKey(const ValueKey('chat-adjuntar')));
    await asentar(tester);
    expect(find.text('Tomar una foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
  });
}
