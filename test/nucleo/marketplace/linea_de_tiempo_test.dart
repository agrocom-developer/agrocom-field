import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

void main() {
  final ahora = DateTime(2026, 11, 23, 9);
  final datos = DatosDemo(reloj: () => ahora);
  Servicio servicio(String id) => datos.servicios.firstWhere((s) => s.id == id);

  ActaConformidad acta(Servicio s, EstadoActa estado) => ActaConformidad(
    servicioId: s.id,
    estado: estado,
    hectareasConfirmadas: s.hectareasCubiertas,
    litrosAplicados: s.litrosTotales,
    inicio: ahora.subtract(const Duration(hours: 5)),
    fin: ahora.subtract(const Duration(hours: 2)),
    resumen: 'Sin incidencias.',
    venceConformidad: ahora.add(const Duration(hours: 70)),
    firmadaEn: estado == EstadoActa.firmada ? ahora : null,
  );

  List<EstadoHito> estados(List<HitoServicio> hitos) => [
    for (final h in hitos) h.estado,
  ];

  const hecho = EstadoHito.hecho;
  const actual = EstadoHito.actual;
  const pendiente = EstadoHito.pendiente;

  test('siempre tiene las cinco etapas en orden', () {
    for (final s in datos.servicios) {
      expect(
        lineaDeTiempo(s).map((h) => h.etapa),
        EtapaServicio.values,
        reason: s.id,
      );
    }
  });

  test('buscando proveedor: la asignación es la etapa en curso', () {
    final hitos = lineaDeTiempo(servicio('srv-1047'));
    expect(estados(hitos), [hecho, actual, pendiente, pendiente, pendiente]);
    expect(hitos[1].titulo, 'Buscando proveedor');
    expect(hitos[1].detalle, contains('flota de Agrocom'));
    expect(hitos.first.momento, servicio('srv-1047').solicitadoEn);
  });

  test('asignado: nombra al proveedor y sigue sin despegar', () {
    final hitos = lineaDeTiempo(servicio('srv-1046'));
    expect(estados(hitos), [hecho, actual, pendiente, pendiente, pendiente]);
    expect(hitos[1].titulo, 'Proveedor asignado');
    expect(hitos[1].detalle, contains('Daniela Egüez Rojas'));
  });

  test('en ejecución: la fumigación es la etapa en curso', () {
    final hitos = lineaDeTiempo(servicio('srv-1042'));
    expect(estados(hitos), [hecho, hecho, actual, pendiente, pendiente]);
    expect(hitos[2].detalle, contains('aplicando'));
  });

  test('el estado en vivo manda sobre el del servicio recibido', () {
    final hitos = lineaDeTiempo(
      servicio('srv-1042'),
      estadoVivo: EstadoServicio.completado,
      acta: acta(servicio('srv-1042'), EstadoActa.pendiente),
    );
    expect(estados(hitos), [hecho, hecho, hecho, actual, pendiente]);
    expect(hitos[2].titulo, 'Fumigación terminada');
  });

  test('recién terminado y sin acta cargada: falta la conformidad', () {
    final hitos = lineaDeTiempo(
      servicio('srv-1042'),
      estadoVivo: EstadoServicio.completado,
      faltaConformidad: true,
    );
    expect(estados(hitos), [hecho, hecho, hecho, actual, pendiente]);
    expect(hitos[3].detalle, contains('firmá el acta'));
  });

  test('completado sin acta a la vista: se da por conforme', () {
    final hitos = lineaDeTiempo(servicio('srv-1039'));
    expect(estados(hitos), everyElement(hecho));
    expect(hitos[3].detalle, 'El servicio quedó conforme.');
  });

  test('completado con acta pendiente: falta la conformidad', () {
    final s = servicio('srv-1036');
    final hitos = lineaDeTiempo(s, acta: acta(s, EstadoActa.pendiente));
    expect(estados(hitos), [hecho, hecho, hecho, actual, pendiente]);
    expect(hitos[3].detalle, contains('firmá el acta'));
  });

  test('completado con acta observada: sigue sin cerrarse', () {
    final s = servicio('srv-1036');
    final hitos = lineaDeTiempo(s, acta: acta(s, EstadoActa.observada));
    expect(estados(hitos), [hecho, hecho, hecho, actual, pendiente]);
    expect(hitos[3].detalle, contains('soporte'));
  });

  test('completado con acta firmada: todo hecho, con la hora de la firma', () {
    final s = servicio('srv-1039');
    final hitos = lineaDeTiempo(s, acta: acta(s, EstadoActa.firmada));
    expect(estados(hitos), everyElement(hecho));
    expect(hitos[3].momento, ahora);
  });

  test('cancelado sin proveedor: se detiene y no hay etapa en curso', () {
    final hitos = lineaDeTiempo(servicio('srv-1020'));
    expect(estados(hitos), [hecho, pendiente, pendiente, pendiente, pendiente]);
    expect(hitos[1].detalle, contains('Ningún proveedor'));
  });
}
