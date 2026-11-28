import 'dart:async';

import 'package:agrocom_field/nucleo/notificaciones/domain/aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/canal_aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/preferencias_canales.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/presentador_avisos.dart';
import 'package:agrocom_field/nucleo/notificaciones/notificador_local.dart';
import 'package:agrocom_field/nucleo/notificaciones/remotas/notificaciones_remotas.dart';
import 'package:flutter_test/flutter_test.dart';

class _Notificador implements NotificadorLocal {
  final mostradas =
      <
        ({
          int id,
          String titulo,
          String cuerpo,
          CanalAviso canal,
          String? carga,
        })
      >[];

  @override
  Future<bool> pedirPermiso() async => true;

  @override
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    CanalAviso canal = CanalAviso.cuenta,
    String? carga,
  }) async => mostradas.add((
    id: id,
    titulo: titulo,
    cuerpo: cuerpo,
    canal: canal,
    carga: carga,
  ));
}

Aviso _aviso(int id, String tipo, {bool leida = false}) => Aviso(
  id: id,
  tipo: tipo,
  titulo: 'Texto $id',
  recursoTipo: 'solicitud',
  recursoId: 40 + id,
  leida: leida,
  creadaEn: DateTime(2026, 11, 27, 9),
);

Bandeja _bandeja(List<Aviso> avisos) =>
    Bandeja(avisos: avisos, noLeidas: avisos.where((a) => !a.leida).length);

class _RemotasConAvisos implements NotificacionesRemotas {
  final controlador = StreamController<AvisoRemoto>();

  @override
  Future<EstadoPushRemoto> estado() async => EstadoPushRemoto.activo;

  @override
  Future<String?> obtenerToken() async => 'token';

  @override
  Stream<AvisoRemoto> get avisos => controlador.stream;
}

void main() {
  late _Notificador notificador;
  late PreferenciasCanalesMemoria prefs;
  late AvisosPresentadosMemoria presentados;
  var ahora = DateTime(2026, 11, 27, 12);

  PresentadorAvisos crear({int maximo = 3}) => PresentadorAvisos(
    notificador: notificador,
    preferencias: prefs,
    presentados: presentados,
    reloj: () => ahora,
    maximoPorRevision: maximo,
  );

  setUp(() {
    notificador = _Notificador();
    prefs = PreferenciasCanalesMemoria();
    presentados = AvisosPresentadosMemoria();
    ahora = DateTime(2026, 11, 27, 12);
  });

  test('la primera lectura solo registra lo que ya hay', () async {
    final p = crear();
    final n = await p.presentar(_bandeja([_aviso(1, 'mensaje_nuevo')]));
    expect(n, 0);
    expect(notificador.mostradas, isEmpty);
  });

  test('presenta lo nuevo sin leer, en su canal y con su carga', () async {
    final p = crear();
    await p.presentar(_bandeja([_aviso(1, 'mensaje_nuevo')]));
    final n = await p.presentar(
      _bandeja([
        _aviso(2, 'oferta_recibida'),
        _aviso(1, 'mensaje_nuevo'),
        _aviso(3, 'sujeto_aprobado', leida: true),
      ]),
    );
    expect(n, 1);
    final m = notificador.mostradas.single;
    expect(m.id, 2);
    expect(m.canal, CanalAviso.ofertas);
    expect(m.cuerpo, 'Texto 2');
    expect(m.carga, 'solicitud:42');
  });

  test('no repite un aviso ya presentado', () async {
    final p = crear();
    await p.presentar(_bandeja([]));
    final b = _bandeja([_aviso(5, 'mensaje_nuevo')]);
    await p.presentar(b);
    await p.presentar(b);
    expect(notificador.mostradas, hasLength(1));
  });

  test('respeta el canal silenciado y el horario de silencio', () async {
    await prefs.guardar(
      const PreferenciasCanales()
          .con(CanalAviso.mensajes, const PreferenciaCanal(activo: false))
          .con(
            CanalAviso.ofertas,
            const PreferenciaCanal(
              silencioDesde: 11 * 60,
              silencioHasta: 13 * 60,
            ),
          ),
    );
    final p = crear();
    await p.presentar(_bandeja([]));
    await p.presentar(
      _bandeja([
        _aviso(1, 'mensaje_nuevo'),
        _aviso(2, 'oferta_recibida'),
        _aviso(3, 'avance_registrado'),
      ]),
    );
    expect(notificador.mostradas.map((m) => m.canal), [CanalAviso.ejecucion]);
  });

  test('muchos avisos a la vez salen en una sola notificación', () async {
    final p = crear(maximo: 2);
    await p.presentar(_bandeja([]));
    final n = await p.presentar(
      _bandeja([
        _aviso(1, 'mensaje_nuevo'),
        _aviso(2, 'mensaje_nuevo'),
        _aviso(3, 'mensaje_nuevo'),
      ]),
    );
    expect(n, 3);
    expect(notificador.mostradas, hasLength(1));
    expect(notificador.mostradas.single.cuerpo, '3 notificaciones nuevas');
  });

  test('con el puerto de push nulo no pasa nada', () async {
    final p = crear();
    final sub = p.escuchar(const NotificacionesRemotasNulas());
    await Future<void>.delayed(Duration.zero);
    expect(notificador.mostradas, isEmpty);
    await sub.cancel();
  });

  test('un aviso remoto se presenta si su canal lo permite', () async {
    final remotas = _RemotasConAvisos();
    final p = crear();
    final sub = p.escuchar(remotas);
    remotas.controlador.add(
      const AvisoRemoto(
        titulo: 'Oferta',
        cuerpo: 'Te ofrecieron',
        solicitudId: 9,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(notificador.mostradas.single.carga, 'solicitud:9');
    await sub.cancel();
    await remotas.controlador.close();
  });
}
