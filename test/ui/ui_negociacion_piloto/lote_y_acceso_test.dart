// Servicio adjudicado en el lote (offline-first), ingreso y registro del
// piloto, en modo campo: comportamiento, estados, texto al 200 % y goldens.

import 'dart:typed_data';

import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:agrocom_field/nucleo/camara/selector_imagen.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/domain/acceso_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/acceso_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/acceso_pantallas.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/registro_proveedor_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/data/ejecucion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/presentation/servicio_lote_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ejecucion/presentation/servicios_lote_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

class _Camara implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async => Uint8List.fromList([1, 2, 3]);
}

class _AccesoFalso implements AccesoProveedorRepositorio {
  @override
  Future<SesionProveedor?> sesionActual() async => null;

  @override
  Future<SesionProveedor> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async => throw const AccesoProveedorExcepcion(
    MotivoFalloAcceso.credencialesInvalidas,
  );

  @override
  Future<void> registrar(DatosPersona datos) async {}

  @override
  Future<void> cerrarSesion() async {}
}

class _DronesFalso implements RegistroDronesRepositorio {
  @override
  Future<int> registrarDron(DatosDron datos) async => 1;

  @override
  Future<void> subirFoto(int dronId, FotoDronLista foto) async {}
}

class _Imagenes implements SelectorImagen {
  @override
  Future<Uint8List?> tomarFoto() async => null;

  @override
  Future<Uint8List?> elegirDeGaleria() async => null;
}

