// La ejecución de un servicio adjudicado en el lote (ADR 0016): escribir es
// insertar local + encolar en una sola transacción, la UI lee de `drift`, y el
// motor de subida es idempotente por `uuid_cliente` (prueba de replay,
// invariante 9 de CLAUDE.md).

import 'dart:convert';
import 'dart:io';

import 'package:agrocom_field/nucleo/api/api_client.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/foto_ejecucion.dart';
import 'package:agrocom_field/nucleo/db/tablas/registro_ejecucion.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/data/ejecucion_local.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/data/ejecucion_sync_engine.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/domain/ejecucion.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../cliente/red/dobles_red.dart' show TokenEnMemoria;

/// Servidor del marketplace, idempotente por `uuid_cliente` como el real: el
/// mismo registro reenviado responde `200` con el mismo resultado y no
/// se aplica dos veces.
class _ServidorEjecucion implements HttpClientAdapter {
  final aplicados = <String, int>{};
  final orden = <String>[];
  final rechazar = <String>{};

  /// Con `true`, toda petición falla como si no hubiera red.
  bool sinRed = false;

  /// Con un código, toda petición responde ese error del servidor.
  int? errorServidor;

  /// Se ejecuta al recibir cada registro (para escribir mientras sube).
  Future<void> Function()? alRecibir;
  var catalogo = <Map<String, dynamic>>[];
  var montoFinal = '5900.00';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (sinRed) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    ResponseBody json(int codigo, Object cuerpo) => ResponseBody.fromString(
      jsonEncode(cuerpo),
      codigo,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
    if (errorServidor != null) {
      return json(errorServidor!, {'message': 'Error del servidor'});
    }
    final ruta = options.path;
    if (options.method == 'GET' && ruta == '/api/sync/catalogo') {
      return json(200, {
        'personas': [],
        'servicios_asignados': catalogo,
        'servicios_retirados': [],
        'limites': {},
        'cursor': 'x',
      });
    }
    if (options.method == 'GET' && ruta.endsWith('/avance')) {
      return json(200, {
        'avance': {'monto_final': montoFinal},
      });
    }
    // POST de registros y de fotos: se identifican por `uuid_cliente`.
    final datos = options.data;
    final uuid = datos is FormData
        ? datos.fields.firstWhere((f) => f.key == 'uuid_cliente').value
        : (datos as Map)['uuid_cliente'] as String;
    if (rechazar.contains(uuid)) {
      return json(422, {'message': 'Hectáreas fuera de rango.'});
    }
    final hook = alRecibir;
    if (hook != null) {
      alRecibir = null;
      await hook();
    }
    final yaEstaba = aplicados.containsKey(uuid);
    aplicados.update(uuid, (v) => v + 1, ifAbsent: () => 1);
    if (!yaEstaba) orden.add('${options.method} $ruta');
    return json(yaEstaba ? 200 : 201, {
      'registro': {'uuid_cliente': uuid},
    });
  }

  @override
  void close({bool force = false}) {}
}

class _CompresorFalso implements CompresorEvidencia {
  @override
  Future<Uint8List> comprimir(Uint8List bytes) async =>
      Uint8List.fromList(bytes.take(100).toList());
}

Map<String, dynamic> _servicioCatalogo({
  int id = 10,
  String estado = 'adjudicada',
  String? ejecutadas,
}) => {
  'id': id,
  'uuid_cliente': 'srv-$id',
  'estado': estado,
  'equipo_id': 1,
  'tipo_aplicacion': 'herbicida',
  'hectareas_solicitadas': '80.0000',
  'cultivo': 'Soya',
  'producto_indicado': 'Glifosato 480 SL, 2 L/ha',
  'aporta_producto': 'cliente',
  'ventana_desde': '2026-12-01',
  'ventana_hasta': '2026-12-10',
  'urgente': false,
  'observaciones': null,
  'terreno': {
    'nombre': 'Lote Norte',
    'hectareas': '80.0000',
    'geometria': {
      'type': 'Polygon',
      'coordinates': [
        [
          [-63.2018, -17.5391],
          [-63.1918, -17.5391],
          [-63.1918, -17.5291],
          [-63.2018, -17.5291],
          [-63.2018, -17.5391],
        ],
      ],
    },
    'referencias_acceso': 'Camino vecinal',
    'colindantes_sensibles': null,
    'acceso_dificil': false,
  },
  'precio_ha_propuesto': '125.0000',
  'precio_ha_acordado': '118.0000',
  'hectareas_ejecutadas': ejecutadas,
  'porcentaje_avance': null,
  'contacto': {'nombre': 'Agro San Rafael', 'telefono': '+591 76543210'},
  'updated_at': '2026-12-01T12:00:00+00:00',
};

