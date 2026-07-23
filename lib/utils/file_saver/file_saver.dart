import 'dart:typed_data';
import 'file_saver_mobile.dart' if (dart.library.html) 'file_saver_web.dart';

abstract class FileSaver {
  Future<String> saveFile(Uint8List bytes, String fileName, {required String mimeType});
}

FileSaver getSaver() => throw UnsupportedError('Cannot create a file saver');

Future<String> saveFileBytes(Uint8List bytes, String fileName, {String mimeType = 'image/png'}) async {
  final saver = getSaver();
  return await saver.saveFile(bytes, fileName, mimeType: mimeType);
}
