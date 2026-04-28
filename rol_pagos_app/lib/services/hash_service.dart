import 'dart:io';

import 'package:crypto/crypto.dart';

class HashService {
  const HashService();

  Future<String> sha256File(String filePath) async {
    final file = File(filePath);
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
