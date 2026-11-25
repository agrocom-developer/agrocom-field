import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/acceso/presentation/arranque_cubit.dart';
import 'package:agrocom_field/cliente/acceso/presentation/formulario_acceso_estado.dart';
import 'package:agrocom_field/cliente/acceso/presentation/login_cliente_cubit.dart';
import 'package:agrocom_field/cliente/acceso/presentation/onboarding_cubit.dart';
import 'package:agrocom_field/cliente/acceso/presentation/registro_cliente_cubit.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles_cliente.dart';

AccesoDemo _demo({bool visto = false, bool sesion = false}) => AccesoDemo(
  AlmacenDemoCliente(),
  latencia: Duration.zero,
  onboardingVisto: visto,
  sesionIniciada: sesion,
);

void main() {
  group('ArranqueCubit', () {
    blocTest<ArranqueCubit, ArranqueEstado>(
      'primer uso lleva a la presentación',
      build: () => ArranqueCubit(_demo()),
      act: (c) => c.resolver(),
      expect: () => const [
        ArranqueEstado(EtapaArranque.resolviendo),
        ArranqueEstado(EtapaArranque.onboarding),
      ],
    );

    blocTest<ArranqueCubit, ArranqueEstado>(
      'presentación vista y sin sesión lleva al acceso',
      build: () => ArranqueCubit(_demo(visto: true)),
      act: (c) => c.resolver(),
      skip: 1,
      expect: () => const [ArranqueEstado(EtapaArranque.acceso)],
    );

    blocTest<ArranqueCubit, ArranqueEstado>(
      'con sesión guardada entra directo y al cerrar vuelve al acceso',
      build: () => ArranqueCubit(_demo(visto: true, sesion: true)),
      act: (c) async {
        await c.resolver();
        await c.cerrarSesion();
      },
      skip: 1,
      expect: () => const [
        ArranqueEstado(EtapaArranque.dentro, sesion: AccesoDemo.sesionBase),
        ArranqueEstado(EtapaArranque.acceso),
      ],
    );

    blocTest<ArranqueCubit, ArranqueEstado>(
      'un fallo al leer el estado guardado queda como error reintentable',
      build: () => ArranqueCubit(AccesoQueFalla()),
      act: (c) async {
        await c.resolver();
        await c.resolver();
      },
      expect: () => const [
        ArranqueEstado(EtapaArranque.resolviendo),
        ArranqueEstado(EtapaArranque.error),
        ArranqueEstado(EtapaArranque.resolviendo),
        ArranqueEstado(EtapaArranque.acceso),
      ],
    );
  });

  group('OnboardingCubit', () {
    late AccesoDemo acceso;
    setUp(() => acceso = _demo());

    blocTest<OnboardingCubit, OnboardingEstado>(
      'avanza tres pasos y al terminar anota que ya se vio',
      build: () => OnboardingCubit(acceso),
      act: (c) async {
        await c.siguiente();
        await c.siguiente();
        await c.siguiente();
        await c.siguiente();
      },
      expect: () => const [
        OnboardingEstado(paso: 1),
        OnboardingEstado(paso: 2),
        OnboardingEstado(paso: 2, terminado: true),
      ],
      verify: (_) async => expect(await acceso.onboardingVisto(), isTrue),
    );

    blocTest<OnboardingCubit, OnboardingEstado>(
      'saltar termina desde el primer paso; anterior no baja de cero',
      build: () => OnboardingCubit(acceso),
      act: (c) async {
        c.anterior();
        await c.terminar();
      },
      expect: () => const [OnboardingEstado(terminado: true)],
    );
  });

  group('LoginClienteCubit', () {
    blocTest<LoginClienteCubit, FormularioAccesoEstado>(
      'ingreso exitoso emite la sesión',
      build: () => LoginClienteCubit(_demo()),
      act: (c) => c.enviar(usuario: 'ana.finca', contrasena: 'segura123'),
      expect: () => [
        const FormularioAccesoEstado(enviando: true),
        isA<FormularioAccesoEstado>().having(
          (e) => e.sesion?.usuario,
          'usuario',
          'ana.finca',
        ),
      ],
    );

    blocTest<LoginClienteCubit, FormularioAccesoEstado>(
      'credenciales inválidas dejan un mensaje y se limpia al editar',
      build: () => LoginClienteCubit(_demo()),
      act: (c) async {
        await c.enviar(
          usuario: 'ana.finca',
          contrasena: AccesoDemo.contrasenaIncorrecta,
        );
        c.limpiarFallo();
      },
      skip: 1,
      expect: () => [
        isA<FormularioAccesoEstado>()
            .having(
              (e) => e.fallo,
              'fallo',
              MotivoFalloAcceso.credencialesInvalidas,
            )
            .having((e) => e.fallo, 'aviso general', isNotNull),
        const FormularioAccesoEstado(),
      ],
    );

    blocTest<LoginClienteCubit, FormularioAccesoEstado>(
      'sin conexión se distingue del resto de fallos',
      build: () => LoginClienteCubit(_demo()),
      act: (c) => c.enviar(
        usuario: AccesoDemo.usuarioSinConexion,
        contrasena: 'segura123',
      ),
      skip: 1,
      expect: () => [
        isA<FormularioAccesoEstado>().having(
          (e) => e.sinConexion,
          'sinConexion',
          isTrue,
        ),
      ],
    );
  });

  group('RegistroClienteCubit', () {
    const datos = DatosRegistroCliente(
      nombre: 'Ana Roca',
      telefono: '77123456',
      usuario: AccesoDemo.usuarioOcupado,
      contrasena: 'segura123',
    );

    blocTest<RegistroClienteCubit, FormularioAccesoEstado>(
      'el error por campo del servidor queda en su campo y se retira al '
      'editarlo',
      build: () => RegistroClienteCubit(_demo()),
      act: (c) async {
        await c.enviar(datos);
        c.campoEditado(CampoAcceso.nombre);
        c.campoEditado(CampoAcceso.usuario);
      },
      skip: 1,
      expect: () => [
        isA<FormularioAccesoEstado>()
            .having(
              (e) => e.porCampo[CampoAcceso.usuario],
              'usuario',
              isNotNull,
            )
            .having(
              (e) => e.fallo,
              'sin aviso general',
              anyOf(isNull, MotivoFalloAcceso.validacion),
            ),
        // Editar otro campo retira el motivo pero conserva el error.
        isA<FormularioAccesoEstado>().having(
          (e) => e.porCampo[CampoAcceso.usuario],
          'usuario',
          isNotNull,
        ),
        const FormularioAccesoEstado(),
      ],
    );
  });
}
