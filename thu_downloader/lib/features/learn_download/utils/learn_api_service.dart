import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class LearnApiService {
  final String _baseUrl = 'https://learn.tsinghua.edu.cn';
  late final Dio _dio;

  LearnApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      // 禁用自动重定向，手动处理
      followRedirects: false,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
      },
    ));
    
    _dio.interceptors.add(CookieManager(CookieJar()));
  }

  // 打印所有cookie
  Future<void> printAllCookies() async {
    print('当前所有cookie:');
    final cookieJar = _dio.interceptors.whereType<CookieManager>().firstOrNull?.cookieJar;
    if (cookieJar != null) {
      try {
        // 获取指定域名的所有cookie
        final cookies = await cookieJar.loadForRequest(Uri.parse('https://learn.tsinghua.edu.cn'));
        
        if (cookies.isEmpty) {
          print('没有找到任何cookie');
        } else {
          print('找到 ${cookies.length} 个cookie:');
          for (int i = 0; i < cookies.length; i++) {
            final cookie = cookies[i];
            print('  ${i + 1}. ${cookie.name} = ${cookie.value}');
            print('     域名: ${cookie.domain}');
            print('     路径: ${cookie.path}');
            print('     过期时间: ${cookie.expires}');
            print('     安全: ${cookie.secure}');
            print('     HttpOnly: ${cookie.httpOnly}');
            print('');
          }
        }
        
      } catch (e) {
        print('获取cookie时出错: $e');
      }
    } else {
      print('CookieJar 未找到');
    }
  }

  Future<String?> getCsrfToken() async {
    // csrf token 在 cookie 中, XSRF-TOKEN
    final cookieJar = _dio.interceptors.whereType<CookieManager>().firstOrNull?.cookieJar;
    if (cookieJar != null) {
      final cookies = await cookieJar.loadForRequest(Uri.parse('https://learn.tsinghua.edu.cn'));
      for (final cookie in cookies) {
        if (cookie.name == 'XSRF-TOKEN') {
          return cookie.value;
        }
      }
    }
    print('Failed to extract CSRF token from cookies');
    return null;
  }

  Future<String?> completeSsoLogin(String url) async {
    try {
      // 第一步：访问 SSO 返回的 URL，手动处理重定向
      Response? currentResponse;
      String currentUrl = url;
      int redirectCount = 0;
      const maxRedirects = 5;
      
      while (redirectCount < maxRedirects) {
        try {
          currentResponse = await _dio.get(
            currentUrl,
            options: Options(
              validateStatus: (status) {
                return status != null && (status >= 200 && status < 400);
              },
            ),
          );
          
          // 如果是200，说明重定向完成
          if (currentResponse.statusCode == 200) {
            break;
          }
          // 如果是302重定向，获取Location头
          if (currentResponse.statusCode == 302) {
            final locationHeader = currentResponse.headers['location'];
            if (locationHeader != null && locationHeader.isNotEmpty) {
              currentUrl = locationHeader.first;
              redirectCount++;
              continue;
            }
          }
          break;
        } catch (e) {
          return null;
        }
      }
      
      if (currentResponse == null || currentResponse.statusCode != 200) {
        return null;
      }
      
      final csrfToken = await getCsrfToken();
      print(await getSemesters(csrfToken!));
      return csrfToken;
    } catch (e) {
      print('Error completing SSO login: $e');
      return null;
    }
  }


  // 获取学期列表
  Future<List<String>> getSemesters(String csrfToken) async {
    try {
      final response = await _dio.get('/b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq',
        queryParameters: {'_csrf': csrfToken}
      );      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting semesters: $e');
      return [];
    }
  }

  // 获取课程列表
  Future<List<Map<String, dynamic>>> getCourses(String csrfToken, String semesterId, {String language = 'zh'}) async {
    try {
      final response = await _dio.get('/b/wlxt/kc/v_wlkc_xs_xkb_kcb_extend/student/loadCourseBySemesterId/$semesterId/$language',
        queryParameters: {'_csrf': csrfToken}
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> resultList = data['resultList'] ?? [];
        return resultList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  // 获取文档分类
  Future<List<Map<String, dynamic>>> getDocumentCategories(String csrfToken, String courseId) async {
    try {
      final response = await _dio.get('/b/wlxt/kj/wlkc_kjflb/student/pageList',
        queryParameters: {
          'wlkcid': courseId,
          '_csrf': csrfToken,
        }
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final Map<String, dynamic> object = data['object'] ?? {};
        final List<dynamic> rows = object['rows'] ?? [];
        return rows.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting document categories: $e');
      return [];
    }
  }

  // 获取文档列表
  Future<List<Map<String, dynamic>>> getDocuments(String csrfToken, String courseId, {int size = 200}) async {
    try {
      final response = await _dio.get('/b/wlxt/kj/wlkc_kjxxb/student/kjxxbByWlkcidAndSizeForStudent',
        queryParameters: {
          'wlkcid': courseId,
          'size': size.toString(),
          '_csrf': csrfToken,
        }
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> object = data['object'] ?? [];
        return object.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }

  // 下载文件
  Future<void> downloadFile(
    dynamic document,
    String baseDirectory,
    String csrfToken, {
    Function(int downloaded, int total)? onProgress,
  }) async {
    try {
      const url = 'https://learn.tsinghua.edu.cn/b/wlxt/kj/wlkc_kjxxb/student/downloadFile';
      
      final params = {
        'sfgk': 0,
        'wjid': document.fileId,
        '_csrf': csrfToken,
      };

      // 构建完整的文件路径，保持目录结构
      final relativePath = document.buildFilePath();
      final directoryPath = '$baseDirectory/${_getDirectoryPath(relativePath)}';
      final fileName = _sanitizeFileNameWithExtension(document.name, document.fileType);
      final filePath = '$directoryPath/$fileName';

      // 确保目录存在
      await _ensureDirectoryExists(directoryPath);

      await _dio.download(
        url,
        filePath,
        queryParameters: params,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Referer': 'https://learn.tsinghua.edu.cn/',
          },
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onProgress,
      );

      print('File downloaded successfully: $filePath');
    } catch (e) {
      print('Download error for ${document.name}: $e');
      rethrow;
    }
  }

  // 清理文件名（移除非法字符）
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // 清理文件名并保留扩展名
  String _sanitizeFileNameWithExtension(String fileName, String? fileType) {
    // 先清理文件名
    String sanitizedName = _sanitizeFileName(fileName);
    
    // 如果文件名已经有扩展名，直接返回
    if (sanitizedName.contains('.')) {
      return sanitizedName;
    }
    
    // 根据文件类型添加扩展名
    if (fileType != null && fileType.isNotEmpty) {
      final extension = fileType;
      if (extension.isNotEmpty) {
        return '$sanitizedName.$extension';
      }
    }
    
    return sanitizedName;
  }

  // 获取目录路径（去掉文件名部分）
  String _getDirectoryPath(String fullPath) {
    final lastSlashIndex = fullPath.lastIndexOf('/');
    if (lastSlashIndex == -1) {
      return '';
    }
    return fullPath.substring(0, lastSlashIndex);
  }

  // 确保目录存在
  Future<void> _ensureDirectoryExists(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      print('Error creating directory $directoryPath: $e');
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
} 