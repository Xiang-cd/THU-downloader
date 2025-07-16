import 'package:http/http.dart' as http;

class LearnApiService {
  final String _baseUrl = 'learn.tsinghua.edu.cn';

  Future<bool> testApi(String csrfToken) async {
    final uri = Uri.https(_baseUrl, '/b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq', {
      '_csrf': csrfToken,
    });

    final headers = {
      'Cookie': 'XSRF-TOKEN=$csrfToken',
    };

    try {
      final response = await http.get(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      // You might want to log the error for debugging purposes
      // print(e);
      return false;
    }
  }
} 