import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../nucleo/marketplace/demo/datos_demo.dart';
import '../mezcla/domain/mezcla_repositorio.dart';

/// Estado en memoria del flavor auxiliar en modo demo.
class AlmacenDemoAuxiliar {
  AlmacenDemoAuxiliar({DatosDemo? datos, Uuid? uuid})
    : datos = datos ?? DatosDemo(),
      _uuid = uuid ?? const Uuid() {
    final ahora = this.datos.ahora;
    _mezclas = [
      RegistroMezcla(
        uuidCliente: _uuid.v4(),
        producto: 'Glifosato 480 SL + coadyuvante',
        litros: Decimal.parse('96.0'),
        numeroTanque: 1,
        registradoEn: ahora.subtract(const Duration(minutes: 95)),
        sincronizado: true,
      ),
      RegistroMezcla(
        uuidCliente: _uuid.v4(),
        producto: 'Glifosato 480 SL + coadyuvante',
        litros: Decimal.parse('96.0'),
        numeroTanque: 2,
        registradoEn: ahora.subtract(const Duration(minutes: 52)),
        sincronizado: true,
      ),
      RegistroMezcla(
        uuidCliente: _uuid.v4(),
        producto: 'Glifosato 480 SL + coadyuvante',
        litros: Decimal.parse('72.5'),
        numeroTanque: 3,
        registradoEn: ahora.subtract(const Duration(minutes: 14)),
      ),
    ];
  }

  final DatosDemo datos;
  final Uuid _uuid;
  late List<RegistroMezcla> _mezclas;
  final _cambios = StreamController<List<RegistroMezcla>>.broadcast();

  List<RegistroMezcla> get mezclas => List.unmodifiable(_mezclas);

  Stream<List<RegistroMezcla>> observar() async* {
    yield mezclas;
    yield* _cambios.stream;
  }

  void agregar(String producto, Decimal litros) {
    _mezclas = [
      RegistroMezcla(
        uuidCliente: _uuid.v4(),
        producto: producto,
        litros: litros,
        numeroTanque: _mezclas.length + 1,
        registradoEn: datos.ahora,
      ),
      ..._mezclas,
    ];
    _cambios.add(mezclas);
  }
}
