// «Eliminar mi cuenta» (ADR 0047): impedimentos, confirmación con contraseña,
// motivos nuevos tras un 409 y «Conservar mi cuenta» en la gracia.

import 'package:agrocom_field/nucleo/auth/cuenta/data/cuenta_seguridad_demo.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/domain/cuenta_seguridad.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/ajustes_seguridad_cubit.dart';
import 'package:agrocom_field/nucleo/auth/cuenta/presentation/eliminar_cuenta_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime.utc(2026, 11, 27, 12);

  test('sin impedimentos queda listo para pedir la eliminación', () async {
    final c = EliminarCuentaCubit(CuentaSeguridadDemo(ahora: () => ahora));
    await c.cargar();
    expect(c.state.etapa, EtapaEliminar.listo);
    expect(c.state.consulta!.bloqueada, isFalse);
    expect(c.state.consulta!.enGracia, isFalse);
    await c.close();
  });

  test('con impedimentos la consulta los lista', () async {
    final c = EliminarCuentaCubit(
      CuentaSeguridadDemo(
        impedimentos: const [ImpedimentoEliminacion.servicioEnCurso],
        ahora: () => ahora,
      ),
    );
    await c.cargar();
    expect(c.state.consulta!.bloqueada, isTrue);
    expect(c.state.consulta!.impedimentos, [
      ImpedimentoEliminacion.servicioEnCurso,
    ]);
    await c.close();
  });

  test('con la contraseña correcta queda solicitada con 7 días', () async {
    final c = EliminarCuentaCubit(
      CuentaSeguridadDemo(ahora: () => ahora)..contrasena = 'abcd',
    );
    await c.cargar();
    await c.eliminarConContrasena('abcd');
    expect(c.state.etapa, EtapaEliminar.solicitada);
    expect(c.state.eliminacion!.diasRestantes(ahora), 7);
    await c.close();
  });

  test('contraseña incorrecta vuelve a listo con la falla', () async {
    final c = EliminarCuentaCubit(CuentaSeguridadDemo(ahora: () => ahora));
    await c.cargar();
    await c.eliminarConContrasena('otra');
    expect(c.state.etapa, EtapaEliminar.listo);
    expect(c.state.falla, isA<CuentaContrasenaIncorrecta>());
    c.limpiarFalla();
    expect(c.state.falla, isNull);
    await c.close();
  });

  test(
    'un 409 al confirmar reemplaza los impedimentos por los nuevos',
    () async {
      final repo = _Bloqueado();
      final c = EliminarCuentaCubit(repo);
      await c.cargar();
      expect(c.state.consulta!.bloqueada, isFalse);
      await c.eliminarConContrasena('x');
      expect(c.state.falla, isA<CuentaEliminacionBloqueada>());
      expect(c.state.consulta!.impedimentos, [
        ImpedimentoEliminacion.reclamoAbierto,
      ]);
      await c.close();
    },
  );

  test('la confirmación por código registra la solicitud', () async {
    final c = EliminarCuentaCubit(CuentaSeguridadDemo(ahora: () => ahora));
    await c.cargar();
    c.registrarSolicitud(
      EliminacionCuenta(
        estado: EstadoEliminacion.solicitada,
        solicitadaEn: ahora,
        ejecutarDesde: ahora.add(const Duration(days: 7)),
      ),
    );
    expect(c.state.etapa, EtapaEliminar.solicitada);
    await c.close();
  });

  test('conservar la cuenta cancela la eliminación en gracia', () async {
    final repo = CuentaSeguridadDemo(ahora: () => ahora)..contrasena = 'abcd';
    await repo.eliminarCuenta(contrasena: 'abcd');
    final c = EliminarCuentaCubit(repo);
    await c.cargar();
    expect(c.state.consulta!.enGracia, isTrue);
    await c.conservar();
    expect(c.state.etapa, EtapaEliminar.conservada);
    expect((await repo.consultarEliminacion()).enGracia, isFalse);
    await c.close();
  });

  test('un fallo de red al cargar deja el error con su causa', () async {
    final c = EliminarCuentaCubit(_SinRed());
    await c.cargar();
    expect(c.state.etapa, EtapaEliminar.error);
    expect(c.state.falla, isA<CuentaSinConexion>());
    await c.close();
  });

  test(
    'con registros del lote sin subir no ofrece eliminar hasta sincronizar',
    () async {
      final lote = _Lote(3);
      final c = EliminarCuentaCubit(
        CuentaSeguridadDemo(ahora: () => ahora),
        pendientes: lote,
      );
      await c.cargar();
      expect(c.state.pendientesPorSubir, 3);
      await c.sincronizar();
      expect(lote.sincronizaciones, 1);
      expect(c.state.pendientesPorSubir, 0);
      expect(c.state.sincronizando, isFalse);
      await c.close();
    },
  );

  test('sin señal, sincronizar deja los pendientes como estaban', () async {
    final lote = _Lote(2, sinSenal: true);
    final c = EliminarCuentaCubit(CuentaSeguridadDemo(), pendientes: lote);
    await c.cargar();
    await c.sincronizar();
    expect(c.state.pendientesPorSubir, 2);
    await c.close();
  });

  test('el cliente no tiene lote: nunca hay pendientes', () async {
    final c = EliminarCuentaCubit(CuentaSeguridadDemo());
    await c.cargar();
    expect(c.state.pendientesPorSubir, 0);
    await c.sincronizar();
    expect(c.state.sincronizando, isFalse);
    await c.close();
  });

  test('ajustes de seguridad: lee si el teléfono está verificado', () async {
    final repo = CuentaSeguridadDemo();
    final c = AjustesSeguridadCubit(repo);
    await c.cargar();
    expect(
      (c.state as AjustesSeguridadListo).perfil.telefonoVerificado,
      isFalse,
    );
    await repo.confirmarTelefono(CuentaSeguridadDemo.codigoValido);
    await c.cargar();
    expect(
      (c.state as AjustesSeguridadListo).perfil.telefonoVerificado,
      isTrue,
    );
    await c.close();
  });

  test('ajustes de seguridad: sin red al abrir queda en error', () async {
    final c = AjustesSeguridadCubit(_SinRed());
    await c.cargar();
    expect(c.state, isA<AjustesSeguridadError>());
    await c.close();
  });
}

class _Bloqueado extends CuentaSeguridadDemo {
  @override
  Future<EliminacionCuenta> eliminarCuenta({
    String? contrasena,
    String? codigo,
  }) async => throw const CuentaEliminacionBloqueada([
    ImpedimentoEliminacion.reclamoAbierto,
  ]);
}

class _SinRed extends CuentaSeguridadDemo {
  @override
  Future<ConsultaEliminacion> consultarEliminacion() async =>
      throw const CuentaSinConexion();

  @override
  Future<PerfilSeguridad> perfil() async => throw const CuentaSinConexion();
}

class _Lote implements PendientesDeSincronizacion {
  _Lote(this.pendientes, {this.sinSenal = false});

  int pendientes;
  final bool sinSenal;
  int sincronizaciones = 0;

  @override
  Future<int> cantidad() async => pendientes;

  @override
  Future<void> sincronizar() async {
    sincronizaciones++;
    if (!sinSenal) pendientes = 0;
  }
}
