import 'dart:async';
import 'dart:typed_data';

import 'package:aim/states/base.dart';

class ConfigState extends BaseState {
  static Future<void> init() async {
    SPUtils.defaultDict["server_address"] = "10.32.128.41:11451";
  }

  // serverAddress: 服务器地址
  String get serverAddress => getCache('server_address', getString);

  set serverAddress(String address) =>
      setCacheN('server_address', address, setString);

  // prevTryOnImage：改造前图像
  Uint8List? get prevTryOnImage => getCache('temp_prev_try_on_image', getImage);

  set prevTryOnImage(Uint8List? image) =>
      setCacheN('temp_prev_try_on_image', image!, setImage);

  // prevTryOnImageText：改造前图像描述
  String? get prevTryOnImageText =>
      getCache('temp_prev_try_on_image_text', getString);

  set prevTryOnImageText(String? image) =>
      setCacheN('temp_prev_try_on_image_text', image!, setString);
}
