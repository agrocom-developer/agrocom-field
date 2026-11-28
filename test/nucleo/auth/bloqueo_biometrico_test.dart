import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/presentation/arranque_cubit.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/auth/biometria.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico.dart';
import 'package:agrocom_field/nucleo/auth/bloqueo_biometrico_store.dart';
import 'package:agrocom_field/nucleo/auth/presentation/bloqueo_biometrico_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BiometriaFalsa biometria;
  late BloqueoBiometricoStoreEnMemoria store;
  late BloqueoBiometrico bloqueo;

  setUp(() {
    biometria = BiometriaFalsa();
    store = BloqueoBiometricoStoreEnMemoria();
    bloqueo = BloqueoBiometrico(biometria, store);
  });

  group('BloqueoBiometrico', () {
    test('desactivado: no pregunta nada', () async {
      expect(
        await bloqueo.desbloquear(motivo: 'x'),
        ResultadoDesbloqueo.noAplica,
      );
      expect(biometria.intentos, 0);
    });

    test('activar exige reconocer a la persona en ese momento', () async {
      biometria.resultado = ResultadoBiometria.cancelado;
      expect(await bloqueo.activar(motivo: 'x'), isFalse);
      expect(await bloqueo.activo(), isFalse);

      biometria.resultado = ResultadoBiometria.exito;
      expect(await bloqueo.activar(motivo: 'x'), isTrue);
      expect(await bloqueo.activo(), isTrue);
    });

    test('sin biometría registrada no se puede activar', () async {
      biometria.estado = DisponibilidadBiometria.sinRegistrar;
      expect(await bloqueo.activar(motivo: 'x'), isFalse);
      expect(biometria.intentos, 0);
    });

    test('activo y reconocida: desbloquea', () async {
      await store.guardar(true);
      expect(
        await bloqueo.desbloquear(motivo: 'x'),
        ResultadoDesbloqueo.desbloqueado,
      );
    });

    test(
      'activo y cancelada: sigue bloqueado y conserva la preferencia',
      () async {
        await store.guardar(true);
        biometria.resultado = ResultadoBiometria.cancelado;
        expect(
          await bloqueo.desbloquear(motivo: 'x'),
          ResultadoDesbloqueo.cancelado,
        );
        expect(await bloqueo.activo(), isTrue);
      },
    );

    test(
      'quitaron la biometría del teléfono: cae a contraseña y se apaga',
      () async {
        await store.guardar(true);
        biometria.estado = DisponibilidadBiometria.sinRegistrar;
        expect(
          await bloqueo.desbloquear(motivo: 'x'),
          ResultadoDesbloqueo.usarContrasena,
        );
        expect(await bloqueo.activo(), isFalse);
      },
    );

    test('olvidar (cerrar sesión) borra la preferencia', () async {
      await store.guardar(true);
      await bloqueo.olvidar();
      expect(await bloqueo.activo(), isFalse);
    });
  });

  group('BloqueoBiometricoCubit', () {
    BloqueoBiometricoCubit crear() =>
        BloqueoBiometricoCubit(bloqueo, motivoActivacion: 'x');

    test('carga listo y apagado', () async {
      final c = crear();
      await c.cargar();
      expect(c.state.etapa, EtapaBloqueoAjuste.listo);
      expect(c.state.activo, isFalse);
    });

    test('sin hardware no deja activar', () async {
      biometria.estado = DisponibilidadBiometria.sinHardware;
      final c = crear();
      await c.cargar();
      await c.cambiar(true);
      expect(c.state.etapa, EtapaBloqueoAjuste.sinHardware);
      expect(c.state.activo, isFalse);
    });

    test('activar y desactivar', () async {
      final c = crear();
      await c.cargar();
      await c.cambiar(true);
      expect(c.state.activo, isTrue);
      await c.cambiar(false);
      expect(c.state.activo, isFalse);
      expect(await bloqueo.activo(), isFalse);
    });

    test('si no se confirma, queda apagado y lo dice', () async {
      biometria.resultado = ResultadoBiometria.cancelado;
      final c = crear();
      await c.cargar();
      await c.cambiar(true);
      expect(c.state.activo, isFalse);
      expect(c.state.noConfirmado, isTrue);
    });
  });

  group('ArranqueCubit con bloqueo', () {
    ArranqueCubit arranque() => ArranqueCubit(
      AccesoDemo(
        AlmacenDemoCliente(),
        latencia: Duration.zero,
        onboardingVisto: true,
        sesionIniciada: true,
      ),
      bloqueo: bloqueo,
      l10n: AppLocalizationsEs(),
    );

    test('activo y reconocida: entra con la sesión', () async {
      await store.guardar(true);
      final c = arranque();
      await c.resolver();
      expect(c.state.etapa, EtapaArranque.dentro);
    });

    test('activo y cancelada: se queda bloqueada sin leer la sesión', () async {
      await store.guardar(true);
      biometria.resultado = ResultadoBiometria.cancelado;
      final c = arranque();
      await c.resolver();
      expect(c.state.etapa, EtapaArranque.bloqueada);
      expect(c.state.sesion, isNull);

      biometria.resultado = ResultadoBiometria.exito;
      await c.desbloquear();
      expect(c.state.etapa, EtapaArranque.dentro);
    });

    test(
      '«entrar con mi contraseña» cierra la sesión y borra la preferencia',
      () async {
        await store.guardar(true);
        biometria.resultado = ResultadoBiometria.cancelado;
        final c = arranque();
        await c.resolver();
        await c.usarContrasena();
        expect(c.state.etapa, EtapaArranque.acceso);
        expect(await bloqueo.activo(), isFalse);
      },
    );
  });
}
