import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'compresor_evidencia.dart';
import 'hash_evidencia.dart';

/// Captura → comprime → hashea → persiste el archivo → encola, todo en una
/// sola operación coherente (invariante 3 de CLAUDE.md): la app no espera señal
/// para confirmar que la evidencia "quedó guardada" localmente y puede
/// seguir capturando. No hay pantalla de cámara en esta tarea (TE-07):
/// quien llame a [capturarEvidencia] ya tiene los bytes originales en
/// memoria — eso lo resuelve HU-08/HU-09, más adelante.
///
/// A diferencia de `TrabajoRepository`/`SesionRepository`, acá no hay una
/// tabla espejo más `ColaSync`: [EvidenciaLocal] ES la cola (invariante 8 de
/// CLAUDE.md, cola separada de los registros livianos), así que un único
/// insert ya es la operación atómica completa.
class EvidenciaRepository {
  EvidenciaRepository(
    this._db, {
    required CompresorEvidencia compresor,
    required Directory directorioEvidencias,
    Uuid? uuid,
  }) : _compresor = compresor,
       _directorioEvidencias = directorioEvidencias,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final CompresorEvidencia _compresor;
  final Directory _directorioEvidencias;
  final Uuid _uuid;

  /// Devuelve el `uuid_cliente` generado en el dispositivo (invariante 2 de
  /// CLAUDE.md) para la fila recién encolada.
  Future<String> capturarEvidencia({
    required Uint8List bytesOriginales,
    required String tipo,
    required DateTime fecha,
  }) async {
    final uuidCliente = _uuid.v4();
    final comprimido = await _compresor.comprimir(bytesOriginales);
    final hash = calcularHashEvidencia(comprimido);

    if (!_directorioEvidencias.existsSync()) {
      await _directorioEvidencias.create(recursive: true);
    }
    final archivo = File('${_directorioEvidencias.path}/$uuidCliente.jpg');
    await archivo.writeAsBytes(comprimido, flush: true);

    await _db
        .into(_db.evidenciaLocal)
        .insert(
          EvidenciaLocalCompanion.insert(
            uuidCliente: uuidCliente,
            tipo: tipo,
            rutaArchivoLocal: archivo.path,
            hashSha256: hash,
            fecha: fecha,
          ),
        );

    return uuidCliente;
  }
}
