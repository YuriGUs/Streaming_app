import 'api_client.dart';
import '../models/movie.dart';

class MovieService {
  // Instanciamos o nosso cliente configurado com o token
  final ApiClient _apiClient = ApiClient();

  Future<List<Movie>> getMovies() async {
    try {
      // Faz a requisição GET na nossa rota protegida
      final response = await _apiClient.dio.get('/library/movies');
      
      // O Dio já converte a resposta para uma Lista (List<dynamic>)
      final List<dynamic> data = response.data;
      
      // Mapeamos cada item do JSON para um objeto Movie
      return data.map((json) => Movie.fromJson(json)).toList();
      
    } catch (e) {
      print('Erro ao buscar filmes: $e');
      throw Exception('Falha ao carregar o catálogo.');
    }
  }
}