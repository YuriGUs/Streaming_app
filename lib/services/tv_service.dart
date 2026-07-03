import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart'; // Ajuste o caminho se necessário

class TvService {
  Future<Map<String, dynamic>> getLiveTv() async {
    final token = await StorageService().getToken();
    final ip = await StorageService().getServerIp(); // LÊ O IP
    
    final response = await http.get(
      Uri.parse('http://$ip:4000/tv/live'), // MONTA A URL
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