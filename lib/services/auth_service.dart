import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class AuthService {
  // Configuração base do Dio (removemos a baseUrl fixa daqui)
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5), // Desiste se o servidor não responder em 5s
  ));

  // NOVO: Método auxiliar que lê o IP salvo e configura no Dio
  Future<void> _configureDio() async {
    final ip = await StorageService().getServerIp();
    // Injeta o IP dinamicamente formando a URL correta
    _dio.options.baseUrl = 'http://$ip:4000';
  }

  /// Retorna o token JWT se o login for bem-sucedido, ou dispara um erro.
  Future<String?> login(String username, String password) async {
    try {
      // 1. Configura a URL base com o IP que o usuário digitou agora
      await _configureDio();

      // 2. Fazemos o POST para a rota que criamos no Rust
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      // Se o Rust retornou 200 OK, pegamos o token do JSON
      if (response.statusCode == 200) {
        return response.data['token'];
      }
      return null;
      
    } on DioException catch (e) {
      // O DioException captura erros HTTP. Vamos tratá-los:
      if (e.response?.statusCode == 401) {
        throw Exception('Usuário ou senha incorretos.');
      }
      // Se não for 401, pode ser que o servidor Rust esteja desligado (Connection Refused)
      throw Exception('Erro de conexão com o servidor.');
    }
  }

  Future<void> register(String username, String password) async {
    try {
      // 1. Configura a URL base com o IP salvo
      await _configureDio();

      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
      });

      // Se não for 201 Created ou 200 OK, algo deu errado
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Falha ao registrar usuário.');
      }
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Código HTTP 409 significa Conflict (Conflito de dados já existentes)
        throw Exception('Este nome de usuário já está em uso.');
      }
      throw Exception('Erro de conexão com o servidor.');
    }
  }
}