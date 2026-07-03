import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'jwt_token';

  // Salva o token no disco
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Lê o token do disco (retorna null se o usuário nunca tiver logado)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Apaga o token (útil para a futura função de Logout)
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    // Tenta ler o IP salvo. Se não tiver nenhum (primeiro uso), usa o padrão como segurança
    return prefs.getString('server_ip') ?? '10.0.2.2'; 
  }
}