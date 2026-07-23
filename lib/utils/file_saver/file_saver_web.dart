// ignore: avoid_web_libraries_in_dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'file_saver.dart';

class WebFileSaver implements FileSaver {
  @override
  Future<String> saveFile(Uint8List bytes, String fileName, {required String mimeType}) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    
    return 'Downloads/$fileName';
  }
}

FileSaver getSaver() => WebFileSaver();
