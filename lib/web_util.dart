import 'package:http/http.dart' as http;

class WebUtil {
 static const String UA =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:91.0) Gecko/20100101 Firefox/91.0";

 static Future<String> getContentType(String url) async {
    var headers = <String, String>{};
    try {
      final mUrl = Uri.parse(url);
      headers["Host"] = mUrl.host;
    } catch (ignored) {
      // 忽略错误
    }
    headers["User-Agent"] = UA;
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print(">>>> url-----$url");
      print(">>>> code----${response.statusCode}");
      print(">>>> type----${response.headers['content-type']}");
      return "${response.headers['content-type']}-${response.statusCode}";
    } catch (e) {
      print(e);
    }
    return "";
 }
}
