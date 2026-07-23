import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'file_saver.dart';

class MobileFileSaver implements FileSaver {
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {required String mimeType}) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    
    if (dir == null) {
      throw Exception('Storage directory not available');
    }
    
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }
}

FileSaver getSaver() => MobileFileSaver();
