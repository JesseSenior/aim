import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late final SharedPreferences prefs;

  static init() async {
    prefs = await SharedPreferences.getInstance();

    var serverAddress = prefs.getString('server_address');
    if (serverAddress == null) {
      await prefs.setString('server_address', '10.32.128.41:11451');
    }
  }

  static cleanCache() async {
    // TODO: Clean up caches and reset home state.
  }
}
