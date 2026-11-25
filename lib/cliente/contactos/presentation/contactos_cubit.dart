import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/contacto.dart';
import '../domain/contactos_repositorio.dart';

sealed class ContactosEstado {
  const ContactosEstado();
}

final class ContactosCargando extends ContactosEstado {
  const ContactosCargando();
}

final class ContactosError extends ContactosEstado {
  const ContactosError({required this.sinConexion});

  final bool sinConexion;
}

final class ContactosListos extends ContactosEstado {
  const ContactosListos(this.contactos, {this.ocupado = false});

  final List<ContactoCliente> contactos;

  /// Hay un guardado o una baja en curso.
  final bool ocupado;
}

/// Por qué no se pudo guardar o dar de baja un contacto.
sealed class ResultadoContacto {
  const ResultadoContacto();
}

final class ContactoGuardado extends ResultadoContacto {
  const ContactoGuardado();
}

final class ContactoFallo extends ResultadoContacto {
  const ContactoFallo({
    required this.sinConexion,
    this.mensaje,
    this.porCampo = const {},
  });

  final bool sinConexion;

  /// Lo que dijo el servidor (por ejemplo, «una empresa necesita al menos un
  /// contacto»), si lo dijo.
  final String? mensaje;

  /// Errores por campo (`nombre`, `telefono`) de un `422`.
  final Map<String, String> porCampo;
}

/// Contactos de referencia del cliente empresa.
class ContactosCubit extends Cubit<ContactosEstado> {
  ContactosCubit(this._repositorio) : super(const ContactosCargando());

  final ContactosRepositorio _repositorio;

  Future<void> cargar() async {
    if (state is! ContactosCargando) emit(const ContactosCargando());
    try {
      final lista = await _repositorio.listar();
      if (!isClosed) emit(ContactosListos(lista));
    } on SinConexion {
      if (!isClosed) emit(const ContactosError(sinConexion: true));
    } on Object {
      if (!isClosed) emit(const ContactosError(sinConexion: false));
    }
  }

  /// Agrega ([id] nulo) o corrige un contacto y recarga la lista.
  Future<ResultadoContacto> guardar(DatosContacto datos, {int? id}) =>
      _operar(() async {
        if (id == null) {
          await _repositorio.agregar(datos);
        } else {
          await _repositorio.actualizar(id, datos);
        }
      });

  Future<ResultadoContacto> darDeBaja(int id) =>
      _operar(() => _repositorio.darDeBaja(id));

  Future<ResultadoContacto> _operar(Future<void> Function() accion) async {
    final actual = state;
    if (actual is ContactosListos) {
      emit(ContactosListos(actual.contactos, ocupado: true));
    }
    try {
      await accion();
      final lista = await _repositorio.listar();
      if (!isClosed) emit(ContactosListos(lista));
      return const ContactoGuardado();
    } on SinConexion {
      _volver(actual);
      return const ContactoFallo(sinConexion: true);
    } on OperacionRechazada catch (e) {
      _volver(actual);
      return ContactoFallo(sinConexion: false, mensaje: e.mensaje);
    } on Object {
      _volver(actual);
      return const ContactoFallo(sinConexion: false);
    }
  }

  void _volver(ContactosEstado anterior) {
    if (isClosed) return;
    emit(
      anterior is ContactosListos
          ? ContactosListos(anterior.contactos)
          : anterior,
    );
  }
}
