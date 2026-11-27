import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart'
    show EstadoAprobacion;
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/data/cuenta_proveedor_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/domain/cuenta_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/presentation/estado_cuenta_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _montar(
  WidgetTester tester,
  CuentaProveedorRepositorio repo, {
  double escala = 1,
}) async {
  tester.view.physicalSize = const Size(720, 1440);
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    RepositoryProvider<CuentaProveedorRepositorio>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
        home: const Scaffold(
          body: PuertaAprobacion(child: Text('MAPA-DE-SOLICITUDES')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EstadoCuentaProveedor _con(EstadoAprobacion a, {String? motivo}) =>
    EstadoCuentaProveedor(
      proveedorId: 1,
      aprobacion: a,
      motivo: motivo,
      documentosFaltantes: const [TipoDocumentoProveedor.licenciaPiloto],
      aptoParaOfertas: a == EstadoAprobacion.aprobado,
      disponibilidad: const EstadoDisponibilidad(
        valor: Disponibilidad.disponible,
      ),
      disponibilidadEmpresa: const EstadoDisponibilidad(
        valor: Disponibilidad.disponible,
      ),
    );

void main() {
  testWidgets('aprobado: deja pasar al mapa', (tester) async {
    await _montar(
      tester,
      CuentaProveedorDemo(estado: _con(EstadoAprobacion.aprobado)),
    );
    expect(find.text('MAPA-DE-SOLICITUDES'), findsOneWidget);
  });

  testWidgets('en revisión: no hay mapa, dice qué falta y ofrece subirlo', (
    tester,
  ) async {
    await _montar(
      tester,
      CuentaProveedorDemo(estado: _con(EstadoAprobacion.pendiente)),
    );
    expect(find.text('MAPA-DE-SOLICITUDES'), findsNothing);
    expect(find.text('Tu cuenta está en revisión'), findsOneWidget);
    expect(find.text('Licencia de piloto'), findsOneWidget);
    expect(find.byKey(const Key('cuenta-subir-documentos')), findsOneWidget);
  });

  testWidgets('rechazado: muestra el motivo y permite reenviar', (
    tester,
  ) async {
    await _montar(
      tester,
      CuentaProveedorDemo(
        estado: _con(EstadoAprobacion.rechazado, motivo: 'Licencia ilegible'),
      ),
    );
    expect(find.text('Motivo: Licencia ilegible'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cuenta-reenviar')));
    await tester.pumpAndSettle();
    expect(find.text('Tu cuenta está en revisión'), findsOneWidget);
  });

  testWidgets('al 200 % no desborda', (tester) async {
    await _montar(
      tester,
      CuentaProveedorDemo(estado: _con(EstadoAprobacion.pendiente)),
      escala: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
