import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'catalog.dart';
import 'login.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final token = await StorageService().getToken();
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }
    return _isAuthenticated ? const CatalogScreen() : const LoginScreen();
  }
}