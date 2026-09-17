import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  static const String baseUrl =
      'https://backend-production-b58c.up.railway.app';

  /// One client for the app's lifetime so requests reuse the open
  /// connection instead of paying a new TLS handshake each time.
  static final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 20);

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
    'Cookie': ?_sessionCookie,
    'X-Session-Token': ?_sessionToken,
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

  /// Turns a dead server or network into an [ApiException] the UI can show,
  /// instead of a hang or an uncaught socket error.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Server tidak merespons, coba lagi', 0);
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server', 0);
    }
  }

  Future<dynamic> get(String path) async {
    final http.Response response = await _send(
      () => _client.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final http.Response response = await _send(
      () => _client.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final http.Response response = await _send(
      () => _client.delete(Uri.parse('$baseUrl$path'), headers: _headers),
    );
    return _decode(response);
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields, {
    String? fileField,
    Uint8List? fileBytes,
    String? fileName,
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
    if (fileField != null && fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );
    }
    final http.Response response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
    );
    return _decode(response);
  }
}
