import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient();

  static const String baseUrl = 'https://backend-production-b58c.up.railway.app';

  static String? _sessionCookie;
  static String? _sessionToken;

  static void _captureCookie(http.Response response) {
    final String? setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _sessionCookie = setCookie.split(';').first;
    }
  }

  // Set-Cookie tidak terbaca oleh JS di browser (Fetch spec), jadi login juga
  // mengembalikan token sesi mentah di body — dipakai lewat header X-Session-Token
  // supaya sesi tetap jalan di semua platform (bukan cuma desktop/dart:io).
  static void _captureToken(dynamic decodedBody) {
    if (decodedBody is Map && decodedBody['token'] is String) {
      _sessionToken = decodedBody['token'] as String;
    }
  }

  static Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    if (_sessionToken != null) 'X-Session-Token': _sessionToken!,
  };

  dynamic _decode(http.Response response) {
    _captureCookie(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Terjadi kesalahan (${response.statusCode})';
      try {
        final dynamic body = jsonDecode(response.body);
        if (body is Map && body['error'] is String) {
          message = body['error'] as String;
        }
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    if (response.body.isEmpty) return null;
    final dynamic decoded = jsonDecode(response.body);
    _captureToken(decoded);
    return decoded;
  }

  Future<dynamic> get(String path) async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _decode(response);
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
    String method = 'POST',
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      method,
      Uri.parse('$baseUrl$path'),
    );
    if (_sessionCookie != null) {
      request.headers['Cookie'] = _sessionCookie!;
    }
    if (_sessionToken != null) {
      request.headers['X-Session-Token'] = _sessionToken!;
    }
    request.fields.addAll(fields);
    if (fileField != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    final http.StreamedResponse streamed = await request.send();
    final http.Response response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
}
