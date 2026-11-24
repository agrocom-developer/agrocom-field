import 'package:agrocom_field/cliente/acceso/data/acceso_demo.dart';
import 'package:agrocom_field/cliente/acceso/domain/acceso_repositorio.dart';
import 'package:agrocom_field/cliente/acceso/domain/reglas_acceso.dart';
import 'package:agrocom_field/cliente/demo/almacen_demo_cliente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReglasAcceso', () {
    test('usuario', () {
      expect(ReglasAcceso.usuario(''), 'Escribe tu usuario');
      expect(
        ReglasAcceso.usuario('hugo@finca.bo'),
        contains('no es un correo'),
      );
      expect(ReglasAcceso.usuario('ab'), isNotNull);
      expect(ReglasAcceso.usuario('hugo finca'), isNotNull);
      expect(ReglasAcceso.usuario(' hugo.finca '), isNull);
      expect(ReglasAcceso.usuario('agro-san_rafael'), isNull);
    });

    test('contraseña nueva exige el largo mínimo', () {
      expect(ReglasAcceso.contrasenaNueva(''), 'Crea una contraseña');
      expect(ReglasAcceso.contrasenaNueva('1234567'), contains('8'));
      expect(
        ReglasAcceso.contrasenaNueva('12345678'),
        'Combina letras y números',
      );
      expect(
        ReglasAcceso.contrasenaNueva('abcdefgh'),
        'Combina letras y números',
      );
      expect(ReglasAcceso.contrasenaNueva('abcd1234'), isNull);
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
        usuario: 'Ana.Finca',
        contrasena: 'segura123',
      );
      expect(sesion.usuario, 'ana.finca');
      expect(await acceso.sesionActual(), sesion);
      await acceso.cerrarSesion();
      expect(await acceso.sesionActual(), isNull);
    });

    test('credenciales inválidas y sin conexión', () async {
      await expectLater(
        acceso.iniciarSesion(
          usuario: 'ana.finca',
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
          usuario: AccesoDemo.usuarioSinConexion,
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
      'registrar usa el nombre escrito y rechaza un usuario ocupado',
      () async {
        await expectLater(
          acceso.registrar(
            const DatosRegistroCliente(
              nombre: 'Ana Roca',
              telefono: '77123456',
              usuario: AccesoDemo.usuarioOcupado,
              contrasena: 'segura123',
            ),
          ),
          throwsA(
            isA<AccesoExcepcion>().having(
              (e) => e.porCampo.keys,
              'campos',
              contains(CampoAcceso.usuario),
            ),
          ),
        );
        final sesion = await acceso.registrar(
          const DatosRegistroCliente(
            nombre: ' Ana Roca ',
            telefono: '77123456',
            usuario: 'ana.finca',
            contrasena: 'segura123',
          ),
        );
        expect(sesion.nombre, 'Ana Roca');
        expect(sesion.primerNombre, 'Ana');
      },
    );
  });
}
