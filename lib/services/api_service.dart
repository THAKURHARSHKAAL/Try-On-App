import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({
    String backendUrl = 'https://your-backend.com',
    http.Client? client,
  })  : _backendUrl = backendUrl,
        _client = client ?? http.Client();

  final String _backendUrl;
  final http.Client _client;

  Future<String> tryOnClothes(File personImage, String clothingInput) async {
    if (!await personImage.exists()) {
      throw Exception('Person image file does not exist: ${personImage.path}');
    }

    if (clothingInput.trim().isEmpty) {
      throw Exception('clothingInput cannot be empty. Provide an image URL or base64 string.');
    }

    try {
      final personBytes = await personImage.readAsBytes();
      final personBase64 = base64Encode(personBytes);

      final response = await _client.post(
        Uri.parse('$_backendUrl/api/tryon'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'person_image': personBase64,
          'clothing_input': clothingInput,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Try-on request failed (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format: expected JSON object.');
      }

      final resultUrl = decoded['result_url'];
      if (resultUrl is! String || resultUrl.trim().isEmpty) {
        throw Exception('Response missing a valid result_url field.');
      }

      return resultUrl;
    } on SocketException catch (e) {
      throw Exception('Network error while calling try-on API: $e');
    } on FormatException catch (e) {
      throw Exception('Failed to decode try-on API response: $e');
    } catch (e) {
      throw Exception('Unable to complete try-on request: $e');
    }
  }
}
