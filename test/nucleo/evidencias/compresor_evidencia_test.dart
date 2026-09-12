// `CompresorEvidenciaFlutterImageCompress` mockeando el `MethodChannel` real
// del plugin `flutter_image_compress` (canal `flutter_image_compress`) —
// sin dispositivo ni emulador, mismo criterio que
// `test/nucleo/linterna/linterna_controlador_test.dart` y
// `test/nucleo/notificaciones/notificador_local_plugin_test.dart`. No
// depende de compresión real de imagen: valida que se invoque el canal con
// los parámetros correctos y que el resultado del canal se devuelva tal
// cual (lo que `EvidenciaRepository` persiste después).

import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress_common/flutter_image_compress_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('flutter_image_compress');
  final llamadas = <MethodCall>[];
  Object? Function(MethodCall) responder = (_) => null;

  setUp(() {
    FlutterImageCompressCommon.registerWith();
    llamadas.clear();
    responder = (_) => Uint8List.fromList(const [1, 2, 3]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (llamada) async {
          llamadas.add(llamada);
          return responder(llamada);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test('comprimir invoca compressWithList con los bytes originales, calidad '
      'fija y formato jpeg', () async {
    final compresor = CompresorEvidenciaFlutterImageCompress();
    final original = Uint8List.fromList(List.filled(10, 7));

    await compresor.comprimir(original);

    final llamada = llamadas.single;
    expect(llamada.method, 'compressWithList');
    final argumentos = llamada.arguments as List<dynamic>;
    final imagenEnviada = argumentos[0] as Uint8List;
    expect(imagenEnviada, original);
    final minWidth = argumentos[1] as int;
    final minHeight = argumentos[2] as int;
    final quality = argumentos[3] as int;
    const indiceFormatoJpeg = 0;
    final formato = argumentos[6] as int;
    expect(minWidth, 1280);
    expect(minHeight, 1280);
    expect(quality, 70);
    expect(formato, indiceFormatoJpeg);
  });

  test('comprimir devuelve tal cual los bytes que responde el canal', () async {
    final comprimido = Uint8List.fromList([9, 9, 9]);
    responder = (_) => comprimido;
    final compresor = CompresorEvidenciaFlutterImageCompress();

    final resultado = await compresor.comprimir(
      Uint8List.fromList([1, 2, 3, 4, 5]),
    );

    expect(resultado, comprimido);
  });
}
