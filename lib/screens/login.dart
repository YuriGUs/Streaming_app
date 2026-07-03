import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importamos o serviço
import '../services/storage_service.dart';
import 'catalog.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // NOVO: Estado para controlar se o botão está carregando
  bool _isLoading = false;
  String? _errorMessage;
  // NOVO: Função assíncrona que lida com o clique do botão
  Future<void> _handleLogin() async {
    setState(() { _errorMessage = null; });
    // Esconde o teclado caso esteja aberto
    FocusScope.of(context).unfocus();

    // Validação básica
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha usuário e senha!')),
      );
      return;
    }

    // Atualiza a tela para mostrar o "carregando"
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final token = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (token != null && mounted) {
        // 1. Salva o token no disco
        await StorageService().saveToken(token);
        
        // 2. Notifica sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 3. Navega para a tela de Catálogo (destruindo a tela de Login)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CatalogScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      // Independentemente de dar certo ou errado, paramos o carregamento
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.movie_creation_rounded, size: 80, color: Colors.deepPurpleAccent),
                const SizedBox(height: 32),
                const Text(
                  'Rust Streamer',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                
                const SizedBox(height: 32),

                // NOVO: Exibe o erro de forma elegante e não invasiva
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ATUALIZADO: O botão agora decide o que desenhar baseado no _isLoading
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // Se estiver carregando, desativa o botão (passa null pro onPressed)
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ENTRAR', style: TextStyle(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () {
                    // Navega para a tela de registro por cima da atual
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Não tem uma conta? Cadastre-se'),
                ),
              ],
            ),
          ),
        ),
      )
        
      ),
    );
  }
}