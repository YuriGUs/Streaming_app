import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController(); // VOLTOU: Confirmar senha
  final TextEditingController _ipController = TextEditingController(); // NOVO: Controlador de IP

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedIp(); 
  }

  // Busca o IP salvo para já vir preenchido o que ele digitou no login
  Future<void> _loadSavedIp() async {
    final savedIp = await StorageService().getServerIp();
    setState(() {
      _ipController.text = savedIp;
    });
  }

  Future<void> _handleRegister() async {
    setState(() { _errorMessage = null; });
    FocusScope.of(context).unfocus();

    // 1. Verifica se ALGUM dos 4 campos está vazio
    if (_usernameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmController.text.isEmpty || // Checa a confirmação
        _ipController.text.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos, incluindo o IP.');
      return;
    }

    // 2. A SUA VALIDAÇÃO ANTIGA: Verifica se as senhas batem
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'As senhas não coincidem.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 3. Salva o IP atualizado no disco antes de disparar o registro
      await StorageService().saveServerIp(_ipController.text.trim());

      // 4. Chama o serviço de registro 
      final authService = AuthService();
      await authService.register(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Faça o login.'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de login
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose(); // Não podemos esquecer de descartar esse!
    _ipController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.deepPurpleAccent),
                  const SizedBox(height: 32),

                  // CAMPO DO IP
                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'IP do Servidor',
                      prefixIcon: Icon(Icons.dns_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Novo Usuário',
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
                  const SizedBox(height: 16),

                  // VOLTOU: CAMPO DE CONFIRMAR SENHA
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: Icon(Icons.lock_clock),
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
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('CADASTRAR', style: TextStyle(fontSize: 16)),
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