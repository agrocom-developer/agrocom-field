import 'package:agrocom_field/l10n/app_localizations_es.dart';
import 'package:agrocom_field/nucleo/api/marketplace_http.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart'
    show EstadoAprobacion;
import 'package:agrocom_field/nucleo/marketplace/dominio/falla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/data/cuenta_proveedor_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/data/cuenta_proveedor_red.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/domain/cuenta_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/presentation/disponibilidad_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/presentation/documentos_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/cuenta/presentation/estado_cuenta_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion_repositorios.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../cliente/red/dobles_red.dart';
import '../../dobles_foto.dart';

const _pendiente = EstadoCuentaProveedor(
  proveedorId: 12,
  aprobacion: EstadoAprobacion.pendiente,
  documentosFaltantes: [
    TipoDocumentoProveedor.licenciaPiloto,
    TipoDocumentoProveedor.registroDron,
  ],
  aptoParaOfertas: false,
  disponibilidad: EstadoDisponibilidad(valor: Disponibilidad.disponible),
  disponibilidadEmpresa: EstadoDisponibilidad(valor: Disponibilidad.disponible),
);

Map<String, dynamic> _disp(String valor, {bool? propia}) => {
  'valor': valor,
  'cambiada_en': '2026-11-27T10:00:00Z',
  'cambiada_por_usuario_id': 31,
  'cambiada_por_propia': propia,
};

class _AvisosFalsos implements AvisosRepositorio {
  @override
  Future<PreferenciasAviso> leer() async => const PreferenciasAviso(
    departamentosExcluidos: ['04'],
    tiposAplicacionExcluidos: ['desecante', 'herbicida'],
  );

  @override
  Future<PreferenciasAviso> guardar(PreferenciasAviso preferencias) async =>
      preferencias;
}

