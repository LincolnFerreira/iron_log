import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final AuthService _authService = AuthService();
  String _response = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService.initialize();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _response = 'Fazendo login...';
    });

    try {
      // Usar o método que já estava funcionando no login_screen.dart
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());

      setState(() {
        _response =
            'Login realizado com sucesso!\nEmail: ${_authService.currentUser?.email}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Erro no login: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testValidateToken() async {
    setState(() {
      _isLoading = true;
      _response = 'Validando token...';
    });

    try {
      if (!_authService.isAuthenticated) {
        setState(() {
          _response = 'Usuário não está logado!';
          _isLoading = false;
        });
        return;
      }

      final token = await _authService.currentUser!.getIdToken();
      if (token == null) {
        setState(() {
          _response = 'Erro: token é null';
          _isLoading = false;
        });
        return;
      }

      final result = await _authService.validateToken(token);

      setState(() {
        _response = 'Token validado com sucesso!\n\n${_formatJson(result)}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Erro ao validar token: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetProfile() async {
    setState(() {
      _isLoading = true;
      _response = 'Obtendo perfil...';
    });

    try {
      final result = await _authService.getUserProfile();

      setState(() {
        _response = 'Perfil obtido com sucesso!\n\n${_formatJson(result)}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Erro ao obter perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _response = 'Fazendo logout...';
    });

    try {
      await _authService.signOut();

      setState(() {
        _response = 'Logout realizado com sucesso!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Erro no logout: $e';
        _isLoading = false;
      });
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    String result = '';
    json.forEach((key, value) {
      result += '$key: $value\n';
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Autenticação Firebase + NestJS'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status do usuário
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<User?>(
                  stream: _authService.authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status do usuário:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user != null
                              ? '✅ Logado\nEmail: ${user.email}\nUID: ${user.uid}'
                              : '❌ Não logado',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de ação
            if (!_authService.isAuthenticated) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Login com Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testValidateToken,
                icon: const Icon(Icons.verified),
                label: const Text('Testar POST /auth/validate'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testGetProfile,
                icon: const Icon(Icons.person),
                label: const Text('Testar GET /auth/me'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Área de resposta
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resposta da API:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Text(
                                    _response.isEmpty
                                        ? 'Nenhuma resposta ainda...'
                                        : _response,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
