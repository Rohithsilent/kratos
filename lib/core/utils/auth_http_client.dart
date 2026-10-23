// lib/core/utils/auth_http_client.dart
//
// A thin wrapper around `package:http` that automatically injects the Firebase
// ID token as an `Authorization: Bearer <token>` header on every request.
// Use this for ALL calls to the KRATOS backend instead of calling `http.*` directly.

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers/firebase_providers.dart';

class AuthHttpClient {
  final FirebaseAuth _auth;

  AuthHttpClient(this._auth);

  /// Returns auth headers with a fresh Firebase ID token.
  /// Returns an empty map if no user is signed in.
  Future<Map<String, String>> _authHeaders({
    Map<String, String>? extra,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) return extra ?? {};
    return {
      'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  Future<http.Response> get(Uri uri) async {
    final headers = await _authHeaders();
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final authHeaders = await _authHeaders(
      extra: {'Content-Type': 'application/json', ...?headers},
    );
    return http.post(uri, headers: authHeaders, body: body, encoding: encoding);
  }

  Future<http.Response> delete(Uri uri) async {
    final headers = await _authHeaders();
    return http.delete(uri, headers: headers);
  }

  /// Multipart POST (e.g. image upload) with auth token.
  Future<http.StreamedResponse> multipartPost(
    Uri uri, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.addAll(files);
    if (fields != null) request.fields.addAll(fields);
    return request.send();
  }
}

final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(ref.watch(firebaseAuthProvider));
});