void main() {
  group('CuentaProveedorRed', () {
    late EntornoRed e;
    late CuentaProveedorRed repo;

    setUp(() {
      e = EntornoRed();
      repo = CuentaProveedorRed(MarketplaceHttp(e.api));
    });

    test(
      'lee el estado, lo que falta y la disponibilidad de la empresa',
      () async {
        e.servidor.responder(
          'GET',
          '/api/proveedores/mi',
          cuerpo: {
            'proveedor': {
              'id': 12,
              'estado': 'rechazado',
              'motivo_estado': 'Licencia ilegible',
            },
            'documentos_faltantes': [
              'licencia_piloto',
              'tipo_que_la_app_no_conoce',
              'seguro_responsabilidad',
            ],
            'apto_para_ofertas': false,
            'disponibilidad': _disp('ocupado', propia: false),
            'disponibilidad_empresa': _disp('disponible', propia: true),
          },
        );
        final c = await repo.estado();
        expect(c.proveedorId, 12);
        expect(c.aprobacion, EstadoAprobacion.rechazado);
        expect(c.motivo, 'Licencia ilegible');
        expect(c.documentosFaltantes, [
          TipoDocumentoProveedor.licenciaPiloto,
          TipoDocumentoProveedor.seguroResponsabilidad,
        ]);
        expect(c.puedeVerMapa, isFalse);
        expect(c.disponibilidad.laCambioLaEmpresa, isTrue);
        expect(c.disponibilidadEmpresa.laCambioLaEmpresa, isFalse);
      },
    );

    test('lista los documentos del proveedor', () async {
      e.servidor.responder(
        'GET',
        '/api/proveedores/documentos',
        cuerpo: {
          'data': [
            {
              'id': 40,
              'sujeto_tipo': 'proveedor',
              'sujeto_id': 12,
              'tipo': 'licencia_piloto',
              'estado': 'rechazado',
              'vence_en': '2027-05-01',
              'motivo_rechazo': 'Borrosa',
            },
          ],
        },
      );
      final docs = await repo.documentos(12);
      expect(docs.single.estado, EstadoDocumentoEnviado.rechazado);
      expect(docs.single.motivoRechazo, 'Borrosa');
      expect(docs.single.venceEn, DateTime(2027, 5, 1));
      final p = e.servidor.de('GET', '/api/proveedores/documentos').single;
      expect(p.query['sujeto_tipo'], 'proveedor');
      expect(p.query['sujeto_id'], 12);
    });

    test(
      'sube el documento como multipart con tipo, sujeto y vencimiento',
      () async {
        e.servidor.responder(
          'POST',
          '/api/proveedores/documentos',
          codigo: 201,
          cuerpo: {
            'documento': {
              'id': 41,
              'sujeto_tipo': 'proveedor',
              'sujeto_id': 12,
              'tipo': 'licencia_piloto',
              'estado': 'en_revision',
            },
          },
        );
        final nuevo = await repo.subirDocumento(
          12,
          DocumentoPorSubir(
            tipo: TipoDocumentoProveedor.licenciaPiloto,
            bytes: fotoDePrueba,
            venceEn: DateTime(2027, 3, 9),
          ),
        );
        expect(nuevo.estado, EstadoDocumentoEnviado.enRevision);
        final cuerpo =
            e.servidor.de('POST', '/api/proveedores/documentos').single.cuerpo!
                as FormData;
        final campos = {for (final f in cuerpo.fields) f.key: f.value};
        expect(campos, {
          'sujeto_tipo': 'proveedor',
          'sujeto_id': '12',
          'tipo': 'licencia_piloto',
          'vence_en': '2027-03-09',
        });
        expect(cuerpo.files.single.key, 'archivo');
      },
    );

    test('cambia la disponibilidad con PUT', () async {
      e.servidor.responder(
        'PUT',
        '/api/proveedores/mi/disponibilidad',
        cuerpo: {'disponibilidad': _disp('en_trabajo', propia: true)},
      );
      final d = await repo.cambiarDisponibilidad(Disponibilidad.enTrabajo);
      expect(d.valor, Disponibilidad.enTrabajo);
      final p = e.servidor
          .de('PUT', '/api/proveedores/mi/disponibilidad')
          .single;
      expect(p.cuerpo, {'disponibilidad': 'en_trabajo'});
    });
  });

  group('EstadoCuentaCubit', () {
    test('en revisión no puede ver el mapa; aprobado sí', () async {
      final repo = CuentaProveedorDemo(estado: _pendiente);
      final c = EstadoCuentaCubit(repo);
      await c.cargar();
      expect(c.state, isA<EstadoCuentaListo>());
      expect((c.state as EstadoCuentaListo).cuenta.puedeVerMapa, isFalse);
    });

    test('reenviar tras un rechazo vuelve a pendiente', () async {
      final repo = CuentaProveedorDemo(
        estado: const EstadoCuentaProveedor(
          proveedorId: 1,
          aprobacion: EstadoAprobacion.rechazado,
          documentosFaltantes: [],
          aptoParaOfertas: false,
          disponibilidad: EstadoDisponibilidad(
            valor: Disponibilidad.disponible,
          ),
          disponibilidadEmpresa: EstadoDisponibilidad(
            valor: Disponibilidad.disponible,
          ),
        ),
      );
      final c = EstadoCuentaCubit(repo);
      await c.cargar();
      await c.reenviar(mensajeSinRed: 'sin red');
      expect(
        (c.state as EstadoCuentaListo).cuenta.aprobacion,
        EstadoAprobacion.pendiente,
      );
    });
  });

  group('DocumentosCubit', () {
    late CuentaProveedorDemo repo;
    late SelectorImagenFalso selector;
    late DocumentosCubit cubit;

    setUp(() async {
      repo = CuentaProveedorDemo(
        estado: _pendiente,
        documentos: const [
          DocumentoEnviado(
            id: 3,
            tipo: TipoDocumentoProveedor.identidad,
            estado: EstadoDocumentoEnviado.aprobado,
          ),
          DocumentoEnviado(
            id: 2,
            tipo: TipoDocumentoProveedor.registroDron,
            estado: EstadoDocumentoEnviado.rechazado,
            motivoRechazo: 'No se lee la serie',
          ),
        ],
      );
      selector = SelectorImagenFalso();
      cubit = DocumentosCubit(
        repo,
        preparadorDePrueba(selector),
        AppLocalizationsEs(),
      );
      await cubit.cargar();
    });

    ItemDocumento item(TipoDocumentoProveedor t) =>
        cubit.state.items.firstWhere((i) => i.tipo == t);

    test('junta lo que falta con lo ya enviado, cada uno con su estado', () {
      expect(
        item(TipoDocumentoProveedor.licenciaPiloto).etapa,
        EtapaDocumento.faltante,
      );
      expect(
        item(TipoDocumentoProveedor.registroDron).etapa,
        EtapaDocumento.rechazado,
      );
      expect(
        item(TipoDocumentoProveedor.registroDron).mensaje,
        'No se lee la serie',
      );
      expect(
        item(TipoDocumentoProveedor.identidad).etapa,
        EtapaDocumento.aprobado,
      );
      expect(item(TipoDocumentoProveedor.identidad).puedeCapturar, isFalse);
    });

    test('tomar abre la cámara y envía; queda en revisión', () async {
      final foto = await cubit.tomar(
        TipoDocumentoProveedor.licenciaPiloto,
        alDenegar: () => fail('no debía negarse'),
      );
      expect(foto, isNotNull);
      expect(selector.llamadas, 1);
      await cubit.enviar(
        DocumentoPorSubir(
          tipo: foto!.tipo,
          bytes: foto.bytes,
          venceEn: DateTime(2027, 1, 1),
        ),
      );
      expect(
        item(TipoDocumentoProveedor.licenciaPiloto).etapa,
        EtapaDocumento.enRevision,
      );
      expect(repo.subidos.single.venceEn, DateTime(2027, 1, 1));
    });

    test('cancelar la cámara no envía nada', () async {
      selector.cancela = true;
      final foto = await cubit.tomar(
        TipoDocumentoProveedor.licenciaPiloto,
        alDenegar: () {},
      );
      expect(foto, isNull);
      expect(repo.subidos, isEmpty);
    });

    test('sin red: marca el error, conserva la foto y reintenta', () async {
      repo.fallaProximaSubida = const SinConexion();
      final doc = DocumentoPorSubir(
        tipo: TipoDocumentoProveedor.registroDron,
        bytes: fotoDePrueba,
      );
      await cubit.enviar(doc);
      expect(
        item(TipoDocumentoProveedor.registroDron).etapa,
        EtapaDocumento.errorEnvio,
      );
      expect(item(TipoDocumentoProveedor.registroDron).puedeCapturar, isTrue);

      await cubit.reintentar(TipoDocumentoProveedor.registroDron);
      expect(
        item(TipoDocumentoProveedor.registroDron).etapa,
        EtapaDocumento.enRevision,
      );
      expect(repo.subidos, hasLength(1));
    });

    test('rechazo del servidor deja su mensaje para corregir', () async {
      repo.fallaProximaSubida = const OperacionRechazada('Archivo inválido');
      await cubit.enviar(
        DocumentoPorSubir(
          tipo: TipoDocumentoProveedor.licenciaPiloto,
          bytes: fotoDePrueba,
        ),
      );
      final i = item(TipoDocumentoProveedor.licenciaPiloto);
      expect(i.etapa, EtapaDocumento.errorEnvio);
      expect(i.mensaje, 'Archivo inválido');
    });
  });

  group('DisponibilidadCubit', () {
    test(
      'carga la propia, la de la empresa y los parámetros de aviso',
      () async {
        final repo = CuentaProveedorDemo(
          estado: const EstadoCuentaProveedor(
            proveedorId: 1,
            aprobacion: EstadoAprobacion.aprobado,
            documentosFaltantes: [],
            aptoParaOfertas: true,
            disponibilidad: EstadoDisponibilidad(
              valor: Disponibilidad.ocupado,
              cambiadaPorPropia: false,
            ),
            disponibilidadEmpresa: EstadoDisponibilidad(
              valor: Disponibilidad.enTrabajo,
            ),
          ),
        );
        final c = DisponibilidadCubit(
          repo,
          _AvisosFalsos(),
          AppLocalizationsEs(),
        );
        await c.cargar();
        expect(c.state.propia!.laCambioLaEmpresa, isTrue);
        expect(c.state.empresaOcupada, isTrue);
        expect(c.state.preferencias.tiposAplicacionExcluidos, hasLength(2));
      },
    );

    test('cambiar actualiza; sin red avisa y no cambia', () async {
      final repo = CuentaProveedorDemo();
      final c = DisponibilidadCubit(repo, null, AppLocalizationsEs());
      await c.cargar();
      await c.cambiar(Disponibilidad.ocupado);
      expect(c.state.propia!.valor, Disponibilidad.ocupado);
      expect(c.state.propia!.cambiadaPorPropia, isTrue);

      final sinRed = _CuentaSinRed(repo);
      final c2 = DisponibilidadCubit(sinRed, null, AppLocalizationsEs());
      await c2.cargar();
      await c2.cambiar(Disponibilidad.enTrabajo);
      expect(c2.state.propia!.valor, Disponibilidad.ocupado);
      expect(c2.state.aviso, contains('Sin conexión'));
    });
  });
}

class _CuentaSinRed implements CuentaProveedorRepositorio {
  _CuentaSinRed(this._base);

  final CuentaProveedorRepositorio _base;

  @override
  Future<EstadoCuentaProveedor> estado() => _base.estado();

  @override
  Future<List<DocumentoEnviado>> documentos(int proveedorId) =>
      _base.documentos(proveedorId);

  @override
  Future<DocumentoEnviado> subirDocumento(int id, DocumentoPorSubir d) =>
      throw const SinConexion();

  @override
  Future<void> reenviarARevision() => throw const SinConexion();

  @override
  Future<EstadoDisponibilidad> cambiarDisponibilidad(Disponibilidad valor) =>
      throw const SinConexion();
}
