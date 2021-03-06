import 'package:bytes_cloud/core/http/http.dart';

class UserHandler {
  static Future<bool> register(String userName, String password) async {
    var rsp = await httpPost(HTTP_POST_REGISTER,
        form: {'email': userName, 'password': password});
    print('UserHandler#register rsp = $rsp');
    return rsp['code'] == 0;
  }

  static Future login(String userName, String password) async {
    print(cookieJar.loadForRequest(Uri.parse(host)));
    var rsp = await httpPost(HTTP_POST_LOGIN,
        form: {'email': userName, 'password': password});
    print('login rsp ${rsp.toString()}');
    return rsp['code'] == 0 || rsp['code'] == 32; // code = 32已经登录
  }

  static Future logout() async {
    print(cookieJar.loadForRequest(Uri.parse(host)));
    var rsp = await httpGet(HTTP_POST_LOGOUT);
    print('logout rsp ${rsp.toString()}');
    return rsp['code'] == 0;
  }
}
