import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 
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
  final TextEditingController _ipController = TextEditingController(); // NOVO
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedIp(); // NOVO: Busca o último IP usado para poupar o usuário
  }

  // NOVO: Preenche o campo de IP automaticamente se houver um histórico
  Future<void> _loadSavedIp() async {
    final savedIp = await StorageService().getServerIp();
    setState(() {
      _ipController.text = savedIp;
    });
  }

  Future<void> _handleLogin() async {
    setState(() { _errorMessage = null; });
    FocusScope.of(context).unfocus();

    // Validação básica atualizada
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha usuário, senha e o IP do servidor!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. PRIMEIRA ETAPA: Salva o IP digitado no disco IMEDIATAMENTE.
      // Assim, quando o AuthService for instanciado ali embaixo, ele já lerá o IP novo!
      await StorageService().saveServerIp(_ipController.text.trim());

      final authService = AuthService();
      final token = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (token != null && mounted) {
        await StorageService().saveToken(token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
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
    _ipController.dispose(); // NOVO
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
                  
                  // NOVO: Campo de texto para o IP do servidor
                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'IP do Servidor',
                      hintText: 'Ex: 192.168.1.50',
                      prefixIcon: Icon(Icons.dns_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                  
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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
                    onPressed: () async {
                      // 👇 CORREÇÃO: Se o usuário digitou o IP, salvamos no disco antes de ir para o cadastro 👇
                      if (_ipController.text.isNotEmpty) {
                        await StorageService().saveServerIp(_ipController.text.trim());
                      }
                      
                      if (mounted) {
                        // Navega para a tela de registro por cima da atual
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      }
                    },
                    child: const Text('Não tem uma conta? Cadastre-se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}