void main() {
  late AppDatabase db;
  late _ServidorEjecucion servidor;
  late ApiClient api;
  late EjecucionSyncEngine motor;
  late EjecucionLocal repo;
  late Directory dir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    servidor = _ServidorEjecucion();
    api = ApiClient(
      baseUrl: 'http://api.prueba',
      tokenStore: TokenEnMemoria('tok'),
      dio: Dio(BaseOptions(baseUrl: 'http://api.prueba'))
        ..httpClientAdapter = servidor,
    );
    motor = EjecucionSyncEngine(api: api, db: db);
    dir = Directory.systemTemp.createTempSync('fotos_ejecucion');
    repo = EjecucionLocal(
      db,
      compresor: _CompresorFalso(),
      directorioFotos: dir,
    );
    servidor.catalogo = [_servicioCatalogo()];
    await motor.bajarCatalogo();
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<ServicioEnLote> leer() async => (await repo.observarUno(10).first)!;

  group('catálogo', () {
    test('baja el servicio adjudicado con sus datos y contacto', () async {
      final s = await leer();
      expect(s.estado, EstadoServicioLote.adjudicada);
      expect(s.hectareas, Decimal.parse('80'));
      expect(s.precioHaAcordado, Decimal.parse('118'));
      expect(s.contactoNombre, 'Agro San Rafael');
      expect(s.terreno!.poligono, hasLength(4));
      expect(s.pendientes, 0);
    });

    test(
      'un servicio que el servidor ya no entrega se oculta, no se borra',
      () async {
        servidor.catalogo = [];
        await motor.bajarCatalogo();
        expect(await repo.observar().first, isEmpty);
        expect(await db.select(db.servicioAdjudicado).get(), hasLength(1));
      },
    );

    test('un pull no pisa lo que se hizo sin señal', () async {
      await repo.iniciar(10);
      // El servidor todavía lo ve `adjudicada`.
      await motor.bajarCatalogo();
      expect((await leer()).estado, EstadoServicioLote.enEjecucion);
    });
  });

  group('escribir = insertar local + encolar, en una transacción', () {
    test('iniciar cambia el espejo y encola un solo registro', () async {
      await repo.iniciar(10);
      final s = await leer();
      expect(s.estado, EstadoServicioLote.enEjecucion);
      expect(s.registrosPendientes, 1);
      final cola = await db.select(db.registroEjecucion).get();
      expect(cola.single.tipo, 'inicio');
      expect(cola.single.secuencia, 1);
      expect(cola.single.uuidCliente, isNotEmpty);
    });

    test('iniciar dos veces no encola dos registros', () async {
      await repo.iniciar(10);
      await repo.iniciar(10);
      expect(await db.select(db.registroEjecucion).get(), hasLength(1));
    });

    test('la secuencia crece y no depende del reloj', () async {
      await repo.iniciar(10);
      await repo.marcarAvance(10, hectareas: Decimal.parse('20'));
      await repo.marcarAvance(10, porcentaje: Decimal.parse('50'));
      final cola = await (db.select(
        db.registroEjecucion,
      )..orderBy([(t) => OrderingTerm.asc(t.secuencia)])).get();
      expect(cola.map((r) => r.secuencia), [1, 2, 3]);
      expect(cola.map((r) => r.tipo), ['inicio', 'avance', 'avance']);
    });

    test(
      'el avance en hectáreas deriva el porcentaje en decimal exacto',
      () async {
        await repo.iniciar(10);
        await repo.marcarAvance(10, hectareas: Decimal.parse('20'));
        final s = await leer();
        expect(s.hectareasEjecutadas, Decimal.parse('20'));
        expect(s.porcentaje, Decimal.parse('25'));
      },
    );

    test('el avance en porcentaje deriva las hectáreas', () async {
      await repo.iniciar(10);
      await repo.marcarAvance(10, porcentaje: Decimal.parse('50'));
      expect((await leer()).hectareasEjecutadas, Decimal.parse('40'));
    });

    test('no se marca avance antes de empezar', () async {
      await repo.marcarAvance(10, hectareas: Decimal.parse('20'));
      expect(await db.select(db.registroEjecucion).get(), isEmpty);
    });

    test(
      'una foto se comprime, se guarda y se encola en su propia cola',
      () async {
        await repo.iniciar(10);
        await repo.marcarAvance(10, hectareas: Decimal.parse('20'));
        final uuid = await repo.adjuntarFoto(
          10,
          Uint8List.fromList(List.filled(1000, 7)),
        );
        final fotos = await db.select(db.fotoEjecucion).get();
        expect(fotos.single.uuidCliente, uuid);
        expect(File(fotos.single.rutaArchivoLocal).lengthSync(), 100);
        // Cuelga del último avance marcado.
        final avance = await (db.select(
          db.registroEjecucion,
        )..where((t) => t.tipo.equals('avance'))).getSingle();
        expect(fotos.single.avanceUuidCliente, avance.uuidCliente);
        // Y no se mezcla con los registros livianos (invariante 7).
        expect(await db.select(db.registroEjecucion).get(), hasLength(2));
        expect((await leer()).fotosPendientes, 1);
      },
    );

    test(
      'finalizar deja el servicio finalizado y el precio estimado',
      () async {
        await repo.iniciar(10);
        await repo.finalizar(10, hectareasEjecutadas: Decimal.parse('50'));
        final s = await leer();
        expect(s.estado, EstadoServicioLote.finalizada);
        expect(s.montoAPagar, Decimal.parse('5900'));
        expect(s.montoConfirmado, isFalse);
      },
    );
  });

  group('subida idempotente', () {
    Future<void> escribirTodo() async {
      await repo.iniciar(10);
      await repo.marcarAvance(10, hectareas: Decimal.parse('30'));
      await repo.adjuntarFoto(10, Uint8List.fromList(List.filled(500, 1)));
      await repo.finalizar(10, hectareasEjecutadas: Decimal.parse('50'));
    }

    test('sube en orden de secuencia, luego las fotos', () async {
      await escribirTodo();
      await motor.sincronizar();
      expect(servidor.orden, [
        'POST /api/solicitudes/10/inicio',
        'POST /api/solicitudes/10/avance',
        'POST /api/solicitudes/10/cierre',
        'POST /api/solicitudes/10/evidencias',
      ]);
      final s = await leer();
      expect(s.pendientes, 0);
      expect(s.rechazos, 0);
    });

    test(
      'lo escrito mientras sube sale en el ciclo siguiente, sin esperar otro '
      'disparador',
      () async {
        await repo.iniciar(10);
        servidor.alRecibir = () async {
          await repo.marcarAvance(10, hectareas: Decimal.parse('30'));
          // El disparador de esa escritura llega con un ciclo en curso.
          await motor.sincronizar();
        };
        await motor.sincronizar();
        expect(servidor.orden, [
          'POST /api/solicitudes/10/inicio',
          'POST /api/solicitudes/10/avance',
        ]);
        expect((await leer()).pendientes, 0);
      },
    );

    test('sin red todo queda pendiente y nada se pierde', () async {
      await escribirTodo();
      servidor.sinRed = true;
      await motor.sincronizar();
      expect((await leer()).pendientes, 4);
      expect(servidor.orden, isEmpty);
      servidor.sinRed = false;
      await motor.sincronizar();
      expect((await leer()).pendientes, 0);
    });

    test(
      'un error del servidor detiene el ciclo sin romper el orden',
      () async {
        await escribirTodo();
        servidor.errorServidor = 503;
        await motor.sincronizar();
        expect((await leer()).pendientes, 4);
        servidor.errorServidor = null;
        await motor.sincronizar();
        expect(servidor.orden.first, 'POST /api/solicitudes/10/inicio');
      },
    );

    test(
      'REPLAY: reenviar el mismo lote 1, 3 y 10 veces deja la base idéntica',
      () async {
        await escribirTodo();
        await motor.sincronizar();
        Future<List<String>> instantanea() async {
          final r = await db.select(db.registroEjecucion).get();
          final f = await db.select(db.fotoEjecucion).get();
          final s = await db.select(db.servicioAdjudicado).get();
          return [
            for (final x in r)
              '${x.uuidCliente}|${x.secuencia}|${x.estado.name}|${x.motivoRechazo}',
            for (final x in f) '${x.uuidCliente}|${x.estado.name}',
            for (final x in s)
              '${x.id}|${x.estado}|${x.hectareasEjecutadas}|${x.porcentajeAvance}',
          ]..sort();
        }

        final base = await instantanea();
        for (var i = 0; i < 10; i++) {
          await motor.sincronizar();
        }
        expect(await instantanea(), base);

        // Aunque la respuesta se haya perdido: las filas vuelven a `pendiente`
        // y el servidor, idempotente, responde 200 con lo ya aplicado.
        await db
            .update(db.registroEjecucion)
            .write(
              const RegistroEjecucionCompanion(
                estado: Value(EstadoRegistroEjecucion.pendiente),
              ),
            );
        await db
            .update(db.fotoEjecucion)
            .write(
              const FotoEjecucionCompanion(
                estado: Value(EstadoFotoEjecucion.pendiente),
              ),
            );
        await motor.sincronizar();
        await motor.sincronizar();
        expect(await instantanea(), base);
        // El servidor aplicó cada registro una sola vez.
        expect(servidor.orden.length, 4);
      },
    );

    test(
      'un rechazo definitivo marca esa fila y sigue con las demás',
      () async {
        await repo.iniciar(10);
        await repo.marcarAvance(10, hectareas: Decimal.parse('30'));
        await repo.finalizar(10, hectareasEjecutadas: Decimal.parse('50'));
        final avance = await (db.select(
          db.registroEjecucion,
        )..where((t) => t.tipo.equals('avance'))).getSingle();
        servidor.rechazar.add(avance.uuidCliente);
        await motor.sincronizar();
        final filas = await db.select(db.registroEjecucion).get();
        final r = filas.firstWhere((f) => f.tipo == 'avance');
        expect(r.estado, EstadoRegistroEjecucion.rechazado);
        expect(r.motivoRechazo, contains('fuera de rango'));
        expect(
          filas
              .where((f) => f.tipo != 'avance')
              .every((f) => f.estado == EstadoRegistroEjecucion.confirmado),
          isTrue,
        );
        expect((await leer()).rechazos, 1);
      },
    );

    test('al finalizar baja el monto final que calcula el servidor', () async {
      await repo.iniciar(10);
      await repo.finalizar(10, hectareasEjecutadas: Decimal.parse('50'));
      await motor.sincronizar();
      final s = await leer();
      expect(s.montoFinal, Decimal.parse('5900'));
      expect(s.montoConfirmado, isTrue);
      // Sigue visible aunque el catálogo ya no lo entregue.
      expect(await repo.observar().first, hasLength(1));
    });
  });

  group('cerrar sesión', () {
    test('descarta lo confirmado y conserva lo pendiente de subir', () async {
      await repo.iniciar(10);
      await repo.marcarAvance(10, hectareas: Decimal.parse('30'));
      await repo.limpiarAlCerrarSesion();
      // Hay registros sin subir: el servicio y su trabajo se conservan.
      expect(await db.select(db.servicioAdjudicado).get(), hasLength(1));
      expect(await db.select(db.registroEjecucion).get(), hasLength(2));

      await motor.sincronizar();
      await repo.limpiarAlCerrarSesion();
      // Todo confirmado: no queda nada del usuario anterior.
      expect(await db.select(db.servicioAdjudicado).get(), isEmpty);
      expect(await db.select(db.registroEjecucion).get(), isEmpty);
    });
  });
}
