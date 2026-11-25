// Goldens de las pantallas nuevas de las fases 4 y 5 del plan 02: perfil del
// cliente, lotes, contactos, perfil público del piloto, chat con foto y
// evento del sistema, precio final por confirmar, y los estados vacío y de
// error de envío. Cada una en claro (teléfono chico y grande) y oscuro
// (grande), más el texto al 200 % en el chico; un desborde falla antes de
// comparar. Solo macOS (el render de texto difiere en Linux).
//
// Se regeneran con
// `flutter test --update-goldens test/ui/ui_pantallas_fase4/goldens_fase4_test.dart`.

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/contactos/presentation/contactos_pantalla.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/cliente/cuenta/presentation/cuenta_pantalla.dart';
import 'package:agrocom_field/cliente/lotes/presentation/lotes_pantalla.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/perfil_proveedor_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/precio_final_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/estado_error_marketplace.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/estado_vacio_marketplace.dart';
import 'package:agrocom_field/nucleo/ui/tema_visual/tema_visual_cubit.dart';

import '../ui_negociacion_cliente/ayudas.dart';

Widget _conTema(Widget hijo) => BlocProvider(
  create: (_) => TemaVisualCubit(AlmacenTemaVisualMemoria()),
  child: hijo,
);

OfertaRecibida _oferta() => OfertaRecibida(
  id: 'of-1',
  solicitudId: '4101',
  numero: 1,
  autor: AutorOferta.proveedor,
  precioHa: Decimal.parse('64'),
  montoEstimado: Decimal.parse('7680'),
  estado: EstadoOferta.vigente,
  proveedor: ProveedorOfertante(
    id: 'p1',
    nombre: 'Marcelo Rojas',
    calificacion: 4.9,
    calificaciones: 64,
    tasaCancelacion: 0.02,
    marcaDron: 'DJI',
    modeloDron: 'Agras T50',
    anioDron: 2023,
    capacidadLitros: Decimal.parse('40'),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  void matriz(
    String nombre,
    Widget Function() pantalla, {
    void Function(AlmacenDemoCliente almacen)? preparar,
  }) {
    for (final v in Variante.matriz) {
      testWidgets('$nombre · ${v.sufijo}', skip: saltarGolden, (tester) async {
        final almacen = almacenDePrueba();
        preparar?.call(almacen);
        await montar(
          tester,
          pantalla: pantalla(),
          dependencias: dependenciasDePrueba(almacen),
          variante: v,
        );
        await asentar(tester);
        await esperarGolden(tester, '${nombre}_${v.sufijo}.png');
      });
    }
  }

  matriz(
    'perfil_cliente',
    () => _conTema(const Scaffold(body: CuentaPantalla())),
  );
  matriz('lotes', () => LotesPantalla(alPublicar: () {}));
  matriz('contactos', () => const ContactosPantalla());
  matriz(
    'perfil_publico_piloto',
    () => PerfilProveedorPantalla(
      oferta: _oferta(),
      nombreLote: 'El Tajibo Norte',
    ),
  );
  matriz(
    'precio_final_por_confirmar',
    () => const PrecioFinalPantalla(solicitudId: '4103'),
  );

  matriz(
    'chat_foto_y_sistema',
    () => const ChatPantalla(solicitudId: '4102', intervalo: null),
    preparar: (almacen) {
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
    },
  );

  matriz(
    'estado_vacio',
    () => Scaffold(
      body: EstadoVacioMarketplace(
        icono: Icons.handshake_outlined,
        titulo: 'Todavía no enviaste ofertas',
        detalle:
            'Hay 14 lotes abiertos a menos de 80 km. Las ofertas que envíes '
            'aparecen aquí con su ronda.',
        etiquetaAccion: 'Ver lotes en el mapa',
        alAccion: () {},
      ),
    ),
  );

  matriz(
    'estado_error_envio',
    () => Scaffold(
      body: EstadoErrorMarketplace(
        sinConexion: true,
        tablaSinRed: true,
        titulo: 'No se envió tu contraoferta',
        detalle:
            'Tu oferta de Bs 68/ha para El Tajibo Norte quedó guardada. Se '
            'envía sola cuando vuelva la señal, mientras siga abierta la '
            'ronda 4.',
        onReintentar: () {},
        etiquetaSecundaria: 'Volver a la negociación',
        onSecundaria: () {},
      ),
    ),
  );
}
