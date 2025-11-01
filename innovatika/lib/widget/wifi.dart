import 'package:http/http.dart' as http;
import 'dart:convert';

class CredentialService {
  static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbx-ST4kFqkXWPB4JTbn7ClLMYGcZLpUTmlhq1gGqwWYG5Oy9Wj_nbanzg2o7ImH66H3/exec';

  Future<bool> validateCredentials({
    required String deviceId,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl').replace(queryParameters: {
        'deviceId': deviceId,
        'password': password,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] as bool;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
