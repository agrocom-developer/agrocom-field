import 'package:agrocom_field/nucleo/notificaciones/data/bandeja_red.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/canal_aviso.dart';
import 'package:agrocom_field/nucleo/notificaciones/domain/preferencias_canales.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(int id, String tipo, {bool leida = false}) => {
  'id': id,
  'tipo': tipo,
  'titulo': 'Aviso $id',
  'recurso_tipo': 'solicitud',
  'recurso_id': 30 + id,
  'leida': leida,
  'creada_en': '2026-11-27T09:00:00+00:00',
};

void main() {
  group('CanalAviso.deTipo', () {
    test('cada tipo cae en su canal', () {
      expect(
        CanalAviso.deTipo('nueva_solicitud_abierta'),
        CanalAviso.nuevasSolicitudes,
      );
      expect(CanalAviso.deTipo('oferta_recibida'), CanalAviso.ofertas);
      expect(CanalAviso.deTipo('solicitud_adjudicada'), CanalAviso.ofertas);
      expect(CanalAviso.deTipo('mensaje_nuevo'), CanalAviso.mensajes);
      expect(CanalAviso.deTipo('avance_registrado'), CanalAviso.ejecucion);
      expect(CanalAviso.deTipo('sujeto_aprobado'), CanalAviso.cuenta);
    });

    test('un tipo desconocido no se pierde: cae en cuenta', () {
      expect(CanalAviso.deTipo('algo_nuevo_del_servidor'), CanalAviso.cuenta);
    });

    test(
      'solo las nuevas solicitudes son de proveedor y la cuenta no se apaga',
      () {
        expect(CanalAviso.nuevasSolicitudes.soloProveedor, isTrue);
        expect(CanalAviso.ofertas.soloProveedor, isFalse);
        expect(CanalAviso.cuenta.obligatorio, isTrue);
      },
    );
  });

  group('Bandeja', () {
    test('lee la lista del contrato y el contador de no leídas', () {
      final b = Bandeja.deJson({
        'data': [
          _json(1, 'mensaje_nuevo'),
          _json(2, 'sujeto_aprobado', leida: true),
        ],
        'no_leidas': 5,
      });
      expect(b.avisos, hasLength(2));
      expect(b.noLeidas, 5);
      expect(b.avisos.first.canal, CanalAviso.mensajes);
      expect(b.avisos.first.recursoId, 31);
    });

    test('ignora un aviso sin id o sin fecha', () {
      final b = Bandeja.deJson({
        'data': [
          {'tipo': 'x'},
          _json(3, 'oferta_recibida'),
        ],
      });
      expect(b.avisos.map((a) => a.id), [3]);
      expect(b.noLeidas, 1);
    });

    test('marcar como leída baja el contador una sola vez', () {
      final b = Bandeja.deJson({
        'data': [_json(1, 'mensaje_nuevo')],
        'no_leidas': 3,
      });
      final una = b.conLeida(1);
      expect(una.avisos.single.leida, isTrue);
      expect(una.noLeidas, 2);
      expect(una.conLeida(1).noLeidas, 2);
    });

    test('filtra por canal y cuenta sus no leídas', () {
      final b = Bandeja.deJson({
        'data': [
          _json(1, 'mensaje_nuevo'),
          _json(2, 'mensaje_nuevo', leida: true),
          _json(3, 'oferta_recibida'),
        ],
      });
      expect(b.delCanal(CanalAviso.mensajes), hasLength(2));
      expect(b.noLeidasDelCanal(CanalAviso.mensajes), 1);
      expect(b.delCanal(null), hasLength(3));
    });
  });

  group('BandejaRed', () {
    test('pide la bandeja y marca como leída por id', () async {
      final rutas = <String>[];
      final red = BandejaRed(
        obtener: (ruta) async {
          rutas.add('GET $ruta');
          return {'data': <Object>[], 'no_leidas': 0};
        },
        enviar: (ruta) async {
          rutas.add('POST $ruta');
          return <String, dynamic>{};
        },
      );
      await red.leer();
      await red.marcarLeida(71);
      expect(rutas, [
        'GET /api/notificaciones',
        'POST /api/notificaciones/71/leida',
      ]);
    });
  });

  group('PreferenciaCanal', () {
    test('el horario cruza la medianoche', () {
      const p = PreferenciaCanal(silencioDesde: 22 * 60, silencioHasta: 6 * 60);
      expect(p.enSilencio(DateTime(2026, 11, 27, 23, 30)), isTrue);
      expect(p.enSilencio(DateTime(2026, 11, 27, 5, 59)), isTrue);
      expect(p.enSilencio(DateTime(2026, 11, 27, 6)), isFalse);
      expect(p.enSilencio(DateTime(2026, 11, 27, 12)), isFalse);
    });

    test('el horario dentro del mismo día', () {
      const p = PreferenciaCanal(
        silencioDesde: 13 * 60,
        silencioHasta: 15 * 60,
      );
      expect(p.enSilencio(DateTime(2026, 11, 27, 14)), isTrue);
      expect(p.enSilencio(DateTime(2026, 11, 27, 15)), isFalse);
    });

    test('sin horario nunca hay silencio', () {
      expect(
        const PreferenciaCanal().enSilencio(DateTime(2026, 11, 27, 3)),
        isFalse,
      );
    });
  });

  group('PreferenciasCanales', () {
    final noche = DateTime(2026, 11, 27, 23);

    test('por defecto todo se presenta', () {
      const p = PreferenciasCanales();
      for (final c in CanalAviso.values) {
        expect(p.permite(c, noche), isTrue);
      }
    });

    test('un canal silenciado o en su horario no se presenta', () {
      final p = const PreferenciasCanales()
          .con(CanalAviso.mensajes, const PreferenciaCanal(activo: false))
          .con(
            CanalAviso.ofertas,
            const PreferenciaCanal(
              silencioDesde: 22 * 60,
              silencioHasta: 6 * 60,
            ),
          );
      expect(
        p.permite(CanalAviso.mensajes, DateTime(2026, 11, 27, 12)),
        isFalse,
      );
      expect(p.permite(CanalAviso.ofertas, noche), isFalse);
      expect(p.permite(CanalAviso.ofertas, DateTime(2026, 11, 27, 12)), isTrue);
      expect(p.permite(CanalAviso.ejecucion, noche), isTrue);
    });

    test('el canal obligatorio no se puede silenciar', () {
      final p = const PreferenciasCanales().con(
        CanalAviso.cuenta,
        const PreferenciaCanal(activo: false),
      );
      expect(p.permite(CanalAviso.cuenta, noche), isTrue);
    });

    test('ida y vuelta por JSON', () {
      final p = const PreferenciasCanales().con(
        CanalAviso.mensajes,
        const PreferenciaCanal(
          activo: false,
          silencioDesde: 60,
          silencioHasta: 120,
        ),
      );
      final otra = PreferenciasCanales.deJson(p.aJson());
      expect(otra.de(CanalAviso.mensajes), p.de(CanalAviso.mensajes));
      expect(otra.de(CanalAviso.ofertas), const PreferenciaCanal());
    });
  });
}
