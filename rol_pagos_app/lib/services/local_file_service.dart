import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileService {
  const LocalFileService();

  Future<String> ensurePayrollFolder() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'payroll_pdfs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String> copyIntoPayrollFolder({
    required String sourcePath,
    required String targetFileName,
  }) async {
    final folder = await ensurePayrollFolder();
    final destPath = p.join(folder, targetFileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<String> writeBytesIntoPayrollFolder({
    required List<int> bytes,
    required String targetFileName,
  }) async {
    final folder = await ensurePayrollFolder();
    final destPath = p.join(folder, targetFileName);
    final file = File(destPath);
    await file.writeAsBytes(bytes, flush: true);
    return destPath;
  }
}
