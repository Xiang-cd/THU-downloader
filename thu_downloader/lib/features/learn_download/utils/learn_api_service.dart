import 'package:http/http.dart' as http;

class LearnApiService {
  final String _baseUrl = 'learn.tsinghua.edu.cn';
  final http.Client _client = http.Client();

  Future<bool> testApi(String csrfToken) async {
    final uri = Uri.https(_baseUrl, '/b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq', {
      '_csrf': csrfToken,
    });

    final headers = {
      'Cookie': 'XSRF-TOKEN=$csrfToken',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      // You might want to log the error for debugging purposes
      // print(e);
      return false;
    }
  }

  Future<String?> completeSsoLogin(String ticket) async {
    try {
      // 第一步：使用ticket完成认证
      final authUri = Uri.https(_baseUrl, '/b/j_spring_security_thauth_roaming_entry', {
        'ticket': ticket,
      });
      
      final authResponse = await _client.get(authUri);
      
      if (authResponse.statusCode != 200) {
        return null;
      }

      // 第二步：访问课程页面完成登录
      final courseUri = Uri.https(_baseUrl, '/f/wlxt/index/course/student/');
      final courseResponse = await _client.get(courseUri);
      
      if (courseResponse.statusCode != 200) {
        return null;
      }

      // 第三步：从响应头中提取CSRF token
      final setCookieHeader = courseResponse.headers['set-cookie'];
      if (setCookieHeader != null) {
        final csrfToken = _extractCsrfFromSetCookie(setCookieHeader);
        if (csrfToken != null) {
          return csrfToken;
        }
      }

      // 如果从响应头中没找到，尝试从响应体中解析
      final body = courseResponse.body;
      final csrfToken = _extractCsrfFromBody(body);
      
      return csrfToken;
    } catch (e) {
      print('Error completing SSO login: $e');
      return null;
    }
  }

  String? _extractCsrfFromSetCookie(String setCookieHeader) {
    final cookies = setCookieHeader.split(',');
    for (final cookie in cookies) {
      final trimmed = cookie.trim();
      if (trimmed.startsWith('XSRF-TOKEN=')) {
        final tokenPart = trimmed.substring('XSRF-TOKEN='.length);
        // 移除可能的路径和过期时间等参数
        final token = tokenPart.split(';')[0];
        return token;
      }
    }
    return null;
  }

  String? _extractCsrfFromBody(String body) {
    // 尝试从HTML中提取CSRF token
    final csrfPattern = RegExp(r'name="_csrf"\s+value="([^"]+)"');
    final match = csrfPattern.firstMatch(body);
    if (match != null) {
      return match.group(1);
    }
    
    // 尝试从meta标签中提取
    final metaPattern = RegExp(r'<meta\s+name="csrf-token"\s+content="([^"]+)"');
    final metaMatch = metaPattern.firstMatch(body);
    if (metaMatch != null) {
      return metaMatch.group(1);
    }
    
    return null;
  }

  void dispose() {
    _client.close();
  }
} 