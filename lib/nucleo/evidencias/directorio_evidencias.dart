import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resuelve dónde `EvidenciaRepository` persiste los archivos YA
/// COMPRIMIDOS (invariante 8 de CLAUDE.md) — una subcarpeta propia dentro
/// del directorio de documentos de la app, creada si todavía no existe.
///
/// Función separada del repositorio a propósito: así el repositorio recibe
/// el [Directory] ya resuelto y es testeable sin canal de plataforma (ver
/// `evidencia_repository_test.dart`, que le pasa un directorio temporal en
/// su lugar).
Future<Directory> resolverDirectorioEvidencias() async {
  final base = await getApplicationDocumentsDirectory();
  final directorio = Directory('${base.path}/evidencias');
  if (!directorio.existsSync()) {
    await directorio.create(recursive: true);
  }
  return directorio;
}
