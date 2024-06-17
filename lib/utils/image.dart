import 'dart:convert';
import 'dart:typed_data';

import 'package:aim/utils/prefs.dart';

Future<bool> saveImage(String key, Uint8List image) async {
  String base64Image = base64Encode(image);
  return Prefs.prefs.setString(key, base64Image);
}

Uint8List? getImage(String key) {
  String? base64Image = Prefs.prefs.getString(key);
  return base64Image == null ? null : base64Decode(base64Image);
}
