import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SPUtils {
  static late final SharedPreferences prefs;
  static Map<String, dynamic> cache = <String, dynamic>{};
  static Logger logger = Logger();

  static Map<String, dynamic> defaultDict = <String, dynamic>{};

  static init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static void clearCache({String prefix = "temp_"}) {
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith(prefix)) {
        prefs.remove(key);
      }
    }

    var toRemove = <String>[];
    for (String key in cache.keys) {
      if (key.startsWith(prefix)) {
        toRemove.add(key);
      }
    }
    for (String key in toRemove) {
      cache.remove(key);
    }
  }

  getDefault(String key) => defaultDict[key];
}

class BaseState with ChangeNotifier {
  dynamic getCache(String key, Function(String) method) {
    SPUtils.cache[key] ??= method(key);
    SPUtils.cache[key] ??= SPUtils.defaultDict[key];
    return SPUtils.cache[key];
  }

  Future<void> setCache<T>(
    String key,
    T value,
    Function(String, T) method,
  ) async {
    SPUtils.cache[key] = value;
    assert(await method(key, value) == true);
  }

  Future<void> setCacheN<T>(
    String key,
    T value,
    Function(String, T) method,
  ) async {
    SPUtils.cache[key] = value;
    assert(await method(key, value) == true);
    notifyListeners();
  }

  Uint8List? getImage(String key) {
    String? base64Image = SPUtils.prefs.getString(key);
    return base64Image == null ? null : base64Decode(base64Image);
  }

  Future<bool> setImage(String key, Uint8List image) async {
    String base64Image = base64Encode(image);
    return SPUtils.prefs.setString(key, base64Image);
  }

  final getString = SPUtils.prefs.getString;
  final getInt = SPUtils.prefs.getInt;

  final setString = SPUtils.prefs.setString;
  final setInt = SPUtils.prefs.setInt;

  static Future<void> init() async {}
}