void main() {
  setUpAll(cargarFuentes);

  late EntornoNegociacion entorno;
  setUp(() => entorno = EntornoNegociacion(camara: _Camara()));

  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Servicios del equipo', () {
    for (final (tamano, escala) in matriz) {
      testWidgets('la lista se lee completa en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await montar(
          tester,
          const ServiciosLotePantalla(),
          dependencias: entorno.dependencias,
          tamano: tamano,
          escala: escala,
        );
        await esperar(tester);
        expect(find.text('Servicio'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'servicios_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('el servicio en marcha va primero, con su avance', (
      tester,
    ) async {
      await montar(
        tester,
        const ServiciosLotePantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      expect(find.text('En ejecución'), findsOneWidget);
      expect(find.text('Adjudicado'), findsOneWidget);
      expect(find.textContaining('51,2 ha de 80 ha'), findsOneWidget);
    });

    testWidgets('sin servicios, el vacío explica cuándo aparecerán', (
      tester,
    ) async {
      final vacio = EntornoNegociacion(
        ejecucion: EjecucionDemo(reloj: relojFijo, vacia: true),
        camara: _Camara(),
      );
      await montar(
        tester,
        const ServiciosLotePantalla(),
        dependencias: vacio.dependencias,
        tamano: telefonoChico,
      );
      await esperar(tester);
      expect(
        find.text('Todavía no tienes un servicio adjudicado'),
        findsOneWidget,
      );
      await golden(tester, 'servicios_vacio_360x640_x1');
    });
  });

  group('Servicio en el lote', () {
    Future<void> abrir(
      WidgetTester tester,
      int id, {
      Size tamano = telefonoGrande,
      double escala = 1.0,
    }) async {
      await montar(
        tester,
        ServicioLotePantalla(servicioId: id),
        dependencias: entorno.dependencias,
        tamano: tamano,
        escala: escala,
        envolverEnScaffold: false,
      );
      await esperar(tester);
    }

    for (final (tamano, escala) in matriz) {
      testWidgets('en ejecución se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrir(tester, 10, tamano: tamano, escala: escala);
        expect(find.text('Subir foto de avance'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'servicio_en_ejecucion_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('muestra la persona de contacto con su cargo y su empresa', (
      tester,
    ) async {
      await abrir(tester, 10);
      await tester.scrollUntilVisible(
        find.text('Persona de contacto'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Persona de contacto'), findsOneWidget);
      expect(find.text('Rosario Antelo Vaca'), findsOneWidget);
      expect(
        find.text('Gerente · Agropecuaria San Rafael SRL'),
        findsOneWidget,
      );
      expect(find.text('+591 76543210'), findsOneWidget);
    });

    testWidgets('adjudicado: una sola acción principal, marcar en ejecución', (
      tester,
    ) async {
      await abrir(tester, 9);
      expect(find.text('Marcar en ejecución'), findsOneWidget);
      expect(find.text('Subir foto de avance'), findsNothing);
      await golden(tester, 'servicio_adjudicado_412x915_x1');
      await tester.tap(find.text('Marcar en ejecución'));
      await esperar(tester);
      expect(find.textContaining('Marcaste el servicio'), findsOneWidget);
      expect(find.text('Subir foto de avance'), findsOneWidget);
    });

    testWidgets('el contacto del cliente se ve tras la adjudicación', (
      tester,
    ) async {
      await abrir(tester, 9);
      await irA(tester, find.text('Luis Antelo'));
      expect(find.text('+591 71234567'), findsOneWidget);
    });

    testWidgets('marcar avance en hectáreas actualiza la barra', (
      tester,
    ) async {
      await abrir(tester, 10);
      await irA(tester, find.text('Marcar avance'));
      await tester.tap(find.text('Marcar avance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '60');
      await tester.tap(find.text('Guardar avance'));
      await esperar(tester);
      expect(find.text('Avance guardado.'), findsOneWidget);
      expect(find.textContaining('60 ha de 80 ha'), findsOneWidget);
      expect(find.textContaining('75 %'), findsOneWidget);
    });

    testWidgets('un avance mayor al servicio no se acepta', (tester) async {
      await abrir(tester, 10);
      await irA(tester, find.text('Marcar avance'));
      await tester.tap(find.text('Marcar avance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '95');
      await tester.tap(find.text('Guardar avance'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No puede pasar de las hectáreas'),
        findsOneWidget,
      );
    });

    testWidgets('bajar el avance exige el motivo de la corrección', (
      tester,
    ) async {
      await abrir(tester, 10);
      await irA(tester, find.text('Marcar avance'));
      await tester.tap(find.text('Marcar avance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '30');
      await tester.pump();
      expect(find.text('Motivo de la corrección'), findsOneWidget);
      await tester.tap(find.text('Guardar avance'));
      await tester.pumpAndSettle();
      expect(find.text('El motivo es obligatorio.'), findsOneWidget);
    });

    testWidgets('subir una foto de avance la guarda para subir luego', (
      tester,
    ) async {
      await abrir(tester, 10);
      await tester.tap(find.text('Subir foto de avance'));
      await esperar(tester);
      expect(find.textContaining('Foto guardada'), findsOneWidget);
      expect(find.text('3 fotos de avance'), findsOneWidget);
    });

    testWidgets('sin señal lo guardado queda «por subir»', (tester) async {
      entorno.ejecucionDemo.enLinea = false;
      await abrir(tester, 10);
      await tester.tap(find.text('Subir foto de avance'));
      await esperar(tester);
      expect(find.text('1 cosa por subir'), findsOneWidget);
      expect(find.textContaining('se sube solo'), findsOneWidget);
      await golden(tester, 'servicio_por_subir_412x915_x1');
      entorno.ejecucionDemo.enLinea = true;
      await entorno.ejecucionDemo.sincronizarAhora();
      await esperar(tester);
      expect(find.textContaining('por subir'), findsNothing);
    });

    testWidgets('finalizar muestra el precio a pagar, sin cobro en la app', (
      tester,
    ) async {
      await abrir(tester, 10);
      await irA(tester, find.text('Finalizar servicio'));
      await tester.tap(find.text('Finalizar servicio'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar el servicio'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '75');
      await tester.pump();
      expect(find.textContaining('A pagar: Bs 8.625'), findsOneWidget);
      await tester.tap(find.text('Finalizar'));
      await esperar(tester);
      expect(find.text('Finalizado'), findsOneWidget);
      expect(find.text('Precio estimado'), findsOneWidget);
      expect(find.text('Bs 8.625'), findsOneWidget);
      expect(find.text('Subir foto de avance'), findsNothing);
      await golden(tester, 'servicio_finalizado_412x915_x1');
    });

    testWidgets('la ubicación se explica antes de pedir el permiso', (
      tester,
    ) async {
      await abrir(tester, 10);
      await irA(tester, find.text('Dile al cliente dónde estás'));
      expect(find.textContaining('No guardamos tu recorrido'), findsOneWidget);
      expect(entorno.ubicacionDemo.permiso.name, 'denegado');
      expect(entorno.publicador.publicadas, isEmpty);
      await golden(tester, 'servicio_ubicacion_412x915_x1');

      await tester.tap(find.text('Compartir mi ubicación'));
      await esperar(tester);
      expect(find.text('Compartiendo tu ubicación'), findsOneWidget);
      expect(entorno.publicador.publicadas, isNotEmpty);
    });
  });

  group('Ingreso y registro', () {
    Widget conAcceso(Widget hijo) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AccesoProveedorRepositorio>.value(
          value: _AccesoFalso(),
        ),
        RepositoryProvider<RegistroDronesRepositorio>.value(
          value: _DronesFalso(),
        ),
        RepositoryProvider<SelectorImagen>.value(value: _Imagenes()),
      ],
      child: BlocProvider(
        create: (_) => AccesoCubit(_AccesoFalso())..iniciar(),
        child: hijo,
      ),
    );

    for (final (tamano, escala) in matriz) {
      testWidgets('el ingreso se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await montar(
          tester,
          PuertaAcceso(
            construir: (_, _) => const SizedBox(),
            nota: 'Servidor localhost:8000 · v0.1.0+1',
          ),
          dependencias: entorno.dependencias,
          tamano: tamano,
          escala: escala,
          envolverEnScaffold: false,
          envoltorios: [conAcceso],
        );
        await esperar(tester);
        expect(find.text('Entra a tu cuenta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'ingreso_${sufijo(tamano, escala)}');
      });
    }

    testWidgets(
      'credenciales malas muestran el error y no cierran el ingreso',
      (tester) async {
        await montar(
          tester,
          PuertaAcceso(construir: (_, _) => const SizedBox()),
          dependencias: entorno.dependencias,
          envolverEnScaffold: false,
          envoltorios: [conAcceso],
        );
        await esperar(tester);
        await tester.tap(find.text('Entrar'));
        await tester.pump();
        expect(find.text('Escribe tu usuario.'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).first, 'rodrigo');
        await tester.enterText(find.byType(TextFormField).last, 'mala');
        await tester.tap(find.text('Entrar'));
        await esperar(tester);
        expect(find.textContaining('incorrectos'), findsOneWidget);
        await golden(tester, 'ingreso_error_412x915_x1');
      },
    );

    Future<void> abrirRegistro(
      WidgetTester tester, {
      Size tamano = telefonoGrande,
      double escala = 1.0,
    }) async {
      await montar(
        tester,
        BlocProvider(
          create: (_) => RegistroCubit(
            acceso: _AccesoFalso(),
            drones: _DronesFalso(),
            selector: _Imagenes(),
          ),
          child: RegistroProveedorPantalla(alTerminar: () {}),
        ),
        dependencias: entorno.dependencias,
        tamano: tamano,
        escala: escala,
        envolverEnScaffold: false,
      );
      await esperar(tester);
    }

    for (final (tamano, escala) in matriz) {
      testWidgets('el registro se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrirRegistro(tester, tamano: tamano, escala: escala);
        expect(find.text('PASO 1 DE 4'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'registro_paso1_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('no avanza con datos faltantes y marca cada campo', (
      tester,
    ) async {
      await abrirRegistro(tester);
      await irA(tester, find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Este dato es obligatorio.'), findsWidgets);
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      await golden(tester, 'registro_errores_412x915_x1');
    });
  });
}
