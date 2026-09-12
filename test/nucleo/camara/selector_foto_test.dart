// `SelectorFotoImagePicker` sin canal de plataforma real. A diferencia de
// `torch_light`/`flutter_local_notifications`/`flutter_image_compress`
// (`MethodChannel` clásico, mockeable con `setMockMethodCallHandler` — ver
// `compresor_evidencia_test.dart`), `image_picker` es un plugin FEDERADO:
// `package:image_picker` delega en `ImagePickerPlatform.instance`
// (`image_picker_platform_interface`), y el mecanismo soportado para
// testear sin plataforma real es reemplazar esa instancia por un fake que
// extienda `ImagePickerPlatform`, no mockear un canal de bajo nivel (que acá
// ni siquiera es un `MethodChannel`, sino un `BasicMessageChannel`
// generado por Pigeon).

import 'dart:typed_data';

import 'package:agrocom_field/nucleo/camara/selector_foto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _ImagePickerPlatformFalsa extends ImagePickerPlatform {
  XFile? archivoAResponder;
  ImageSource? fuenteRecibida;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    fuenteRecibida = source;
    return archivoAResponder;
  }
}

void main() {
  late _ImagePickerPlatformFalsa plataformaFalsa;

  setUp(() {
    plataformaFalsa = _ImagePickerPlatformFalsa();
    ImagePickerPlatform.instance = plataformaFalsa;
  });

  test('tomarFoto pide la fuente cámara (nunca galería) y devuelve los bytes '
      'del archivo elegido', () async {
    final bytesEsperados = Uint8List.fromList([1, 2, 3, 4, 5]);
    plataformaFalsa.archivoAResponder = XFile.fromData(
      bytesEsperados,
      name: 'incidencia.jpg',
    );

    final selector = SelectorFotoImagePicker();
    final resultado = await selector.tomarFoto();

    expect(plataformaFalsa.fuenteRecibida, ImageSource.camera);
    expect(resultado, bytesEsperados);
  });

  test('tomarFoto devuelve null si el piloto cancela la captura', () async {
    plataformaFalsa.archivoAResponder = null;

    final selector = SelectorFotoImagePicker();
    final resultado = await selector.tomarFoto();

    expect(resultado, isNull);
  });
}
