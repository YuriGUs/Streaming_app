import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiClient {
  // Criamos a instância do Dio que será usada por todo o app
  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
    ));

    // A Mágica: Adicionamos o Interceptador
    dio.interceptors.add(
      InterceptorsWrapper(
        // onRequest é executado ANTES da requisição sair para a internet
        onRequest: (options, handler) async {
          // 1. Pega o IP e monta a Base URL
          final ip = await StorageService().getServerIp();
          options.baseUrl = 'http://$ip:4000';

          // 2. Lemos o token salvo no disco
          final token = await StorageService().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        
        // onError é executado se o servidor retornar um erro (ex: 401 ou 500)
        onError: (DioException e, handler) async {
          // Se o servidor Rust disser 401 Unauthorized (o token expirou ou é inválido)
          if (e.response?.statusCode == 401) {
            // Aqui, no futuro, poderíamos adicionar a lógica para deslogar 
            // o usuário automaticamente e mandá-lo para a tela de login.
            print("Alerta: Token inválido ou expirado!");
          }
          
          return handler.next(e);
        },
      ),
    );
  }
}