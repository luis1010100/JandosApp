import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // FormKey para validar os campos
  final _formKey = GlobalKey<FormState>();

  // Controllers dos campos de e-mail e senha
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Controle para exibir/ocultar senha
  bool _obscure = true;

  // Estado de carregamento (para bloquear botão e mostrar indicador)
  bool _loading = false;

  // Referência ao Realtime Database
  final database = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Função principal de login
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return; // validação do form

    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      // Tenta fazer login
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Salva/atualiza usuário no Realtime Database
      await _saveUserToDatabase(userCredential.user!);

      // Navega para tela principal
      _goToHome();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Usuário não encontrado → cria automaticamente
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Salva o usuário criado no Realtime Database
          await _saveUserToDatabase(userCredential.user!);

          _goToHome();

        } on FirebaseAuthException catch (e) {
          _showError(_mapFirebaseError(e.code));
        }
      } else if (e.code == 'wrong-password') {
        _showError('Senha incorreta');
      } else {
        _showError('Erro desconhecido');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Salva ou atualiza o usuário no Realtime Database
  Future<void> _saveUserToDatabase(User user) async {
    await database.child('users/${user.uid}').set({
      'email': user.email,
      'name': user.email!.split('@')[0], // Exemplo: extrai nome do e-mail
      'role': user.email == 'admin@oficina.com' ? 'admin' : 'mechanic',
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Navega para a tela principal
  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  /// Exibe snackbar com mensagem de erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Converte códigos de erro do Firebase em mensagens amigáveis
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'E-mail já cadastrado';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'weak-password':
        return 'Senha muito fraca (mínimo 6 caracteres)';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      default:
        return 'Erro desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Entrar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Campo de e-mail
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 12),

                    // Campo de senha
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 16),

                    // Botão de login
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _signIn,
                        child: _loading ? const CircularProgressIndicator() : const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
