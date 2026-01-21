import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

class ChatDocumentController {
  /// 🔽 Download if needed, then open
  Future<void> openOrDownload({
    required String url,
    required String fileName,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      if (file.existsSync()) {
        debugPrint('📄 [DocCtrl] Opening cached file');
        await OpenFilex.open(file.path);
        return;
      }

      debugPrint('📄 [DocCtrl] Downloading file');
      final res = await http.get(Uri.parse(url));
      await file.writeAsBytes(res.bodyBytes);

      debugPrint('📄 [DocCtrl] Download complete');
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('🔴 [DocCtrl] Failed → $e');
    }
  }
}
