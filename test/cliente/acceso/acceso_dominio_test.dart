import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/acceso/domain/reglas_acceso.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReglasAcceso', () {
    test('correo', () {
      expect(ReglasAcceso.correo(''), 'Escribe tu correo');
      expect(ReglasAcceso.correo('hugo@'), isNotNull);
      expect(ReglasAcceso.correo('hugo@finca'), isNotNull);
      expect(ReglasAcceso.correo(' hugo@finca.bo '), isNull);
    });

    test('contraseña nueva exige el largo mínimo', () {
      expect(ReglasAcceso.contrasenaNueva(''), 'Crea una contraseña');
      expect(ReglasAcceso.contrasenaNueva('1234567'), contains('8'));
      expect(ReglasAcceso.contrasenaNueva('12345678'), isNull);
    });

    test('al ingresar la contraseña solo no puede estar vacía', () {
      expect(ReglasAcceso.contrasena(''), isNotNull);
      expect(ReglasAcceso.contrasena('abc'), isNull);
    });

    test('nombre y teléfono', () {
      expect(ReglasAcceso.nombre('  '), isNotNull);
      expect(ReglasAcceso.nombre('Al'), isNotNull);
      expect(ReglasAcceso.nombre('Ana Roca'), isNull);
      expect(ReglasAcceso.telefono(''), isNotNull);
      expect(ReglasAcceso.telefono('771'), isNotNull);
      expect(ReglasAcceso.telefono('+591 7712 3456'), isNull);
    });
  });

  group('AccesoDemo', () {
    late AccesoDemo acceso;
    setUp(
      () => acceso = AccesoDemo(AlmacenDemoCliente(), latencia: Duration.zero),
    );

    test('arranca sin sesión y sin presentación vista', () async {
      expect(await acceso.sesionActual(), isNull);
      expect(await acceso.onboardingVisto(), isFalse);
      await acceso.marcarOnboardingVisto();
      expect(await acceso.onboardingVisto(), isTrue);
    });

    test('iniciar sesión deja la sesión y cerrarla la borra', () async {
      final sesion = await acceso.iniciarSesion(
        correo: ' Ana@Finca.bo ',
        contrasena: 'segura123',
      );
      expect(sesion.correo, 'ana@finca.bo');
      expect(await acceso.sesionActual(), sesion);
      await acceso.cerrarSesion();
      expect(await acceso.sesionActual(), isNull);
    });

    test('credenciales inválidas y sin conexión', () async {
      await expectLater(
        acceso.iniciarSesion(
          correo: 'ana@finca.bo',
          contrasena: AccesoDemo.contrasenaIncorrecta,
        ),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFalloAcceso.credencialesInvalidas,
          ),
        ),
      );
      await expectLater(
        acceso.iniciarSesion(
          correo: AccesoDemo.correoSinConexion,
          contrasena: 'segura123',
        ),
        throwsA(
          isA<AccesoExcepcion>().having(
            (e) => e.motivo,
            'motivo',
            MotivoFalloAcceso.sinConexion,
          ),
        ),
      );
      expect(await acceso.sesionActual(), isNull);
    });

    test(
      'registrar usa el nombre escrito y rechaza un correo ocupado',
      () async {
        await expectLater(
          acceso.registrar(
            const DatosRegistroCliente(
              nombre: 'Ana Roca',
              telefono: '77123456',
              correo: AccesoDemo.correoOcupado,
              contrasena: 'segura123',
            ),
          ),
          throwsA(
            isA<AccesoExcepcion>().having(
              (e) => e.porCampo.keys,
              'campos',
              contains(CampoAcceso.correo),
            ),
          ),
        );
        final sesion = await acceso.registrar(
          const DatosRegistroCliente(
            nombre: ' Ana Roca ',
            telefono: '77123456',
            correo: 'ana@finca.bo',
            contrasena: 'segura123',
          ),
        );
        expect(sesion.nombre, 'Ana Roca');
        expect(sesion.primerNombre, 'Ana');
      },
    );
  });
}
