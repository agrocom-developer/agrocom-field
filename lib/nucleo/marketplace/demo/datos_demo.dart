import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../dominio/dominio.dart';

Decimal _d(String v) => Decimal.parse(v);

/// Parcela rectangular con una leve irregularidad, centrada en
/// ([lat], [lng]), de [nsM] metros norte-sur y [eoM] metros este-oeste.
/// A 17° de latitud sur, un grado de latitud son ~111 km y uno de longitud
/// ~106 km.
List<GeoPunto> _parcela(
  double lat,
  double lng, {
  required double nsM,
  required double eoM,
  double giroGrados = 0,
}) {
  final dLat = (nsM / 2) / 111000;
  final dLng = (eoM / 2) / 106000;
  final g = giroGrados * math.pi / 180;
  GeoPunto v(double x, double y) {
    // x: este-oeste, y: norte-sur, normalizados a [-1, 1].
    final rx = x * math.cos(g) - y * math.sin(g);
    final ry = x * math.sin(g) + y * math.cos(g);
    return GeoPunto(lat + ry * dLat, lng + rx * dLng);
  }

  return [v(-1, -1), v(1, -0.94), v(0.96, 1), v(-1, 0.92)];
}

/// Conjunto de datos ficticios pero creíbles del marketplace en la zona
/// agrícola de Santa Cruz de la Sierra, Bolivia (Cuatro Cañadas, San Julián,
/// Pailón y Colonia Okinawa). Lo comparten los repositorios demo de los tres
/// flavors; ninguno lo muta: cada fake guarda su propio estado encima.
///
/// Todas las fechas se calculan respecto de [ahora] para que la demo siempre
/// se vea reciente.
class DatosDemo {
  DatosDemo({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now {
    final ahora = _reloj();
    _construir(ahora);
  }

  final DateTime Function() _reloj;
  DateTime get ahora => _reloj();

  late final List<Lote> lotes;
  late final List<Proveedor> proveedores;
  late final List<Dron> drones;
  late final List<Servicio> servicios;
  late final List<HectareasMensuales> hectareasMensuales;
  late final List<CalificacionRecibida> calificacionesDelCliente;
  late final MetricasProveedor metricasPiloto;
  late final ResumenCalificaciones calificacionesDelPiloto;

  static const clienteNombre = 'Hugo Antelo Suárez';
  static const clienteEmpresa = 'Agropecuaria Los Tajibos';
  static const pilotoNombre = 'Rodrigo Sandoval Justiniano';
  static const auxiliarNombre = 'Edwin Mamani Quispe';

  /// Proveedor que usa la sesión demo del piloto.
  Proveedor get pilotoDemo => proveedores.first;

  Proveedor proveedorPorId(String id) =>
      proveedores.firstWhere((p) => p.id == id);

  Lote loteDemoPorId(String id) => lotes.firstWhere((l) => l.id == id);

  void _construir(DateTime ahora) {
    DateTime hace(Duration d) => ahora.subtract(d);

    lotes = [
      Lote(
        id: 'lote-soya-norte',
        nombre: 'Soya Norte',
        zona: 'Cuatro Cañadas',
        cultivo: 'Soya',
        hectareas: _d('120.0'),
        fotos: const [
          FotoTerreno(
            id: 1,
            url: 'assets/imagenes/fondo_dron_pulverizando.jpg',
            descripcion: 'Borde norte',
          ),
          FotoTerreno(id: 2, url: 'assets/imagenes/fondo_dron_sobre_agua.jpg'),
        ],
        poligono: _parcela(
          -17.1830,
          -62.5560,
          nsM: 1000,
          eoM: 1200,
          giroGrados: 6,
        ),
      ),
      Lote(
        id: 'lote-maiz-sur',
        nombre: 'Maíz La Curva',
        zona: 'San Julián',
        cultivo: 'Maíz',
        hectareas: _d('85.5'),
        poligono: _parcela(
          -16.9110,
          -62.6180,
          nsM: 780,
          eoM: 1100,
          giroGrados: -9,
        ),
      ),
      Lote(
        id: 'lote-girasol',
        nombre: 'Girasol El Palmar',
        zona: 'Pailón',
        cultivo: 'Girasol',
        hectareas: _d('64.0'),
        poligono: _parcela(
          -17.6590,
          -62.7290,
          nsM: 640,
          eoM: 1000,
          giroGrados: 14,
        ),
      ),
      Lote(
        id: 'lote-trigo',
        nombre: 'Trigo Okinawa',
        zona: 'Colonia Okinawa',
        cultivo: 'Trigo',
        hectareas: _d('210.0'),
        poligono: _parcela(
          -17.2040,
          -62.8530,
          nsM: 1400,
          eoM: 1500,
          giroGrados: -4,
        ),
      ),
      Lote(
        id: 'lote-sorgo',
        nombre: 'Sorgo Tres Cruces',
        zona: 'San Julián',
        cultivo: 'Sorgo',
        hectareas: _d('48.5'),
        poligono: _parcela(
          -16.8870,
          -62.6420,
          nsM: 520,
          eoM: 930,
          giroGrados: 3,
        ),
      ),
    ];

    final resenasRodrigo = [
      Resena(
        autor: 'Agropecuaria Los Tajibos',
        puntaje: 5,
        fecha: hace(const Duration(days: 6)),
        comentario:
            'Llegó puntual y la cobertura fue pareja. Sin deriva en el borde.',
      ),
      Resena(
        autor: 'Hacienda San Rafael',
        puntaje: 5,
        fecha: hace(const Duration(days: 19)),
        comentario: 'Muy profesional con el equipo y con la mezcla.',
      ),
      Resena(
        autor: 'Familia Roca Vaca',
        puntaje: 4,
        fecha: hace(const Duration(days: 41)),
        comentario: 'Buen trabajo, se atrasó un día por la lluvia.',
      ),
      Resena(
        autor: 'Cooperativa Pailón Verde',
        puntaje: 5,
        fecha: hace(const Duration(days: 63)),
      ),
    ];

    drones = [
      Dron(
        id: 'dron-agras-t50',
        matricula: 'AGR-T50-014',
        modelo: 'DJI Agras T50',
        capacidadLitros: _d('40'),
        estado: EstadoDron.disponible,
        propiedad: PropiedadDron.agrocom,
        ciclosBateria: 212,
        cicloMaximoBateria: 400,
      ),
      Dron(
        id: 'dron-agras-t40',
        matricula: 'AGR-T40-007',
        modelo: 'DJI Agras T40',
        capacidadLitros: _d('40'),
        estado: EstadoDron.enServicio,
        propiedad: PropiedadDron.agrocom,
        ciclosBateria: 318,
        cicloMaximoBateria: 400,
      ),
      Dron(
        id: 'dron-agras-t25',
        matricula: 'TER-T25-031',
        modelo: 'DJI Agras T25',
        capacidadLitros: _d('20'),
        estado: EstadoDron.mantenimiento,
        propiedad: PropiedadDron.tercero,
        ciclosBateria: 96,
        cicloMaximoBateria: 400,
      ),
    ];

    proveedores = [
      Proveedor(
        id: 'prov-rodrigo',
        nombre: pilotoNombre,
        tipo: TipoProveedor.propioAgrocom,
        calificacion: 4.8,
        serviciosCompletados: 142,
        zonas: const ['Cuatro Cañadas', 'San Julián', 'Pailón'],
        drones: [drones[0], drones[1]],
        auxiliares: const [
          AuxiliarAsociado(nombre: auxiliarNombre, serviciosJuntos: 96),
          AuxiliarAsociado(
            nombre: 'Jhonny Vaca Parada',
            aprobacion: EstadoAprobacion.pendiente,
          ),
        ],
        resenas: resenasRodrigo,
        documentos: [
          DocumentoProveedor(
            nombre: 'Licencia de piloto remoto',
            estado: EstadoDocumento.vigente,
            vence: ahora.add(const Duration(days: 310)),
          ),
          DocumentoProveedor(
            nombre: 'Matrícula del dron AGR-T50-014',
            estado: EstadoDocumento.vigente,
            vence: ahora.add(const Duration(days: 220)),
          ),
          DocumentoProveedor(
            nombre: 'Seguro de responsabilidad civil',
            estado: EstadoDocumento.porVencer,
            vence: ahora.add(const Duration(days: 18)),
          ),
          DocumentoProveedor(
            nombre: 'Certificado de aplicador de agroquímicos',
            estado: EstadoDocumento.enRevision,
          ),
        ],
      ),
      Proveedor(
        id: 'prov-marcelo',
        nombre: 'Marcelo Roca Vaca',
        tipo: TipoProveedor.independiente,
        calificacion: 4.7,
        serviciosCompletados: 88,
        zonas: const ['San Julián', 'Colonia Okinawa'],
        drones: [drones[2]],
        auxiliares: const [AuxiliarAsociado(nombre: 'Cristian Egüez Paz')],
      ),
      Proveedor(
        id: 'prov-fernando',
        nombre: 'Fernando Parada Añez',
        tipo: TipoProveedor.duenoDeDrones,
        calificacion: 4.5,
        serviciosCompletados: 61,
        zonas: const ['Pailón', 'Colonia Okinawa'],
        auxiliares: const [
          AuxiliarAsociado(nombre: 'Daniel Chuvé Masai'),
          AuxiliarAsociado(nombre: 'Wilson Salvatierra'),
        ],
      ),
      Proveedor(
        id: 'prov-daniela',
        nombre: 'Daniela Egüez Rojas',
        tipo: TipoProveedor.independiente,
        calificacion: 4.9,
        serviciosCompletados: 203,
        zonas: const ['Cuatro Cañadas', 'Colonia Okinawa'],
        auxiliares: const [AuxiliarAsociado(nombre: 'Pablo Cuéllar')],
      ),
    ];

    final rodrigo = proveedores[0];

    servicios = [
      // En ejecución ahora mismo: el que el cliente sigue en vivo.
      Servicio(
        id: 'srv-1042',
        lote: lotes[0],
        producto: 'Glifosato 480 SL + coadyuvante',
        dosisLitrosPorHectarea: _d('2.4'),
        hectareasDeclaradas: _d('120.0'),
        hectareasCubiertas: _d('46.8'),
        fechaDeseada: ahora,
        estado: EstadoServicio.enEjecucion,
        precio: _d('10800.00'),
        solicitadoEn: hace(const Duration(days: 2)),
        proveedor: rodrigo,
        dron: drones[1],
        clienteNombre: clienteNombre,
        etaMinutos: 74,
      ),
      // Con proveedor asignado, aún sin empezar.
      Servicio(
        id: 'srv-1046',
        lote: lotes[3],
        producto: 'Fungicida triazol + estrobilurina',
        dosisLitrosPorHectarea: _d('0.8'),
        hectareasDeclaradas: _d('210.0'),
        hectareasCubiertas: _d('0'),
        fechaDeseada: ahora.add(const Duration(days: 2)),
        estado: EstadoServicio.asignado,
        precio: _d('19950.00'),
        solicitadoEn: hace(const Duration(hours: 20)),
        proveedor: proveedores[3],
        clienteNombre: clienteNombre,
        etaMinutos: 2880,
      ),
      // Recién solicitado: el motor lo ofrece primero a la flota de Agrocom.
      Servicio(
        id: 'srv-1047',
        lote: lotes[4],
        producto: 'Fertilizante foliar',
        dosisLitrosPorHectarea: _d('3.0'),
        hectareasDeclaradas: _d('48.5'),
        hectareasCubiertas: _d('0'),
        fechaDeseada: ahora.add(const Duration(days: 4)),
        estado: EstadoServicio.buscandoProveedor,
        precio: _d('4365.00'),
        solicitadoEn: hace(const Duration(minutes: 6)),
        clienteNombre: clienteNombre,
      ),
      Servicio(
        id: 'srv-1039',
        lote: lotes[1],
        producto: 'Fungicida triazol + estrobilurina',
        dosisLitrosPorHectarea: _d('0.8'),
        hectareasDeclaradas: _d('85.5'),
        hectareasCubiertas: _d('85.5'),
        fechaDeseada: hace(const Duration(days: 9)),
        estado: EstadoServicio.completado,
        precio: _d('8122.50'),
        solicitadoEn: hace(const Duration(days: 14)),
        proveedor: rodrigo,
        dron: drones[0],
        puntajeDelCliente: 5,
        puntajeDelProveedor: 5,
        clienteNombre: clienteNombre,
      ),
      Servicio(
        id: 'srv-1031',
        lote: lotes[2],
        producto: 'Insecticida piretroide',
        dosisLitrosPorHectarea: _d('0.5'),
        hectareasDeclaradas: _d('64.0'),
        hectareasCubiertas: _d('64.0'),
        fechaDeseada: hace(const Duration(days: 27)),
        estado: EstadoServicio.completado,
        precio: _d('6080.00'),
        solicitadoEn: hace(const Duration(days: 31)),
        proveedor: proveedores[3],
        puntajeDelCliente: 4,
        puntajeDelProveedor: 5,
        clienteNombre: clienteNombre,
      ),
      // Completado y aún sin calificar: invita a calificar.
      Servicio(
        id: 'srv-1036',
        lote: lotes[3],
        producto: 'Herbicida de preemergencia',
        dosisLitrosPorHectarea: _d('1.2'),
        hectareasDeclaradas: _d('210.0'),
        hectareasCubiertas: _d('210.0'),
        fechaDeseada: hace(const Duration(days: 4)),
        estado: EstadoServicio.completado,
        precio: _d('19950.00'),
        solicitadoEn: hace(const Duration(days: 8)),
        proveedor: proveedores[1],
        clienteNombre: clienteNombre,
      ),
      Servicio(
        id: 'srv-1020',
        lote: lotes[4],
        producto: 'Fertilizante foliar',
        dosisLitrosPorHectarea: _d('3.0'),
        hectareasDeclaradas: _d('48.5'),
        hectareasCubiertas: _d('0'),
        fechaDeseada: hace(const Duration(days: 52)),
        estado: EstadoServicio.cancelado,
        precio: _d('4607.50'),
        solicitadoEn: hace(const Duration(days: 55)),
        clienteNombre: clienteNombre,
      ),
    ];

    const meses = ['Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov'];
    const valores = ['410.5', '520.0', '688.5', '735.0', '612.5', '478.0'];
    hectareasMensuales = [
      for (var i = 0; i < meses.length; i++)
        HectareasMensuales(etiqueta: meses[i], hectareas: _d(valores[i])),
    ];

    metricasPiloto = MetricasProveedor(
      serviciosCompletados: rodrigo.serviciosCompletados,
      hectareasAtendidas: _d('11846.5'),
      tasaAceptacion: 92,
      tasaCancelacion: 2,
    );

    calificacionesDelPiloto = ResumenCalificaciones(
      promedio: rodrigo.calificacion,
      total: 128,
      porPuntaje: const {5: 108, 4: 15, 3: 4, 2: 1, 1: 0},
      recientes: [
        for (var i = 0; i < resenasRodrigo.length; i++)
          CalificacionRecibida(
            servicioId: 'srv-res-$i',
            autor: resenasRodrigo[i].autor,
            puntaje: resenasRodrigo[i].puntaje,
            fecha: resenasRodrigo[i].fecha,
            comentario: resenasRodrigo[i].comentario,
          ),
      ],
    );

    calificacionesDelCliente = [
      CalificacionRecibida(
        servicioId: 'srv-1039',
        autor: 'Rodrigo Sandoval',
        puntaje: 5,
        fecha: hace(const Duration(days: 9)),
        comentario: 'Lote bien señalizado y acceso fácil para la camioneta.',
      ),
      CalificacionRecibida(
        servicioId: 'srv-1031',
        autor: 'Daniela Egüez',
        puntaje: 5,
        fecha: hace(const Duration(days: 27)),
      ),
    ];
  }

  /// Ofertas de ejemplo para la bandeja del piloto, con ventana respecto de
  /// [ahora]. La primera es de la flota propia de Agrocom.
  List<Oferta> ofertasIniciales() {
    final t = ahora;
    return [
      Oferta(
        id: 'of-1',
        lote: lotes[3],
        producto: 'Herbicida de preemergencia',
        pago: _d('1890.00'),
        distanciaKm: _d('14.2'),
        ventana: const Duration(minutes: 3),
        recibidaEn: t,
        fechaServicio: t.add(const Duration(days: 1)),
        esDeAgrocom: true,
      ),
      Oferta(
        id: 'of-2',
        lote: lotes[4],
        producto: 'Fertilizante foliar',
        pago: _d('690.50'),
        distanciaKm: _d('31.7'),
        ventana: const Duration(minutes: 10),
        recibidaEn: t.subtract(const Duration(minutes: 2)),
        fechaServicio: t.add(const Duration(days: 2)),
      ),
      Oferta(
        id: 'of-3',
        lote: lotes[2],
        producto: 'Insecticida piretroide',
        pago: _d('920.00'),
        distanciaKm: _d('48.9'),
        ventana: const Duration(minutes: 15),
        recibidaEn: t.subtract(const Duration(minutes: 5)),
        fechaServicio: t.add(const Duration(days: 3)),
      ),
    ];
  }
}
