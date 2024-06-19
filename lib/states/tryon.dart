import 'dart:async';
import 'dart:typed_data';

import 'package:aim/states/base.dart';
import 'package:flutter/cupertino.dart';

class TryOnResult {
  final String gids; // 下划线分割gid
  final Uint8List image;

  const TryOnResult({required this.gids, required this.image});
}

class TryOnResultsState extends BaseState {
  static Future<void> init() async {
    SPUtils.defaultDict["temp_tryon_amount"] = 0;
    SPUtils.defaultDict["temp_tryon_active_id"] = 0;
  }

  clean() {
    SPUtils.clearCache(prefix: "temp_tryon_");
    notifyListeners();
  }

  int size() => getCache("temp_tryon_amount", getInt);

  int get activeID => getCache("temp_tryon_active_id", getInt);

  set activeID(int val) => setCache("temp_tryon_active_id", val, setInt);

  Iterable<TryOnResult> iterateResult() sync* {
    final sz = size();
    for (int id = 0; id < sz; id++) {
      final gids = getCache("temp_tryon_gids_$id", getString);
      final image = getCache("temp_tryon_image_$id", getImage);
      yield TryOnResult(gids: gids, image: image);
    }
  }

  TryOnResult getResult(int id) {
    final gids = getCache("temp_tryon_gids_$id", getString);
    final image = getCache("temp_tryon_image_$id", getImage);
    return TryOnResult(gids: gids, image: image);
  }

  appendResult(TryOnResult result) async {
    final id = size();
    await setCache("temp_tryon_amount", id + 1, setInt);
    await setCache('temp_tryon_gids_$id', result.gids, setString);
    await setCache('temp_tryon_image_$id', result.image, setImage);
    activeID = id;
    notifyListeners();
  }
}
