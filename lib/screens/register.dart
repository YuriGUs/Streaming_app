import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _confirmController = TextEditingController(); 
  final TextEditingController _ipController = TextEditingController(); 

  late FocusNode _ipFocus;
  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  late FocusNode _confirmFocus;
  late FocusNode _registerButtonFocus;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _ipFocus = _createTvFocusNode();
    _usernameFocus = _createTvFocusNode();
    _passwordFocus = _createTvFocusNode();
    _confirmFocus = _createTvFocusNode();
    _registerButtonFocus = _createTvFocusNode();

    _loadSavedIp(); 
  }

  // 🌟 MÁGICA DA TV TAMBÉM NA TELA DE REGISTRO
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

  Future<void> _handleRegister() async {
    setState(() { _errorMessage = null; });
    FocusScope.of(context).unfocus();

    if (_usernameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmController.text.isEmpty || 
        _ipController.text.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos, incluindo o IP.');
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'As senhas não coincidem.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await StorageService().saveServerIp(_ipController.text.trim());

      final authService = AuthService();
      await authService.register(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso! Faça o login.'), backgroundColor: Colors.green),
        );
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
    _confirmController.dispose(); 
    _ipController.dispose(); 
    _ipFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _registerButtonFocus.dispose();
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
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.black, Colors.deepPurpleAccent.withOpacity(0.2)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 24, left: 24,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 120, color: Colors.deepPurpleAccent),
                        SizedBox(height: 24),
                        Text('Nova Conta', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 16),
                        Text('Junte-se ao servidor.', style: TextStyle(fontSize: 20, color: Colors.white54)),
                      ],
                    ),
                  ),
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
                        'Preencha seus dados',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      TextField(
                        controller: _ipController,
                        focusNode: _ipFocus,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'IP do Servidor',
                          prefixIcon: Icon(Icons.dns_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Novo Usuário',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: Icon(Icons.lock_clock),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _handleRegister(),
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
                        focusNode: _registerButtonFocus,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('CADASTRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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