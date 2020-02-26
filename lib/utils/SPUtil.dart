import 'package:shared_preferences/shared_preferences.dart';

class SPUtil {
  static SharedPreferences sp;

  static Future<SharedPreferences> getSp() async {
    return SharedPreferences.getInstance();
  }

  static setString(String key, String value) {
    sp.setString(key, value);
  }

  static getString(String key, String def) {
    if (!sp.containsKey(key)) return def;
    String value = sp.getString(key);
    return value == null ? def : value;
  }

  static setBool(String key, bool value) {
    sp.setBool(key, value);
  }

  static getBool(String key, bool def) {
    if (!sp.containsKey(key)) return def;
    if (sp == null) {
      print('hhhhhhhh');
    }
    bool value = sp.getBool(key);
    return value == null ? def : value;
  }

  static setInt(String key, int value) {
    sp.setInt(key, value);
  }

  static getInt(String key, int def) {
    if (!sp.containsKey(key)) return def;
    int value = sp.getInt(key);
    return value == null ? def : value;
  }
}
