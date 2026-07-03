import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart'; // Ajuste o caminho se necessário

class TvService {
  final String baseUrl = 'http://10.0.2.2:4000';

  Future<Map<String, dynamic>> getLiveTv() async {
    final token = await StorageService().getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/tv/live'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Sinal da TV fora do ar!');
    }
  }
}