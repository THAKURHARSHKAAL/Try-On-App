import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiServiceException implements Exception {
  ApiServiceException(this.message);

  final String message;

  @override
  String toString() => 'ApiServiceException: $message';
}

class ApiService {
  ApiService({
    String backendUrl = 'https://your-backend.com',
    http.Client? client,
    Duration timeout = const Duration(seconds: 60),
  })  : _backendUrl = backendUrl,
        _client = client ?? http.Client(),
        _timeout = timeout;

  final String _backendUrl;
  final http.Client _client;
  final Duration _timeout;

  /// Sends person and clothing images to backend and returns generated result URL.
  ///
  /// [personImage] should be a local file selected from camera/gallery.
  /// [clothingInput] can be either:
  /// - direct image URL (http/https)
  /// - base64 encoded image string
  Future<String> tryOnClothes(File personImage, String clothingInput) async {
    if (!await personImage.exists()) {
      throw ApiServiceException(
        'Person image file does not exist: ${personImage.path}',
      );
    }

    if (clothingInput.trim().isEmpty) {
      throw ApiServiceException(
        'clothingInput cannot be empty. Provide an image URL or base64 string.',
      );
    }

    try {
      final personBytes = await personImage.readAsBytes();
      final personBase64 = base64Encode(personBytes);

      final response = await _client
          .post(
            Uri.parse('$_backendUrl/api/tryon'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'person_image': personBase64,
              'clothing_input': clothingInput,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiServiceException(
          'Try-on request failed (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ApiServiceException(
          'Unexpected response format: expected JSON object.',
        );
      }

      final resultUrl = decoded['result_url'];
      if (resultUrl is! String || resultUrl.trim().isEmpty) {
        throw ApiServiceException('Response missing a valid result_url field.');
      }

      return resultUrl;
    } on TimeoutException {
      throw ApiServiceException(
        'Try-on request timed out. Check backend status and internet connection.',
      );
    } on SocketException catch (e) {
      throw ApiServiceException('Network error while calling try-on API: $e');
    } on FormatException catch (e) {
      throw ApiServiceException('Failed to decode try-on API response: $e');
    } on ApiServiceException {
      rethrow;
    } catch (e) {
      throw ApiServiceException('Unable to complete try-on request: $e');
    }
  }
}
