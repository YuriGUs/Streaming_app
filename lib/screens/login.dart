import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _ipController = TextEditingController(); 
  
  // 📺 Variáveis para guardar os nós de foco do controle remoto
  late FocusNode _ipFocus;
  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  late FocusNode _loginButtonFocus;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Inicializa os focos com a nossa função anti-bug da TV
    _ipFocus = _createTvFocusNode();
    _usernameFocus = _createTvFocusNode();
    _passwordFocus = _createTvFocusNode();
    _loginButtonFocus = _createTvFocusNode();

    _loadSavedIp(); 
  }

  // 🌟 A MÁGICA DA TV: Intercepta a seta do controle e força o pulo do campo
  FocusNode _createTvFocusNode() {
    return FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // SE SETA PARA BAIXO: Pula para o próximo campo
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            FocusScope.of(context).nextFocus();
            return KeyEventResult.handled;
          } 
          // SE SETA PARA CIMA: Verifica se pode subir
          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            // Se o foco já está no primeiro campo (IP), não faz nada.
            // Se não, volta para o campo anterior.
            if (node == _ipFocus) {
              return KeyEventResult.ignored; // Fica preso no IP se for o primeiro
            }
            FocusScope.of(context).previousFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  Future<void> _loadSavedIp() async {
    final savedIp = await StorageService().getServerIp();
    setState(() {
      _ipController.text = savedIp;
    });
  }

  Future<void> _handleLogin() async {
    setState(() { _errorMessage = null; });
    FocusScope.of(context).unfocus();

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha usuário, senha e o IP do servidor!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await StorageService().saveServerIp(_ipController.text.trim());

      final authService = AuthService();
      final token = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (token != null && mounted) {
        await StorageService().saveToken(token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!'), backgroundColor: Colors.green),
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
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ipController.dispose(); 
    _ipFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _loginButtonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurpleAccent.withOpacity(0.2), Colors.black],
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_creation_rounded, size: 120, color: Colors.deepPurpleAccent),
                  SizedBox(height: 24),
                  Text('Rust Streamer', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  Text('Sua TV, Suas Regras.', style: TextStyle(fontSize: 20, color: Colors.white54)),
                ],
              ),
            ),
          ),
          
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[900], 
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Acessar Servidor',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      TextField(
                        controller: _ipController,
                        focusNode: _ipFocus, // 📺 Vinculado
                        autofocus: true,     // 📺 Já abre a tela focado aqui!
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'IP do Servidor',
                          hintText: 'Ex: 192.168.1.50',
                          prefixIcon: Icon(Icons.dns_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus, // 📺 Vinculado
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Usuário',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus, // 📺 Vinculado
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _handleLogin(),
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
                        focusNode: _loginButtonFocus, // 📺 Vinculado
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('ENTRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      
                      TextButton(
                        onPressed: () async {
                          if (_ipController.text.isNotEmpty) {
                            await StorageService().saveServerIp(_ipController.text.trim());
                          }
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          }
                        },
                        child: const Text('Não tem uma conta? Cadastre-se', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}