import 'dart:async';
import 'dart:typed_data';

import 'package:aim/states/base.dart';

class Garment {
  final int gid;
  final Uint8List image;
  final String url;
  final String type;

  const Garment(
      {required this.gid,
      required this.image,
      required this.url,
      required this.type});
}

class GarmentsState extends BaseState {
  static Future<void> init() async {
    SPUtils.defaultDict["temp_garments_amount"] = 0;
    SPUtils.defaultDict["temp_selected_garments_amount"] = 0;
  }

  int size() => getCache("temp_garments_amount", getInt);

  Garment? getGarment(int gid) {
    final id = getCache("temp_garments_$gid", getInt);
    if (id == null) return null;

    final image = getCache("temp_garments_image_$id", getImage);
    final url = getCache("temp_garments_url_$id", getString);
    final type = getCache("temp_garments_type_$id", getString);
    return Garment(gid: gid, image: image, url: url, type: type);
  }

  Iterable<Garment> iterateGarment() sync* {
    final sz = size();
    for (int id = 0; id < sz; id++) {
      final gid = getCache("temp_garments_gid_$id", getInt);
      final image = getCache("temp_garments_image_$id", getImage);
      final url = getCache("temp_garments_url_$id", getString);
      final type = getCache("temp_garments_type_$id", getString);
      yield Garment(gid: gid, image: image, url: url, type: type);
    }
  }

  appendGarment(Garment garment) async {
    int? id = getCache("temp_garments_${garment.gid}", getInt);
    bool increment = id == null;
    id = id ?? size();
    if (increment) {
      await setCache("temp_garments_amount", id + 1, setInt);
    }

    await setCache('temp_garments_gid_$id', garment.gid, setInt);
    await setCache('temp_garments_image_$id', garment.image, setImage);
    await setCache('temp_garments_url_$id', garment.url, setString);
    await setCache('temp_garments_type_$id', garment.type, setString);
    await setCache('temp_garments_${garment.gid}', id!, setInt);

    notifyListeners();
  }

  int sizeSelected() => getCache("temp_selected_garments_amount", getInt);

  List<int> getSelectedGID() {
    List<int> result = <int>[];
    final sz = sizeSelected();
    for (int id = 0; id < sz; id++) {
      final gid = getCache("temp_selected_garments_$id", getInt);
      result.add(gid);
    }
    return result;
  }

  setSelectedGID(List<int> gids) async {
    await setCache("temp_selected_garments_amount", gids.length, setInt);
    for (int id = 0; id < gids.length; id++) {
      await setCache("temp_selected_garments_$id", gids[id], setInt);
    }
    notifyListeners();
  }
}
