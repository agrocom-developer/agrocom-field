import 'package:agrocom_field/nucleo/permisos/domain/permiso.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> pasos;

  Future<bool> explicar(PermisoApp p) async {
    pasos.add('explicar:${p.name}');
    return respuestaExplicar;
  }

  Future<bool> avisar(PermisoApp p, {required bool ajustes}) async {
    pasos.add('denegado:${p.name}:ajustes=$ajustes');
    return respuestaAjustes;
  }

  setUp(() {
    pasos = [];
    respuestaExplicar = true;
    respuestaAjustes = true;
  });

  Future<ResultadoPermiso> correr(
    GestorPermisosEnMemoria gestor,
    PermisoApp permiso,
  ) => FlujoPermiso(
    gestor,
  ).ejecutar(permiso, explicar: explicar, avisarDenegado: avisar);

  test('ya concedido: no explica ni pregunta', () async {
    final gestor = GestorPermisosEnMemoria(
      estados: {PermisoApp.ubicacion: EstadoPermiso.concedido},
    );
    expect(
      await correr(gestor, PermisoApp.ubicacion),
      ResultadoPermiso.concedido,
    );
    expect(pasos, isEmpty);
    expect(gestor.pedidos, isEmpty);
  });

  test('sin preguntar: primero explica y después pide al sistema', () async {
    final gestor = GestorPermisosEnMemoria();
    expect(
      await correr(gestor, PermisoApp.notificaciones),
      ResultadoPermiso.concedido,
    );
    expect(pasos, ['explicar:notificaciones']);
    expect(gestor.pedidos, [PermisoApp.notificaciones]);
  });

  test('«Ahora no»: no se pregunta al sistema', () async {
    respuestaExplicar = false;
    final gestor = GestorPermisosEnMemoria();
    expect(await correr(gestor, PermisoApp.camara), ResultadoPermiso.pospuesto);
    expect(gestor.pedidos, isEmpty);
  });

  test('el sistema dice no, pero se puede reintentar', () async {
    final gestor = GestorPermisosEnMemoria(
      respuestas: {PermisoApp.ubicacion: EstadoPermiso.denegado},
    );
    expect(
      await correr(gestor, PermisoApp.ubicacion),
      ResultadoPermiso.denegado,
    );
    expect(pasos, ['explicar:ubicacion', 'denegado:ubicacion:ajustes=false']);
    expect(gestor.ajustesAbiertos, isEmpty);
  });

  test(
    'denegado para siempre: avisa y abre ajustes si la persona quiere',
    () async {
      final gestor = GestorPermisosEnMemoria(
        estados: {PermisoApp.camara: EstadoPermiso.denegadoParaSiempre},
      );
      expect(
        await correr(gestor, PermisoApp.camara),
        ResultadoPermiso.denegadoParaSiempre,
      );
      expect(pasos, ['denegado:camara:ajustes=true']);
      expect(gestor.ajustesAbiertos, [PermisoApp.camara]);
      expect(gestor.pedidos, isEmpty);
    },
  );

  test('denegado para siempre y la persona cierra: no abre ajustes', () async {
    respuestaAjustes = false;
    final gestor = GestorPermisosEnMemoria(
      estados: {PermisoApp.camara: EstadoPermiso.denegadoParaSiempre},
    );
    await correr(gestor, PermisoApp.camara);
    expect(gestor.ajustesAbiertos, isEmpty);
  });

  test('el sistema niega para siempre al pedir: guía a ajustes', () async {
    final gestor = GestorPermisosEnMemoria(
      respuestas: {
        PermisoApp.notificaciones: EstadoPermiso.denegadoParaSiempre,
      },
    );
    expect(
      await correr(gestor, PermisoApp.notificaciones),
      ResultadoPermiso.denegadoParaSiempre,
    );
    expect(gestor.ajustesAbiertos, [PermisoApp.notificaciones]);
  });

  test('servicio apagado se trata como salida a ajustes', () async {
    final gestor = GestorPermisosEnMemoria(
      estados: {PermisoApp.ubicacion: EstadoPermiso.servicioApagado},
    );
    expect(
      await correr(gestor, PermisoApp.ubicacion),
      ResultadoPermiso.denegadoParaSiempre,
    );
  });

  test('la captura que revela un rechazo de cámara lo recuerda', () async {
    final gestor = GestorPermisosEnMemoria();
    gestor.registrarDenegadoParaSiempre(PermisoApp.camara);
    expect(
      await gestor.estado(PermisoApp.camara),
      EstadoPermiso.denegadoParaSiempre,
    );
  });
}

bool respuestaExplicar = true;
bool respuestaAjustes = true;
